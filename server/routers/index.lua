local http = require "lib.http"
local htmx = require "lib.htmx"
local test = require "server.db.models.test"

---@type Router
local IndexRouter = {}

IndexRouter.index = function(req)
    local foo = req.query.foo
    local cursor = test:find({
        foo = foo
    })
    local items = {}
    for doc in cursor:iterator() do
        if doc.foo then
            table.insert(items, doc.foo)
        end
    end
    local response, err = htmx.layout("test.tpl", {
        title = 'Index',
        data = {
            name = foo or "mentals",
            items = items
        }
    })
    if err then
        return {
            status = 500,
            body = tostring(err)
        }
    end
    return http.cached(response)
end

IndexRouter.alone = function(req)
    return htmx.renderFromFile("test.tpl", {
        name = "leafo",
        items = { "Shoe", "Reflector", "Scarf" }
    })
end

return IndexRouter
