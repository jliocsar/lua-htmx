local Http = require "lib.http"
local Router = require "server.router"
local Static = require "server.static"

local HOST <const> = [[0.0.0.0]]
local PORT <const> = 39179

local function handleRequest(req)
    local static = Static.serve(req)
    if static then
        return static
    end
    local route_name = req.path:sub(2)
    if route_name == '' then
        route_name = 'index'
    end
    local route = Router[route_name]
    if not route then
        return Http.response(404, 'Not found')
    end
    local response = route(req)
    return response
end

local server = Http.createServer(HOST, PORT, handleRequest)
server:start()
