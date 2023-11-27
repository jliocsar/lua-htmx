---@class Path
local Path = {}

local proc = assert(io.popen("pwd"), "Could not get current working directory")

Path.root = proc:read("*a"):gsub("\n", "")
proc:close()

Path.resolve = function(path)
    return Path.root .. "/" .. path
end

return Path
