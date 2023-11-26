local static = require('server.middlewares.static')
local logger = require('server.middlewares.logger')

---@class Middleware
---@field use async fun(req: Request): Response?

return { static.use(), logger.use() }
