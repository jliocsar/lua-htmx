---@class Path
local Path = {}

local proc = assert(io.popen("pwd"), "Could not get current working directory")

Path.root = proc:read("*a"):gsub("\n", "")
proc:close()

Path.resolve = function(...)
    return table.concat({ ... }, "/")
end

Path.resolveFromRoot = function(...)
    return Path.resolve(Path.root, ...)
end

return Path
