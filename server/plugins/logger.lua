local term = require "lib.utils.term"

---@class Logger: Plugin
local Logger = {}

Logger.use = function()
    return function(req)
        local now = os.date(" %Y-%m-%d %H:%M:%S")
        print(term.colors.green_bright("%s %s %s"):format(req.method, req.path, now))
    end
end

return Logger
