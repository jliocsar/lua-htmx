---@class Env
local Env = {}

local function readEnvFile()
    local file = assert(io.open(".env", "r"), "No .env file found")
    local env = file:read "a"
    file:close()
    return env
end

---@param env string
Env.parse = function(env)
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

local env = Env.parse(readEnvFile())

---@param key string
Env.get = function(key)
    return env[key]
end

---@param key string
Env.set = function(key, value)
    env[key] = value
end

---@param key string
Env.delete = function(key)
    env[key] = nil
end

return Env
