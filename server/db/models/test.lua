local client = require "server.db.client"

local collection = client:getCollection("lua-mongo-test", "test")

return collection
