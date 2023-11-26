local http = require "lib.http"
local http_plugins = require "lib.http.plugins"
local htmx = require "lib.htmx"
local router = require "server.router"

local DEFAULT_ROUTE <const> = "index"
local HOST <const> = [[0.0.0.0]]
local PORT <const> = tonumber(arg[1]) or 39179

---@type table<string, string>
local cache = {}
local plugins = {
    http_plugins.static.use(),
}

---@param req Request
---@return string
local function handleRequest(req)
    local plugin_response = http_plugins.apply(req, plugins)
    if plugin_response then
        return plugin_response
    end
    local route_name = req.path:sub(2)
    if route_name == '' then
        return DEFAULT_ROUTE
    end
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
    local compressed = http_plugins.compression(response)
    return http.response(compressed)
end

local server = http.createServer(HOST, PORT, handleRequest)
server:start()
