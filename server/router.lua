local htmx = require "lib.htmx"

---@type Router
local Router = {}

Router.index = function(req)
    local response = htmx.layout("test.tpl", {
        title = 'Index',
        data = {
            name = "leafo",
            items = { "Shoe", "Reflector", "Scarf" }
        }
    })
    response.headers['Cache-Control'] = 'max-age=3600'
    return response
end

Router.alone = function(req)
    return htmx.renderFromFile("test.tpl", {
        name = "leafo",
        items = { "Shoe", "Reflector", "Scarf" }
    })
end

Router.clicked = function(req)
    return {
        body = [[
            <h1>Clicked</h1>!!!
        ]]
    }
end

return Router
