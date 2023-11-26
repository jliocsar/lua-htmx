local Logger = {}

Logger.use = function()
    return function(req)
        print(req.method .. ' ' .. req.path)
    end
end

return Logger
