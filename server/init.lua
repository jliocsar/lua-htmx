local Http = require "lib.http"
local Router = require "server.router"
local Static = require "server.static"

local HOST <const> = [[0.0.0.0]]
local PORT <const> = 39179

local serveStatic = Static.serve()

---@param req Request
---@return string
local function handleRequest(req)
    local static = serveStatic(req)
    if static then
        return static
    end
    local route_name = req.path:sub(2)
    if route_name == '' then
        route_name = 'index'
    end
    local route = Router[route_name]
    if not route then
        return Http.response({
            status = Http.Status.NOT_FOUND,
            body = 'Not found'
        })
    end
    local response = route(req)
    return Http.response(response)
end

local server = Http.createServer(HOST, PORT, handleRequest)
server:start()
