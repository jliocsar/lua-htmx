---@class RouteHelper
local RouteHelper = {}

---@param modname_prefix string
---@return table<method, table<string, handler>>
RouteHelper.findRouters = function(modname_prefix)
    local find_target_path = modname_prefix
        :gsub("%.", "/")
    local find_routers = io.popen(string.format("find %s -name '*.lua' -type f -exec basename {} .lua \\;",
        find_target_path))
    assert(find_routers, "Failed to find routers")

    ---@type table<method, handler[]>
    local routers = {}
    for router_name in find_routers:lines() do
        local router_file_name = string.format("%s.%s", modname_prefix, router_name)
        ---@type HttpRouter
        local router = require(router_file_name)
        RouteHelper.merge(routers, router)
    end

    find_routers:close()
    return routers
end

---@param routers table<method, handler[]>
---@param router HttpRouter
RouteHelper.merge = function(routers, router)
    local router_meta = getmetatable(router)
    ---@type httprrmeta
    local routes = router_meta.__routes
    for method, handlers in pairs(routes) do
        for route, fn in pairs(handlers) do
            if not routers[method] then
                routers[method] = {}
            end
            if routers[method][route] then
                error("Duplicate router key: " .. route)
            end
            routers[method][route] = fn
        end
    end
end

return RouteHelper
