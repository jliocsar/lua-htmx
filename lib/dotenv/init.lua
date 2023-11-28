---@class Dotenv
local Dotenv = {}

local function readEnvFile()
    local file = io.open(".env", "r")
    if not file then
        return ""
    end
    local env = file:read "a"
    file:close()
    return env
end

---@param env string
Dotenv.parse = function(env)
    local lines = env:gmatch "[^\r\n]+"
    local parsed = {}
    for line in lines do
        if line and line:sub(1, 1) ~= "#" then
            local key, value = line:match("([%w%d_]+)=(.+)")
            if value then
                local safe = value:gsub("^[%s\"]*(.-)[%s\"]*$", "%1")
                parsed[key] = safe
            end
        end
    end
    return parsed
end

local env = Dotenv.parse(readEnvFile())

---@param key string
Dotenv.get = function(key)
    return env[key]
end

---@param key string
Dotenv.set = function(key, value)
    env[key] = value
end

---@param key string
Dotenv.delete = function(key)
    env[key] = nil
end

return Dotenv
