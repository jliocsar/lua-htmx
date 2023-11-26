---@class Plugin
---@field use? async fun(req: Request): Response?
local Plugin = {}

function Plugin:new()
    setmetatable(self, {
        __plugin = true,
    })
    return self
end

return Plugin
