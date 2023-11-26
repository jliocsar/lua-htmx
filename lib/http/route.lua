local Route = {}

---@param modname_prefix string
Route.getRouters = function(modname_prefix)
    local find_routers = io.popen("find server/routers -name '*.lua' -type f -exec basename {} .lua \\;")
    if not find_routers then
        error("Failed to find routers")
    end
    local routers_iter = find_routers:read("*a"):gmatch("[^\n]+")
    find_routers:close()

    local routers = {}
    for router_name in routers_iter do
        local router_file_name = modname_prefix .. "." .. router_name
        local router = require(router_file_name)
        for key, value in pairs(router) do
            if routers[key] then
                error("Duplicate router key: " .. key)
            end
            routers[key] = value
        end
    end

    return routers
end

return Route
