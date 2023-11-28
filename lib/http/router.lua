---@type method[]
local supported_methods = { "get", "post", "put", "delete", "patch" }

---@alias httprh fun(self: HttpRouter, route_name: string, handler: handler)

---@class HttpRouter
---@field get httprh
---@field post httprh
---@field put httprh
---@field delete httprh
---@field patch httprh
local HttpRouter = {}

---@private
---@param method method
local function createMethodHandler(method)
    ---@param route route
    ---@param handler handler
    return function(self, route, handler)
        local routes_metatable = getmetatable(self.routes)
        routes_metatable[method][route] = handler
        setmetatable(self.routes, routes_metatable)
    end
end

for _, method in pairs(supported_methods) do
    HttpRouter[method] = createMethodHandler(method)
end

---@param self HttpRouter
---@return HttpRouter
function HttpRouter:new()
    local router = {
        routes = {},
    }
    setmetatable(router, self)
    self.__index = self
    ---@type table<method, table<string, handler>>
    local initial_metatable = {
        get = {},
        post = {},
        put = {},
        delete = {},
        patch = {},
    }
    setmetatable(router.routes, initial_metatable)
    return router
end

return HttpRouter
