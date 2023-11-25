local Http = require "lib.http"
local Htmx = require "lib.htmx"

local Router = {}

Router.index = function(req)
    return Http.response(Http.Status.OK, Htmx.template(
        [[<title>Index</title>]],
        [[
            <h1>Index</h1>
            <button hx-post="/clicked" hx-swap="outerHTML">
                Click Me
            </button>
        ]]
    ))
end

Router.clicked = function(req)
    return Http.response(Http.Status.OK, [[
        <div>CLICKED MA HOMIEEEEE</div>
    ]])
end

return Router
