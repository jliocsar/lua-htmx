local App = require "lib.app"
local static = require "lib.http.plugins.static"
local compression = require "lib.http.plugins.compression"

local config = require "config.const"

local app = App:new({
    host = config.HOST,
    port = config.PORT,
    routers = "server.routers"
})

App:use(static.use())

function App:afterRequest(_, res)
    local compressed = compression(res)
    return compressed
end

app:start()
