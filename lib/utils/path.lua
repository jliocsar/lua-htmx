local Path = {}

Path.getRootPath = function()
    local proc = io.popen('pwd')
    if not proc then
        return nil
    end
    local pwd = proc:read('*a'):gsub('\n', '')
    proc:close()
    return pwd
end

Path.resolve = function(path)
    return Path.getRootPath() .. '/' .. path
end

return Path
