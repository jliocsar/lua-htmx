local dotenv = require "lib.dotenv"

local mongo = require "mongo"
local client = mongo.Client(
    dotenv.get("MONGO_URI") or "mongodb://localhost:27017"
)

return client
