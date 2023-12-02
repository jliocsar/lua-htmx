local App = require "lib.app"
local WebSocket = require "lib.ws"
local static = require "lib.http.plugins.static"
local compression = require "lib.http.plugins.compression"
local htmx = require "server.htmx"

local config = require "config.const"

local app = App:new({
    host = config.HOST,
    port = config.PORT,
    routers = "server.routers"
})
local ws = WebSocket.server

App:use(static.use())

function App:render404()
    -- uses the default htmx helper to render `server/pages/404.etlua`
    return htmx:render404()
end

function App:afterRequest(_, res)
    local compressed = compression(res)
    return compressed
end

ws.start()
app:start()
