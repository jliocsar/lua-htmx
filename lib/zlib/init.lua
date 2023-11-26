local zlib = require "zlib"

local ZlibCompression = {}

---@param value string
ZlibCompression.compress = function(value, level)
    if not level then
        level = 9
    end
    local windowSize = 15 + 16
    local compress = zlib.deflate(level, windowSize)
    return compress(value, "finish")
end

return ZlibCompression
