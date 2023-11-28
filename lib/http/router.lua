---@type method[]
local supported_methods = { "get", "post", "put", "delete", "patch" }

---@alias httprmeta table<method, table<string, handler>>
---@alias httprh fun(self: HttpRouter, route_name: string, handler: handler)

---@class HttpRouter
---@field private __routes httprmeta
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
        if self.__routes[method][route] then
            error("Duplicate router key: " .. route)
        end
        self.__routes[method][route] = handler
    end
end

for _, method in pairs(supported_methods) do
    HttpRouter[method] = createMethodHandler(method)
end

---@param self HttpRouter
---@return HttpRouter
function HttpRouter:new()
    local router = {}
    setmetatable(router, self)
    self.__index = self
    -- TODO: is there a better way to do this?
    ---@type httprmeta
    router.__routes = {
        get = {},
        post = {},
        put = {},
        delete = {},
        patch = {},
    }
    return router
end

return HttpRouter
