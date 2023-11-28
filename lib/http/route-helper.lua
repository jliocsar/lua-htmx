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
        RouteHelper.mapPush(routers, router)
    end

    find_routers:close()
    return routers
end

---@param routers table<method, handler[]>
---@param router HttpRouter
RouteHelper.mapPush = function(routers, router)
    ---@type table<method, table<string, handler>>
    local router_meta = getmetatable(router)
    for method, handlers in pairs(router_meta) do
        print(router_meta, router, method)
        if not routers[method] then
            routers[method] = {}
        end
        for route, fn in pairs(handlers) do
            if routers[method][route] then
                error("Duplicate router key: " .. route)
            end
            routers[method][route] = fn
        end
    end
end

return RouteHelper
