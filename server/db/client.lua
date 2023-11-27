local env = require "lib.env"

local mongo = require "mongo"
local client = mongo.Client(
    env.get("MONGO_URI") or "mongodb://localhost:27017"
)

return client
