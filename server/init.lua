local http = require "lib.http"
local htmx = require "lib.htmx"
local router = require "server.router"
local static = require "server.static"

local DEFAULT_ROUTE <const> = "index"
local HOST <const> = [[0.0.0.0]]
local PORT <const> = 39179

---@type table<string, string>
local cache = {}

local serveStatic = static.serve()

local function getRouteName(req_path)
    local route_name = req_path:sub(2)
    if route_name == '' then
        return DEFAULT_ROUTE
    end
    return route_name
end

---@param req Request
---@return string
local function handleRequest(req)
    local resource = serveStatic(req)
    if resource then
        return http.response(resource)
    end
    local route_name = getRouteName(req.path)
    if cache[route_name] then
        return cache[route_name]
    end
    local route = router[route_name]
    if not route then
        return http.response(htmx.renderFromFile "404.tpl")
    end
    local response = route(req)
    if not response then
        -- all gud just didnt feel like returning a body
        response = {
            status = http.Status.OK
        }
    end
    return http.response(response)
end

local server = http.createServer(HOST, PORT, handleRequest)
server:start()
