local http = require "lib.http"
local http_plugins = require "lib.http.plugins"
local htmx = require "lib.htmx"
local router = require "server.router"

local DEFAULT_ROUTE <const> = "index"

local App = {
    ---@type table<string, (Plugin | Router)[]>
    usable = {}
}

function App:new()
    return self
end

---@param pluginOrRouter Plugin | Router
function App:use(pluginOrRouter)
    table.insert(self.usable, pluginOrRouter)
end

function App:onRequest(req)
    local plugins = {}
    local routers = {}
    for _, usable in ipairs(self.usable) do
        local metatable = getmetatable(usable)
        local is_plugin = metatable.__plugin
        if is_plugin then
            table.insert(plugins, usable)
        else
            table.insert(routers, usable)
        end
    end
    local plugin_response = http_plugins.apply(req, self.usable)
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

return App
