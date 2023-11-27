local test = require "server.db.models.test"

local ThingService = {}

function ThingService:new()
    return self
end

---@param filter table<string, any>
function ThingService:list(filter)
    local cursor = test:find(filter)
    local things = {}
    for thing in cursor:iterator() do
        table.insert(things, thing.foo)
    end
    return things
end

return ThingService
