local base64 = require "base64"
local sha1 = require "external.sha1"
local http = require "lib.http"
local tcp = require "lib.http.tcp"
local term = require "lib.utils.term"

-- Currently implements version 13 of the WebSocket protocol.
-- No support for `subprotocols` and `extensions` yet.
-- TODO: Support `permessage-deflate` and `client_max_window_bits` extensions.
local WS = {}

WS.MAGIC = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
-- 16 bytes base64 encoded
WS.EXPECTED_KEY_LENGTH = 0x18

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
---@param req string
WS.handleWebSocketRequest = function(req)
    local random_websocket_response_in_bytes = string.char(0x81, 0x85, 0x37, 0xfa, 0x21, 0x3d, 0x7f, 0x9f, 0x4d, 0x51,
        0x58)
    return random_websocket_response_in_bytes
end

---@private
---@param res unknown
---@param client Socket
WS.handleWebSocketResponse = function(res, client)
    -- local random_websocket_response_in_bytes = string.char(0x81, 0x85, 0x37, 0xfa, 0x21, 0x3d, 0x7f, 0x9f, 0x4d, 0x51,
    --     0x58)
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
            if res.status then
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
