---@class Logger: Plugin
local Logger = {}

Logger.use = function()
    return function(req)
        print(req.method .. ' ' .. req.path .. os.date(' %Y-%m-%d %H:%M:%S'))
    end
end

return Logger
