local zlibcomp = require "lib.zlib"

---@class Compression: Plugin
local Compression = {}

Compression.new = function()
    ---Blesses a response with gzip compression
    ---@param res Response
    ---@return Response
    return function(res)
        local original_body = res.body
        if not original_body then
            return res
        end
        if not res.headers then
            res.headers = {}
        end
        res.headers["Content-Encoding"] = "gzip"
        res.body = zlibcomp.compress(original_body)
        return res
    end
end

local compress = Compression.new()
return compress
