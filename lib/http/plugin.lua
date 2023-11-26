local http = require "lib.http"

local HttpPlugin = {}

---@param req Request
---@param plugins Plugin[]
---@return string? error?
HttpPlugin.apply = function(req, plugins)
    for _, plugin in ipairs(plugins) do
        local response, plugin_err = plugin(req)
        if plugin_err then
            return http.response {
                status = http.Status.INTERNAL_SERVER_ERROR,
                body = plugin_err
            }
        end
        if response then
            return http.response(response)
        end
    end
end

return HttpPlugin
