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
        local original_headers = res.headers
        local response_headers = {
            ["Content-Encoding"] = "gzip"
        }
        if original_headers then
            for header, value in pairs(original_headers) do
                response_headers[header] = value
            end
        end
        local compressed = zlibcomp.compress(original_body)
        return {
            headers = response_headers,
            body = compressed
        }
    end
end

local compress = Compression.new()
return compress
