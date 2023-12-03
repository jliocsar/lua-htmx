local base64 = require "base64"
local bit = require "external.bit"
local sha1 = require "external.sha1"
local http = require "lib.http"
local tcp = require "lib.http.tcp"
local term = require "lib.utils.term"
local json = require "external.json"

---@class WebSocketFrame
---@field fin boolean
---@field opcode wsopcode
---@field mask boolean
---@field mask_key integer[]
---@field payload integer[]
---@field payload_len? integer
---@field payload_str? string

---@class ClientWebSocketFrame: WebSocketFrame
---@field payload integer[]
---@field payload_len integer
---@field payload_str string

---@class ServerWebSocketFrame: WebSocketFrame
---@field payload string

-- Currently implements version 13 of the WebSocket protocol.
-- No support for `subprotocols` and `extensions` yet.
-- TODO: Support `permessage-deflate` and `client_max_window_bits` extensions.
local WS = {}

WS.MAGIC = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
-- 16 bytes base64 encoded
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

-- print(WS.Opcode.BINARY)

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
        print(term.colors.bg_yellow "WARNING: No Origin header found.")
        print(term.colors.bg_yellow("Request Host: " .. headers.Host))
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

---@private
---@return ClientWebSocketFrame
WS.decodeFrame = function(req)
    local decoded = {}
    local bytes = { string.byte(req, 1, -1) }
    local op4, op3, op2, op1, rsv3, rsv2, rsv1, fin = bit.byte_to_bits(bytes[1])
    local len7, len6, len5, len4, len3, len2, len1, mask = bit.byte_to_bits(bytes[2])
    local mask_key = { table.unpack(bytes, 3, 6) }
    local payload = { table.unpack(bytes, 7, -1) }
    decoded.fin = fin
    decoded.opcode = bit.bits_to_byte(op4, op3, op2, op1)
    decoded.mask = mask
    decoded.payload_len = bit.bits_to_byte(len7, len6, len5, len4, len3, len2, len1)
    decoded.mask_key = mask_key
    decoded.payload = payload
    decoded.payload_str = string.char(table.unpack(payload))
    return decoded
end

---@private
---@param frame ServerWebSocketFrame
---@return string
WS.encodeFrame = function(frame)
    local encoded = {}
    local fin = frame.fin
    local rsv1 = false
    local rsv2 = false
    local rsv3 = false
    local op4, op3, op2, op1 = bit.byte_to_bits(frame.opcode)
    local len7, len6, len5, len4, len3, len2, len1 = bit.byte_to_bits(frame.payload_len)
    local mask = frame.mask
    local mask_key = frame.mask_key
    local payload = mask_key and WS.maskPayload(frame.payload, mask_key) or frame.payload
    local head = bit.bits_to_byte(op4, op3, op2, op1, rsv3, rsv2, rsv1, fin)
    table.insert(encoded, head)
    local mask_and_len = bit.bits_to_byte(len7, len6, len5, len4, len3, len2, len1, mask)
    table.insert(encoded, mask_and_len)
    for pos = 1, #mask_key do
        table.insert(encoded, mask_key[pos])
    end
    for pos = 1, #payload do
        table.insert(encoded, payload[pos])
    end
    return string.char(table.unpack(encoded))
end

---@private
---@param payload string
---@param mask_key integer[]
WS.maskPayload = function(payload, mask_key)
    return payload
    -- local payload_bytes = { string.byte(payload, 1, #payload) }
    -- local masked = {}
    -- for pos = 1, #payload_bytes do
    --     local byte = payload_bytes[pos]
    --     local masked_byte = bit.bxor(byte, mask_key[(pos - 1) % 4 + 1])
    --     table.insert(masked, masked_byte)
    -- end
    -- return string.char(table.unpack(masked))
end

---@private
---@param client Socket
WS.close = function(client)
    local frame = WS.encodeFrame {
        fin = true,
        opcode = WS.Opcode.CLOSE,
        mask = false,
        payload_len = 0,
        payload = "",
        mask_key = {},
    }
    -- TODO: This is a hack to avoid returning a response here
    -- then close the connection inside `WS.handleWebSocketResponse`
    -- This whole logic should be reworked and cleaner
    client:write(frame, function(write_err)
        assert(not write_err, write_err)
    end)
end

---@private
---@param req string
---@param client Socket
---@return string | nil
WS.handleWebSocketRequest = function(req, client)
    local decoded_frame = WS.decodeFrame(req)
    print("DECODED", json.encode(decoded_frame))
    if decoded_frame.opcode == WS.Opcode.CLOSE then
        return WS.close(client)
    end
    return WS.encodeFrame {
        fin = true,
        opcode = WS.Opcode.TEXT,
        mask = false,
        payload_len = #"Hello!",
        payload = "Hello!",
        mask_key = {},
    }
end

---@private
---@param res unknown
---@param client Socket
WS.handleWebSocketResponse = function(res, client)
    if not res then
        return client:close()
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
---@return Server
WS.createServer = function(host, port)
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
                return WS.handleWebSocketRequest(req, client)
            end
            return WS.handshake(parsed_req, client)
        end
    })
    return server
end

return WS
