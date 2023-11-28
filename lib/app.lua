local http = require "lib.http"
local http_plugins = require "lib.http.plugins"
local route_helper = require "lib.http.route-helper"
local env = require "lib.env"
local devtools = require "lib.devtools"
-- FIXME: Remove this
local htmx = require "server.htmx"

---@class AppOptions
---@field host string
---@field port integer
---@field routers string - path to the routers directory

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
    if env.IS_DEV then
        route_helper.mapPush(self.routers, devtools)
    end
    print(self.routers.get["/"])
    print(self.routers.get["/devtools"])
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
    -- TODO: Allow things like `[:id]` etc in the path
    local route_name = req.path
    local method = req.method:lower()
    local handlers = self.routers[method]
    local route = handlers[route_name]
    if not route then
        -- TODO: 404 page
        return htmx:render404()
    end
    local response = route(req)
    if self.afterRequest then
        local after_response = self:afterRequest(req, response)
        if after_response then
            return http.response(after_response)
        end
    end
    return http.response(response)
end

return App
