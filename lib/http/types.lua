---@class Socket
---@field bind fun(self: Socket, host: string, port: integer)
---@field listen fun(self: Socket, backlog: integer, callback: fun(err: string))
---@field accept fun(self: Socket, client: Client)
---@field getsockname fun(self: Socket): unknown?
---@field close fun(self: Socket)

---@class Server: { socket: Socket, start: fun() }

---@class Client
---@field read_start fun(self: Client, callback: fun(err: string, data: string))
---@field write fun(self: Client, data: string, callback: fun(err: string))
---@field close fun(self: Client)

---@alias method "get" | "post" | "put" | "delete" | "head" | "options" | "patch" | "trace" | "connect"
---@alias handler async fun(req: Request): Response
---@alias error string
---@alias route string
---@alias httprrmeta table<method, table<string, handler>>
---@alias httprh fun(self: HttpRouter, route_name: string, handler: handler)

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

---@class Router
---@field [route] handler
