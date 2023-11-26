local tcp = require "lib.http.tcp"

---@class Response
---@field status? status
---@field body? string
---@field headers? table<string, string>

---@class Request
---@field method string
---@field path string
---@field version string
---@field query table<string, string>
---@field headers table<string, string>
---@field body string

---@class Plugin
---@field use? async fun(req: Request): Response?
---@field new? async fun(res: Response): Response?

---@alias route string
---@class Router
---@field [route] handler

---@alias handler async fun(req: Request): Response?

local HTTP_REQUEST_HEAD_MATCH <const> = "([A-Z]+) ([^ ]+) HTTP/([0-9.]+)(.+)"
local HTTP_HEADER_ENTRY_MATCH <const> = "([^:]+):%s([^\r\n]+)"
local HTTP_BODY_MATCH <const> = "\r\n\r\n(.+)"

---@class Http
local Http = {}

---@enum status
Http.Status = {
    OK = 200,
    NOT_MODIFIED = 304,
    BAD_REQUEST = 400,
    UNAUTHORIZED = 401,
    FORBIDDEN = 403,
    NOT_FOUND = 404,
    INTERNAL_SERVER_ERROR = 500,
}

---@enum mimetype
Http.MimeType = {
    HTML = "text/html",
    CSS = "text/css",
    JS = "text/javascript",
    JSON = "application/json",
    PNG = "image/png",
    JPG = "image/jpeg",
    GIF = "image/gif",
    SVG = "image/svg+xml",
    ICO = "image/x-icon",
    TXT = "text/plain",
    WEBP = "image/webp",
}

-- TODO: How to lazily load this?
---@enum extension
local ExtensionMimeTypeMap = {
    html = Http.MimeType.HTML,
    css = Http.MimeType.CSS,
    js = Http.MimeType.JS,
    json = Http.MimeType.JSON,
    png = Http.MimeType.PNG,
    jpg = Http.MimeType.JPG,
    jpeg = Http.MimeType.JPG,
    gif = Http.MimeType.GIF,
    svg = Http.MimeType.SVG,
    ico = Http.MimeType.ICO,
    txt = Http.MimeType.TXT,
    webp = Http.MimeType.WEBP,
}

---@param res Response
---@param max_age? number
Http.cached = function(res, max_age)
    res.headers = res.headers or {}
    res.headers['Cache-Control'] = 'max-age=' .. (max_age or 3600)
    return res
end

---@param extension extension
---@return mimetype?, error?
Http.extenstionToMimeType = function(extension)
    if not extension then
        return nil
    end
    local mime_type = ExtensionMimeTypeMap[extension]
    if not mime_type then
        return nil, 'Unknown extension'
    end
    return mime_type
end

Http.qs = function(query_string)
    local qs = {}
    if query_string then
        for key, value in query_string:gmatch("([^&]+)=([^&]+)") do
            qs[key] = value
        end
    end
    return qs
end

---@param req string
---@return Request
Http.parseRequest = function(req)
    local method, raw_route_path, version, raw_headers_with_body = req:match(HTTP_REQUEST_HEAD_MATCH)
    local headers_entries = raw_headers_with_body:gmatch(HTTP_HEADER_ENTRY_MATCH)
    local body = raw_headers_with_body:match(HTTP_BODY_MATCH)
    local route_path, query_string = raw_route_path:match("([^?]+)%??(.*)")
    local headers = {}
    for key, value in headers_entries do
        headers[key] = value
    end
    return {
        query = Http.qs(query_string),
        method = method,
        path = route_path,
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
        .. headers
    if body then
        if response.headers and not response.headers['Content-Type'] then
            payload = payload .. "Content-Type: text/plain\r\n"
        end
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
