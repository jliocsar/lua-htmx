local http = require "lib.http"
local path = require 'lib.utils.path'
local compress = require "server.plugins.compression"

---@class StaticOptions
---@field prefix? string

---@type table<string, Response>
local cache = {}
local public_path = path.resolve 'public'
---@class Static: Plugin
local Static = {}

---@param options? StaticOptions
Static.use = function(options)
    local prefix = options and options.prefix or 'static'
    return function(req)
        local req_path = req.path
        local is_static = req_path:find("^/" .. prefix .. "/") ~= nil
        if not is_static then
            return nil
        end
        if cache[req_path] then
            return cache[req_path]
        end
        local file_path = req_path:gsub(prefix .. '/', '')
        local public_file_path = public_path .. file_path
        local file = io.open(public_file_path, 'r')
        if not file then
            return { status = http.Status.NOT_FOUND }
        end
        local file_extension = file_path:match('.+%.(.+)$')
        local mime_type = http.extenstionToMimeType(file_extension)
        if not mime_type then
            return {
                status = http.Status.INTERNAL_SERVER_ERROR,
                body = "Unknown file extension being sourced"
            }
        end
        local body = file:read('*a')
        file:close()
        ---@type Response
        local response = compress {
            headers = {
                ['Cache-Control'] = 'max-age=31536000, immutable',
                ['Content-Type'] = mime_type
            },
            body = body
        }
        cache[req_path] = response
        return response
    end
end

return Static
