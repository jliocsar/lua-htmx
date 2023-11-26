local env = require 'lib.utils.env'

local mongo = require 'mongo'
local client = mongo.Client(
    env["MONGO_URI"] or "mongodb://localhost:27017"
)

return client
