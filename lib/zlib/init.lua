local zlib = require "zlib"

local GZIP_WINDOW_SIZE <const> = 15 + 16

local ZlibCompression = {}

---@param value string
ZlibCompression.compress = function(value, level)
    if not level then
        level = 5
    end
    local compress = zlib.deflate(level, GZIP_WINDOW_SIZE)
    return compress(value, "finish")
end

return ZlibCompression
