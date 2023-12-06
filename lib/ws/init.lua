-- Some parts of `encode`/`decode` frame were copied from Luvit's `ws.lua` module
-- https://github.com/creationix/lua-websocket/blob/master/websocket-codec.lua

local base64 = require "base64"
local sha1 = require "external.sha1"
local bit = require "lib.utils.bit"
local http = require "lib.http"
local tcp = require "lib.http.tcp"
local term = require "lib.utils.term"

---@class WebSocketFrame
---@field fin boolean
---@field rsv1 any
---@field rsv2 any
---@field rsv3 any
---@field opcode wsopcode
---@field mask boolean
---@field payload string
---@field payload_len integer
---@field extra string

---@class ClientWebSocketFrame: WebSocketFrame

---@class ServerWebSocketFrame: WebSocketFrame
---@field opcode? wsopcode

local byte, char, sub = string.byte, string.char, string.sub
local floor, random = math.floor, math.random
local concat = table.concat
local colors = term.colors

-- Currently implements version 13 of the WebSocket protocol.
-- No support for `subprotocols` and `extensions` yet.
-- TODO: Support `permessage-deflate` and `client_max_window_bits` extensions.
local WS = {}

WS.MAGIC = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
WS.EXPECTED_KEY_LENGTH = 0x18

---@enum wsopcode
WS.Opcode = {
    CONTINUATION = 0x0,
    TEXT = 0x1,
    BINARY = 0x2,
    CLOSE = 0x8,
    PING = 0x9,
    PONG = 0xA,
}

---@private
---@param key string
WS.hashKey = function(key)
    local hash = sha1.bin(key .. WS.MAGIC)
    return base64.encode(hash)
end

---@private
---@param req Request
---@param client Socket
WS.handshake = function(req, client)
    local headers = req.headers
    local is_websocket_connection = headers.Connection == 'Upgrade' and headers.Upgrade == 'websocket'
    local is_get_request = req.method == 'GET'
    local has_origin = headers.Origin ~= nil
    if not has_origin then
        print(colors.bg_yellow "WARNING: No Origin header found.")
        print(colors.bg_yellow("Request Host: " .. headers.Host))
    end
    local is_valid_websocket_request = is_websocket_connection and is_get_request
    if not is_valid_websocket_request then
        return {
            status = http.Status.BAD_REQUEST,
            headers = {
                ['Sec-WebSocket-Version'] = '13',
            }
        }
    end
    local key, version = WS.getWebSocketHeaders(headers)
    -- TODO: Do a proper check to see if the string is base64 encoded
    local is_valid_key = key and #key == WS.EXPECTED_KEY_LENGTH
    if not is_valid_key or not version then
        return {
            status = http.Status.BAD_REQUEST,
            headers = {
                ['Sec-WebSocket-Version'] = '13',
            }
        }
    end
    local hashed_key = WS.hashKey(key)
    return {
        status = http.Status.SWITCHING_PROTOCOLS,
        headers = {
            ['Upgrade'] = 'websocket',
            ['Connection'] = 'Upgrade',
            ['Sec-WebSocket-Accept'] = hashed_key,
        }
    }
end

WS.rand4 = function()
    -- Generate 32 bits of pseudo random data
    local num = floor(random() * 0x100000000)
    -- Return as a 4-byte string
    return char(
        num >> 24,
        (num >> 16) & 0xff,
        (num >> 8) & 0xff,
        num & 0xff
    )
end

