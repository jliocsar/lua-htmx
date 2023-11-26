local http = require "lib.http"
local http_plugins = require "lib.http.plugins"
local htmx = require "lib.htmx"
local router = require "server.router"

local DEFAULT_ROUTE <const> = "index"
local HOST <const> = [[0.0.0.0]]
local PORT <const> = tonumber(arg[1]) or 39179

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
        route_name = DEFAULT_ROUTE
    end
    local method = req.method:lower()
    local method_router_handlers = router[method]
    if not method_router_handlers then
        return htmx.render404()
    end
    local route = method_router_handlers[route_name]
    if not route then
        return htmx.render404()
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
