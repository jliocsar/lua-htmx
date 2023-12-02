local uv = require "luv"

local term = require "lib.utils.term"

---@class Socket
---@field accept fun(self: Socket, client: Socket)
---@field bind fun(self: Socket, host: string, port: integer)
---@field close fun(self: Socket)
---@field getsockname fun(self: Socket): unknown?
---@field keepalive fun(self: Socket, enable: boolean, delay: integer)
---@field listen fun(self: Socket, backlog: integer, callback: fun(err: string))
---@field read_start fun(self: Socket, callback: fun(err: string, data: string))
---@field write fun(self: Socket, data: string, callback: fun(err: string))

---@class Server: { socket: Socket, start: fun() }

local BACKLOG <const> = 128

---@class Tcp
local Tcp = {}

---@private
---@param client Socket
---@param on_request fun(req: string, client: Socket): string
Tcp.handleConnection = function(client, on_request)
  client:read_start(function(read_err, req)
    assert(not read_err, read_err)
    local response = on_request(req, client)
    if response then
      client:write(response, function(write_err)
        assert(not write_err, write_err)
        client:close()
      end)
    else
      client:close()
    end
  end)
end

---@param host string
---@param port integer
---@param on_request fun(req: string, client: Socket): string
---@param on_socket? fun(socket: Socket)
---@return Server
Tcp.createServer = function(host, port, on_request, on_socket)
  ---@type Socket
  local socket = uv.new_tcp()

  if on_socket then
    on_socket(socket)
  end

  socket:bind(host, port)
  socket:listen(BACKLOG, function(err)
    assert(not err, err)
    local client = uv.new_tcp()
    socket:accept(client)
    Tcp.handleConnection(client, on_request)
  end)

  local function start()
    local current = socket:getsockname()
    if not current then
      print(term.colors.red_bright(string.format("Could not start server, is the port %d available?\n", port)))
      os.exit(98)
    end
    term.resetTerm()
    local now = term.colors.blue_bright(os.date("%c"))
    local address = term.colors.underline(string.format("http://%s:%d", host, port))
    local listening = term.colors.cyan_bright("Server listening on " .. address)
    print(term.colors.bold((string.format("[%s] %s", now, listening))))
    uv.run()
  end

  return {
    socket = socket,
    start = start
  }
end

return Tcp
