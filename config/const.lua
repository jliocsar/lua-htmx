local dotenv = require "lib.dotenv"

local HOST <const> = [[0.0.0.0]]
local PORT <const> = tonumber(dotenv.get("PORT")) or 39179

return {
    HOST = HOST,
    PORT = PORT
}
