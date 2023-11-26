local function get()
    local file = io.open(".env", "r")
    if not file then
        print "No .env file found"
        os.exit(1)
    end
    local env = file:read "a"
    file:close()
    return env
end

local function parse(env)
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

local env = parse(get())

return env
