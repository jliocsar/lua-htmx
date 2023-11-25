local Http = require "lib.http"

local cached = {}
local Static = {}

Static.serve = function(req)
    local path = req.path
    local is_static = path:find("^/static/") ~= nil
    if not is_static then
        return nil
    end
    if cached[path] then
        return cached[path]
    end
    local file_path = path:gsub('static/', '')
    local file = io.open('../public/' .. file_path, 'r')
    if not file then
        return Http.response(404, 'Not found')
    end
    local content = file:read('*a')
    file:close()
    local response = Http.response(Http.Status.OK, content)
    cached[path] = response
    return response
end

return Static
