local Http = require "lib.http"
local Router = require "server.router"

local HOST <const> = [[0.0.0.0]]
local PORT <const> = 39179

local Static = {}

local function handleRequest(req)
    local path = req.path:sub(2)
    local is_static = path:find("^static/") ~= nil
    if is_static then
        if Static[path] then
            return Static[path]
        end
        local file_path = path:gsub('static/', '')
        local file = io.open('../public/' .. file_path, 'r')
        if file then
            local content = file:read('*a')
            file:close()
            local response = Http.response(Http.Status.OK, content)
            Static[path] = response
            return response
        else
            return Http.response(404, 'Not found')
        end
    end
    if path == '' then
        path = 'index'
    end
    local route = Router[path]
    if not route then
        return Http.response(404, 'Not found')
    end
    local response = route(req)
    return response
end

local server = Http.createServer(HOST, PORT, handleRequest)
server:start()
