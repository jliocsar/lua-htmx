local http = require "lib.http"
local htmx = require "lib.htmx"
local router = require "server.router"
local middlewares = require "server.middlewares"

local DEFAULT_ROUTE <const> = "index"
local HOST <const> = [[0.0.0.0]]
local PORT <const> = tonumber(arg[1]) or 39179

---@type table<string, string>
local cache = {}

local function getRouteName(req_path)
    local route_name = req_path:sub(2)
    if route_name == '' then
        return DEFAULT_ROUTE
    end
    return route_name
end

---@param req Request
---@return string? error?
local function applyMiddlewares(req)
    for _, middleware in ipairs(middlewares) do
        local response, middleware_err = middleware(req)
        if middleware_err then
            return http.response {
                status = http.Status.INTERNAL_SERVER_ERROR,
                body = middleware_err
            }
        end
        if response then
            return http.response(response)
        end
    end
end

---@param req Request
---@return string
local function handleRequest(req)
    local middleware_response = applyMiddlewares(req)
    if middleware_response then
        return middleware_response
    end
    local route_name = getRouteName(req.path)
    if cache[route_name] then
        return cache[route_name]
    end
    local route = router[route_name]
    if not route then
        return http.response(htmx.renderFromFile "404.tpl")
    end
    local response = route(req)
    if not response then
        -- all gud just didnt feel like returning a body
        response = {
            status = http.Status.OK
        }
    end
    return http.response(response)
end

local server = http.createServer(HOST, PORT, handleRequest)
server:start()
