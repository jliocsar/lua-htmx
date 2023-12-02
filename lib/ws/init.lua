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

WS.hashKey = function(key)
    local hash = sha1.bin(key .. WS.MAGIC)
    return base64.encode(hash)
end

---@private
---@param req string
---@param client Socket
WS.onRequest = function(req, client)
    local request = http.parseRequest(req)
    local headers = request.headers
    local is_websocket_connection = headers.Connection == 'Upgrade' and headers.Upgrade == 'websocket'
    local is_get_request = request.method == 'GET'
    local has_origin = headers.Origin ~= nil
    if not has_origin then
        print(term.colors.bg_yellow "WARNING: No Origin header found.")
        print(term.colors.bg_yellow("Request Host: " .. headers.Host))
    end
    local is_valid_websocket_request = is_websocket_connection and is_get_request
    if not is_valid_websocket_request then
        client:close()
        return http.response({
            status = http.Status.BAD_REQUEST,
            headers = {
                ['Sec-WebSocket-Version'] = '13',
            }
        })
    end
    local key, version = WS.getWebSocketHeaders(headers)
    -- print(key, version)
    local hashed_key = WS.hashKey(key)
    print(hashed_key)
    return http.response({
        status = http.Status.SWITCHING_PROTOCOLS,
        headers = {
            ['Upgrade'] = 'websocket',
            ['Connection'] = 'Upgrade',
            ['Sec-WebSocket-Accept'] = hashed_key,
        }
    })
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

WS.server = tcp.createServer("0.0.0.0", 3001, WS.onRequest, WS.onSocket)

return WS
