local Router = require "lib.http.router"

local devtools = Router:new()
local start = true

devtools:get("/devtools", function(req)
    ---@type Response
    local response = {}
    if start then
        -- response.headers = {
        --     ["HX-Redirect"] = "/"
        -- }
        start = false
    end
    return response
end)

return devtools
