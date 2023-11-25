local tcp = require "lib.http.tcp"

---@class Response
---@field status? status
---@field body? string
---@field headers? table<string, string>

---@class Request
---@field method string
---@field path string
---@field version string
---@field headers table<string, string>
---@field body string

---@alias route string
---@class Router
---@field [route] handler

---@alias handler async fun(req: Request): Response | nil

local HTTP_REQUEST_HEAD_MATCH <const> = "([A-Z]+) ([^ ]+) HTTP/([0-9.]+)(.+)"
local HTTP_HEADER_ENTRY_MATCH <const> = "([^:]+):%s([^\r\n]+)"
local HTTP_BODY_MATCH <const> = "\r\n\r\n(.+)"

---@class Http
local Http = {}

---@enum status
Http.Status = {
    OK = "200",
    NOT_MODIFIED = "304",
    BAD_REQUEST = "400",
    UNAUTHORIZED = "401",
    FORBIDDEN = "403",
    NOT_FOUND = "404",
    INTERNAL_SERVER_ERROR = "500",
}

---@param req string
---@return Request
Http.parseRequest = function(req)
    local method, path, version, raw_headers_with_body = req:match(HTTP_REQUEST_HEAD_MATCH)
    local headers_entries = raw_headers_with_body:gmatch(HTTP_HEADER_ENTRY_MATCH)
    local body = raw_headers_with_body:match(HTTP_BODY_MATCH)
    -- FIXME not working
    local headers = {}
    for key, value in headers_entries do
        key = key:lower()
        headers[key] = value
    end
    return {
        method = method,
        path = path,
        version = version,
        headers = headers,
        body = body
    }
end

---@param headers table<string, string>
---@return string
Http.stringifyHeaders = function(headers)
    if not headers then
        return ""
    end
    local str_headers = ""
    for key, value in pairs(headers) do
        str_headers = str_headers .. key .. ": " .. value .. "\r\n"
    end
    return str_headers
end

---@param response Response
---@return string
Http.response = function(response)
    local status = response.status or Http.Status.OK
    local body = response.body
    local headers = Http.stringifyHeaders(response.headers)
    local payload = "HTTP/1.1 " .. status .. " OK\r\n"
        .. "Content-Type: text/html\r\n"
        .. headers
    if body then
        payload = payload
            .. "Content-Length: "
            .. #body
            .. "\r\n\r\n"
            .. body
    else
        payload = payload .. "\r\n"
    end
    return payload
end

---@param host string
---@param port number
---@param on_request fun(req: Request): string
---@return Server
Http.createServer = function(host, port, on_request)
    local server = tcp.createServer(host, port, function(req)
        local parsed_req = Http.parseRequest(req)
        return on_request(parsed_req)
    end)
    return server
end

return Http
