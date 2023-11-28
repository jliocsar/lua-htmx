---@class Response
---@field status? status
---@field body? string
---@field headers? table<string, string>
---@field cookies? table<string, string>

---@class Request
---@field method string
---@field path string
---@field version string
---@field query table<string, string>
---@field headers table<string, string>
---@field body string

---@alias error string
---@alias route string
---@alias method "get" | "post" | "put" | "delete" | "head" | "options" | "patch" | "trace" | "connect"
---@class Router
---@field [route] handler

---@alias handler async fun(req: Request): Response
