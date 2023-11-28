local http = require "lib.http"
local path = require "lib.utils.path"
local env = require "lib.env"
local compress = require "lib.http.plugins.compression"

---@class StaticOptions
---@field prefix? string

---@type table<string, Response>
local cache = {}
local public_path = path.resolve "public"
---@class Static: Plugin
local Static = {}

---@param options? StaticOptions
Static.use = function(options)
    local prefix = options and options.prefix or "static"
    return function(req)
        local req_path = req.path
        local is_static = req_path:find("^/" .. prefix .. "/") ~= nil
        if not is_static then
            return nil
        end
        if cache[req_path] then
            return cache[req_path]
        end
        local file_path = req_path:gsub(prefix .. "/", "")
        local public_file_path = public_path .. file_path
        local file = io.open(public_file_path, "r")
        if not file then
            return { status = http.Status.NOT_FOUND }
        end
        local file_extension = file_path:match(".+%.(.+)$")
        local mime_type = http.extenstionToMimeType(file_extension)
        if not mime_type then
            return {
                status = http.Status.INTERNAL_SERVER_ERROR,
                body = "Unknown file extension being sourced"
            }
        end
        local body = file:read("*a")
        file:close()
        local headers = {
            ["Content-Type"] = mime_type
        }
        -- cache static files only if not in development
        if not env.IS_DEV then
            headers["Cache-Control"] = "public, max-age=31536000, immutable"
        end
        ---@type Response
        local response = compress {
            headers = headers,
            body = body
        }
        cache[req_path] = response
        return response
    end
end

return Static
