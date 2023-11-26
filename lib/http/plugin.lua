---@class Plugin
---@field use? async fun(req: Request): Response?
local Plugin = {}

function Plugin:new()
    return self
end

return Plugin
