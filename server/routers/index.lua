local http = require "lib.http"
local htmx = require "lib.htmx"

---@type Router
local IndexRouter = {}

IndexRouter.index = function(req)
    local foo = req.query.foo
    local response = htmx.layout("test.tpl", {
        title = 'Index',
        data = {
            name = foo or "mentals",
            items = { "Shoe", "Reflector", "Scarf" }
        }
    })
    return http.cached(response)
end


IndexRouter.alone = function(req)
    return htmx.renderFromFile("test.tpl", {
        name = "leafo",
        items = { "Shoe", "Reflector", "Scarf" }
    })
end

return IndexRouter
