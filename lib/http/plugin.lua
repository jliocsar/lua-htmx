---@class Plugin: { use?: async fun(req: Request): Response? }
local Plugin = {}

function Plugin:new()
    return self
end

return Plugin
