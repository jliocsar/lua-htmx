---@class Logger: Plugin
local Logger = {}

Logger.use = function()
    return function(req)
        local now = os.date(" %Y-%m-%d %H:%M:%S")
        print(req.method .. " " .. req.path .. now)
    end
end

return Logger
