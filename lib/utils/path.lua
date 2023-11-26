local Path = {}

local proc = io.popen('pwd')
if not proc then
    return nil
end

Path.root = proc:read('*a'):gsub('\n', '')
proc:close()

Path.resolve = function(path)
    return Path.root .. '/' .. path
end

return Path