---@private
---@param chunk string
---@return ClientWebSocketFrame?
WS.decodeFrame = function(chunk)
    local second_byte = byte(chunk, 2)
    local payload_len = second_byte & 0x7F
    local offset = 2
    if payload_len == 126 then
        payload_len = (byte(chunk, 3) << 8) | byte(chunk, 4)
        offset = 4
    elseif payload_len == 127 then
        payload_len = (byte(chunk, 3) << 24) | (byte(chunk, 4) << 16) | (byte(chunk, 5) << 8) |
            byte(chunk, 6) * 0x100000000 + (byte(chunk, 7) << 24) + (byte(chunk, 8) << 16) +
            (byte(chunk, 9) << 8) + byte(chunk, 10)
        offset = 10
    end
    local has_mask = second_byte & 0x80 > 0
    if has_mask then
        offset = offset + 4
    end
    if #chunk < offset + payload_len then
        return
    end
    local first_byte = byte(chunk, 1)
    local payload = sub(chunk, offset + 1, offset + payload_len)
    assert(#payload == payload_len, "Payload length mismatch")
    if has_mask then
        payload = WS.maskPayload(payload, sub(chunk, offset - 3, offset))
    end
    local extra = sub(chunk, offset + payload_len + 1)
    return {
        fin = first_byte & 0x80 > 0,
        rsv1 = first_byte & 0x40 > 0,
        rsv2 = first_byte & 0x20 > 0,
        rsv3 = first_byte & 0x10 > 0,
        opcode = first_byte & 0x0F,
        mask = has_mask,
        payload = payload,
        payload_len = payload_len,
        extra = extra
    }
end

-- https://tools.ietf.org/html/rfc6455#section-5.2
---@private
---@param frame ServerWebSocketFrame
---@return string
WS.encodeFrame = function(frame)
    local fin = frame.fin
    local opcode = frame.opcode
    local has_mask = frame.mask
    local op1, op2, op3, op4 = bit.byte_to_four_bits(opcode or WS.Opcode.TEXT)
    local first_byte = bit.bits_to_byte(
        fin,
        false,
        false,
        false,
        op1,
        op2,
        op3,
        op4
    )
    local payload_len = frame.payload and #frame.payload + 1 or 0
    local _, len1, len2, len3, len4, len5, len6, len7 = bit.byte_to_bits(payload_len)
    local second_byte = bit.bits_to_byte(
        has_mask,
        len1,
        len2,
        len3,
        len4,
        len5,
        len6,
        len7
    )
    local payload = frame.payload
    if has_mask then
        local mask_key = WS.rand4()
        payload = WS.maskPayload(payload, mask_key)
        payload_len = #payload
    end
    local bytes = {
        char(first_byte),
        char(second_byte),
    }
    if payload_len < 126 then
        bytes[3] = char(payload_len)
    end
    bytes[#bytes + 1] = payload
    return concat(bytes)
end

---@private
---@param payload string
---@param mask_key string
WS.maskPayload = function(payload, mask_key)
    local bytes = {
        byte(mask_key, 1),
        byte(mask_key, 2),
        byte(mask_key, 3),
        byte(mask_key, 4),
    }
    local masked_payload = {}
    for pos = 1, #payload do
        masked_payload[pos] = char(byte(payload, pos) ~ bytes[(pos - 1) % 4 + 1])
    end
    return concat(masked_payload)
end

---@private
---@param client Socket
WS.close = function(client)
    local frame = WS.encodeFrame {
        fin = true,
        opcode = WS.Opcode.CLOSE,
    }
    -- TODO: This is a hack to avoid returning a response here
    -- then close the connection inside `WS.handleWebSocketResponse`
    -- This whole logic should be reworked and cleaner
    client:write(frame, function(write_err)
        assert(not write_err, write_err)
        client:close()
    end)
end

---@private
---@param req string
---@param client Socket
---@param on_request fun(decoded_frame: ClientWebSocketFrame, client: Socket): ServerWebSocketFrame
---@return string | nil
WS.handleWebSocketRequest = function(req, client, on_request)
    local decoded_frame = WS.decodeFrame(req)
    if not decoded_frame then
        return
    end
    -- print("DECODED", json.encode(decoded_frame))
    if decoded_frame.opcode == WS.Opcode.CLOSE then
        return WS.close(client)
    end
    -- print("PAYLOAD", decoded_frame.payload)
    local response = WS.encodeFrame(on_request(decoded_frame, client))
    return response
end

---@private
---@param res unknown
---@param client Socket
WS.handleWebSocketResponse = function(res, client)
    if not res then
        return
    end
    client:write(res, function(write_err)
        assert(not write_err, write_err)
        -- client:close()
    end)
end

---@private
---@param res Response
---@param client Socket
WS.handleHttpResponse = function(res, client)
    local should_close = res.status ~= http.Status.SWITCHING_PROTOCOLS
    local response = http.response(res)
    client:write(response, function(write_err)
        assert(not write_err, write_err)
        if should_close then
            return client:close()
        end
    end)
end

---@private
---@param headers table<string, string>
WS.getWebSocketHeaders = function(headers)
    local key = headers['Sec-WebSocket-Key']
    local version = headers['Sec-WebSocket-Version']
    -- local protocol = headers['Sec-WebSocket-Protocol']
    -- local extensions = headers['Sec-WebSocket-Extensions']
    -- return key, version, protocol, extensions
    return key, version
end

---@private
---@param socket Socket
WS.onSocket = function(socket)
    socket:keepalive(true, 1000)
end

---@param host string
---@param port integer
---@param on_request fun(decoded_frame: ClientWebSocketFrame, client: Socket): ServerWebSocketFrame
---@return Server
WS.createServer = function(host, port, on_request)
    local server = tcp.createServer({
        host = host,
        port = port,
        on_socket = function(socket)
            socket:keepalive(true, 1000)
        end,
        ---@param res unknown
        on_response = function(res, client)
            local is_http_request = res and res.status
            if is_http_request then
                WS.handleHttpResponse(res, client)
                return
            end
            WS.handleWebSocketResponse(res, client)
        end,
        on_request = function(req, client)
            if not req then
                return {
                    status = http.Status.INTERNAL_SERVER_ERROR,
                }
            end
            local parsed_req = http.parseRequest(req)
            -- isn't a handshake
            if not parsed_req then
                return WS.handleWebSocketRequest(req, client, on_request)
            end
            return WS.handshake(parsed_req, client)
        end
    })
    return server
end

return WS
