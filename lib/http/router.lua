---@type method[]
local supported_methods = { "get", "post", "put", "delete", "patch" }

---@alias httprrmeta table<method, table<string, handler>>
---@alias httprh fun(self: HttpRouter, route_name: string, handler: handler)

---@class HttpRouter
---@field private __routes httprrmeta
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
        local meta = getmetatable(self)
        ---@type httprrmeta
        local routes = meta.__routes
        if routes[method][route] then
            error("Duplicate router key: " .. route)
        end
        routes[method][route] = handler
        setmetatable(self, meta)
    end
end

for _, method in pairs(supported_methods) do
    HttpRouter[method] = createMethodHandler(method)
end

---@param self HttpRouter
---@return HttpRouter
function HttpRouter:new()
    local router = {}
    setmetatable(router, {
        __index = self,
        __routes = {
            get = {},
            post = {},
            put = {},
            delete = {},
            patch = {},
        }
    })
    self.__index = self
    return router
end

return HttpRouter
