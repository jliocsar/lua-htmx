local Http = require "lib.http"

---@class StaticOptions
---@field prefix? string

local function getPublicPath()
    local pwd = io.popen('pwd'):read('*a'):gsub('\n', '')
    return pwd .. '/public'
end

---@type table<string, string>
local cached = {}
local public_path = getPublicPath()
---@class Static
local Static = {}

---@param options? StaticOptions
Static.serve = function(options)
    local prefix = options and options.prefix or 'static'
    ---@async
    ---@param req Request
    return function(req)
        local path = req.path
        local is_static = path:find("^/" .. prefix .. "/") ~= nil
        if not is_static then
            return nil
        end
        if cached[path] then
            return cached[path]
        end
        local file_path = path:gsub('static/', '')
        local public_file_path = public_path .. file_path
        local file = io.open(public_file_path, 'r')
        if not file then
            return Http.response({ status = Http.Status.NOT_FOUND })
        end
        local content = file:read('*a')
        file:close()
        local response = Http.response({ body = content })
        cached[path] = response
        return response
    end
end

return Static
