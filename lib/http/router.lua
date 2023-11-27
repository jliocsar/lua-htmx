---@type method[]
local supported_methods = { "get", "post", "put", "delete", "patch" }

HttpRouter = {}

function HttpRouter:new()
    ---@type table<method, table<string, handler>>
    local initial_metatable = {
        get = {},
        post = {},
        put = {},
        delete = {},
        patch = {},
    }
    setmetatable(self, initial_metatable)
    return self
end

---@private
---@param method method
local function createMethodHandler(method)
    ---@param route route
    ---@param handler handler
    return function(self, route, handler)
        local metatable = getmetatable(self)
        metatable[method][route] = handler
        setmetatable(self, metatable)
    end
end
for _, method in pairs(supported_methods) do
    HttpRouter[method] = createMethodHandler(method)
end

return HttpRouter
