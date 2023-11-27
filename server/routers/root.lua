local http = require "lib.http"
local HttpRouter = require "lib.http.router"

local htmx = require "server.htmx"
local ThingService = require "server.services.thing-service"

local thing_service = ThingService:new()
local root_router = HttpRouter:new()

root_router:get("/", function(req)
    local things = thing_service:list({ foo = req.query.foo })
    local response, err = htmx:layout("test.tpl", {
        title = "Index",
        data = {
            name = "mentals",
            items = things
        }
    })
    if err then
        return {
            status = 500,
            body = tostring(err)
        }
    end
    return http.cached(response)
end)

return root_router
