local http = require "lib.http"
local HttpRouter = require "lib.http.router"

local htmx = require "server.htmx"

local root_router = HttpRouter:new()

root_router:get("/", function(req)
    local res, err = htmx:layout("index.tpl", {
        title = "Lua HTMX Example"
    })
    if err then
        return {
            status = 500,
            body = tostring(err)
        }
    end
    res.cookies = {
        test = {
            value = "test",
            httponly = true,
            expires = "Wed, 21 Oct 2024 07:28:00 GMT"
        }
    }
    return http.cached(res)
end)

return root_router
