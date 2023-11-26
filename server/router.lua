local find_routers = io.popen("find server/routers -name '*.lua' -type f -exec basename {} .lua \\;")
if not find_routers then
    error("Failed to find routers")
end
local routers_iter = find_routers:read("*a"):gmatch("[^\n]+")
find_routers:close()

local Router = {}

for router_name in routers_iter do
    local router_file_name = "server.routers." .. router_name
    local router = require(router_file_name)
    for key, value in pairs(router) do
        if Router[key] then
            error("Duplicate router key: " .. key)
        end
        Router[key] = value
    end
end

return Router
