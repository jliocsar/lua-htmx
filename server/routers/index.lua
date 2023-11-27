local http = require "lib.http"
local HttpRouter = require "lib.http.router"
local htmx = require "server.htmx"

local test = require "server.db.models.test"

local testRouter = HttpRouter:new()

testRouter:get("index", function(req)
    local cursor = test:find({ foo = req.query.foo })
    local things = {}
    for thing in cursor:iterator() do
        table.insert(things, thing.foo)
    end
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

return testRouter
