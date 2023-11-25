local http = require "lib.http"
local router = require "server.router"
local static = require "server.static"

local HOST <const> = [[0.0.0.0]]
local PORT <const> = 39179

local serveStatic = static.serve()

---@param req Request
---@return string
local function handleRequest(req)
    local resource = serveStatic(req)
    if resource then
        return http.response(resource)
    end
    local route_name = req.path:sub(2)
    if route_name == '' then
        route_name = 'index'
    end
    local route = router[route_name]
    if not route then
        return http.response {
            status = http.Status.NOT_FOUND,
            body = 'Not found'
        }
    end
    local response = route(req)
    return http.response(response)
end

local server = http.createServer(HOST, PORT, handleRequest)
server:start()
