local Tcp = require "lib.http.tcp"

local HTTP_REQUEST_HEAD_MATCH <const> = "([A-Z]+) ([^ ]+) HTTP/([0-9.]+)(.+)"
local HTTP_HEADER_ENTRY_MATCH <const> = "([^:]+):%s([^\r\n]+)"
local HTTP_BODY_MATCH <const> = "\r\n\r\n(.+)"

local Http = {}

Http.Status = {
    OK = "200",
    NOT_FOUND = "404",
    INTERNAL_SERVER_ERROR = "500",
    BAD_REQUEST = "400",
    FORBIDDEN = "403",
    UNAUTHORIZED = "401"
}

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

Http.response = function(status, body)
    local response = "HTTP/1.1 "
        .. status
        .. " OK\r\n"
        .. "Content-Type: text/html\r\n"
    if body then
        response = response
            .. "Content-Length: "
            .. #body
            .. "\r\n\r\n"
            .. body
    else
        response = response .. "\r\n"
    end
    return response
end

Http.createServer = function(host, port, on_request)
    local server = Tcp.createServer(host, port, function(req)
        local parsed_req = Http.parseRequest(req)
        return on_request(parsed_req)
    end)
    return server
end

return Http
