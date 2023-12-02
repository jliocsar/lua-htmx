local base64 = require "base64"
local bit = require "external.bit"
local sha1 = require "external.sha1"
local http = require "lib.http"
local tcp = require "lib.http.tcp"
local term = require "lib.utils.term"

---@class WebSocketFrame
---@field fin boolean
---@field opcode wsopcode
---@field mask boolean
---@field payload_len integer
---@field mask_key integer[]
---@field payload integer[]
---@field payload_str string

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
---@return WebSocketFrame
WS.decodeFrame = function(req)
    local decoded = {}
    local bytes = { string.byte(req, 1, #req) }
    local first_byte = bytes[1]
    local fin, rsv1, rsv2, rsv3, op1, op2, op3, op4 = bit.byte_to_bits(first_byte)
    decoded.fin = fin
    decoded.opcode = bit.bits_to_byte(op1, op2, op3, op4)
    local mask, len1, len2, len3, len4 = bit.byte_to_bits(bytes[2])
    decoded.mask = mask
    decoded.payload_len = bit.bits_to_byte(len1, len2, len3, len4)
    local mask_key = { table.unpack(bytes, 3, 6) }
    decoded.mask_key = mask_key
    local payload = { table.unpack(bytes, 15, #bytes) }
    decoded.payload = payload
    decoded.payload_str = string.char(table.unpack(payload))
    return decoded
end

---@private
---@param frame WebSocketFrame
WS.encodeFrame = function(frame)

end

---@private
---@param req string
WS.handleWebSocketRequest = function(req)
    local decoded_frame = WS.decodeFrame(req)
    print(decoded_frame.opcode)
    if decoded_frame.opcode == WS.Opcode.CLOSE then
        return nil
    end
    print(decoded_frame.payload_str)
    return req
end

---@private
---@param res unknown
---@param client Socket
WS.handleWebSocketResponse = function(res, client)
    -- local random_websocket_response_in_bytes = string.char(0x81, 0x85, 0x37, 0xfa, 0x21, 0x3d, 0x7f, 0x9f, 0x4d, 0x51,
    --     0x58)
    if not res then
        client:close()
        return
    end
    client:write(res, function(write_err)
        assert(not write_err, write_err)
        -- client:close()
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
            if res and res.status then
                local should_close = res.status ~= http.Status.SWITCHING_PROTOCOLS
                local response = http.response(res)
                client:write(response, function(write_err)
                    assert(not write_err, write_err)
                    if should_close then
                        client:close()
                    end
                end)
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
                return WS.handleWebSocketRequest(req)
            end
            return WS.handshake(parsed_req, client)
        end
    })
    return server
end

return WS
