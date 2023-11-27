local http = require "lib.http"
local http_plugins = require "lib.http.plugins"
local route_helper = require "lib.http.route-helper"
local htmx = require "server.htmx"

local DEFAULT_ROUTE <const> = "index"

---@class AppOptions
---@field host string
---@field port number
---Path to get the routes from
---@field routers string

---@class App
---@field private server Server
---@field private plugins handler[]
---@field private routers table<method, handler[]>
---@field onRequest async fun(self: App, req: Request): string
---@field afterRequest async fun(self: App, req?: Request, res?: Response): Response
local App = {
    plugins = {},
    routers = {}
}

---@param options AppOptions
function App:new(options)
    self.routers = route_helper.findRouters(options.routers)
    self.server = http.createServer(options.host, options.port, function(req)
        return self:onRequest(req)
    end)
    return self
end

function App:start()
    self.server:start()
end

---@param plugin handler
function App:use(plugin)
    table.insert(self.plugins, plugin)
end

---@param req Request
function App:onRequest(req)
    local plugin_response = http_plugins.apply(req, self.plugins)
    if plugin_response then
        return plugin_response
    end
    local route_name = req.path:sub(2)
    if route_name == '' then
        route_name = DEFAULT_ROUTE
    end
    local method = req.method:lower()
    local handlers = self.routers[method]
    local route = handlers[route_name]
    if not route then
        return htmx:render404()
    end
    local response = route(req)
    if not response then
        -- all gud just didnt feel like returning a body
        response = {
            status = http.Status.OK
        }
    end
    if self.afterRequest then
        local after_response = self:afterRequest(req, response)
        if after_response then
            return http.response(after_response)
        end
    end
    return http.response(response)
end

return App
