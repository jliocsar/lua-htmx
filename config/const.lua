local env = require "lib.env"

local HOST <const> = [[0.0.0.0]]
local PORT <const> = tonumber(env.get("PORT")) or 39179

return {
    HOST = HOST,
    PORT = PORT
}
