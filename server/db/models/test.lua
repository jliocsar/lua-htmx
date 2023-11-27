local client = require "server.db.client"

---@class Type
---@field foo string
---@field bar string

local collection = client:getCollection("lua-mongo-test", "test")

return collection
