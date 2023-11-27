local path = require "lib.utils.path"

---@class RouteHelper
local RouteHelper = {}

---@param modname_prefix string
---@return table<method, table<string, handler>>
RouteHelper.findRouters = function(modname_prefix)
    local find_routers = io.popen("find " ..
        modname_prefix:gsub("%.", "/") .. " -name '*.lua' -type f -exec basename {} .lua \\;")
    assert(find_routers, "Failed to find routers")
    local routers_iter = find_routers:read("*a"):gmatch("[^\n]+")
    find_routers:close()

    ---@type table<method, handler[]>
    local routers = {}
    for router_name in routers_iter do
        local router_file_name = modname_prefix .. "." .. router_name
        local router = require(router_file_name)
        ---@type table<method, table<string, handler>>
        local router_meta = getmetatable(router)
        for method, handlers in pairs(router_meta) do
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

    return routers
end

return RouteHelper
