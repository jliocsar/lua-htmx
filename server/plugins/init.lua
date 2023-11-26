local static = require('server.plugins.static')
local logger = require('server.plugins.logger')

---@class Plugin
---@field use? async fun(req: Request): Response?
---@field new? async fun(res: Response): Response?

return { static.use(), logger.use() }
