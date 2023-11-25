local Path = {}

Path.getRootPath = function()
    local pwd = io.popen('pwd'):read('*a'):gsub('\n', '')
    return pwd
end

Path.resolve = function(path)
    return Path.getRootPath() .. '/' .. path
end

return Path
