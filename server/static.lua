local http = require "lib.http"
local path = require 'lib.utils.path'

---@class StaticOptions
---@field prefix? string

---@type table<string, string>
local cached = {}
local public_path = path.resolve 'public'
---@class Static
local Static = {}

---@param options? StaticOptions
Static.serve = function(options)
    local prefix = options and options.prefix or 'static'
    ---@async
    ---@param req Request
    ---@return Response?
    return function(req)
        local req_path = req.path
        local is_static = req_path:find("^/" .. prefix .. "/") ~= nil
        if not is_static then
            return nil
        end
        if cached[req_path] then
            return {
                status = http.Status.NOT_MODIFIED,
                body = cached[req_path]
            }
        end
        local file_path = req_path:gsub('static/', '')
        local public_file_path = public_path .. file_path
        local file = io.open(public_file_path, 'r')
        if not file then
            return { status = http.Status.NOT_FOUND }
        end
        local content = file:read('*a')
        file:close()
        local response = { body = content }
        cached[req_path] = content
        return response
    end
end

return Static
