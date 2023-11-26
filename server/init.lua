local App = require "lib.app"

local static = require "lib.http.plugins.static"
local compression = require "lib.http.plugins.compression"
local logger = require "server.plugins.logger"

local HOST <const> = [[0.0.0.0]]
local PORT <const> = tonumber(arg[1]) or 39179

local app = App:new({
    host = HOST,
    port = PORT,
    routers = "server.routers"
})

App:use(static.use())
App:use(logger.use())

function App:afterRequest(_, res)
    local compressed = compression(res)
    return compressed
end

app:start()
