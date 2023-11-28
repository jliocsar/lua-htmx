local http = require "lib.http"
local HttpRouter = require "lib.http.router"

local htmx = require "server.htmx"

local root_router = HttpRouter:new()

root_router:get("/", function()
    local response, err = htmx:layout("index.tpl", {
        title = "Lua HTMX Example"
    })
    if err then
        return {
            status = 500,
            body = tostring(err)
        }
    end
    response.cookies = {
        Test = "Test cookies"
    }
    return http.cached(response)
end)

return root_router
