local htmx = require "lib.htmx"

---@alias route string
---@class Router
---@field [route] handler
local Router = {}

Router.index = function(req)
    return {
        body = htmx.template(
            [[<title>Index</title>]],
            [[
                <h1>Index</h1>
                <img width=600 src="/static/rat.webp" />
                <button hx-post="/clicked" hx-swap="outerHTML">
                    Click Me
                </button>
            ]]
        )
    }
end

Router.clicked = function(req)
    return {
        body = [[
            <div>CLICKED MA HOMIEEEEE</div>
        ]]
    }
end

return Router
