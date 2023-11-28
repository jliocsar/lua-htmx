local uv = require "luv"

local term = require "lib.utils.term"

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

local BACKLOG <const> = 128

---@class Tcp
local Tcp = {}

---@private
---@param client Client
---@param on_request fun(req: string): string
Tcp.handleConnection = function(client, on_request)
  client:read_start(function(read_err, req)
    assert(not read_err, read_err)
    local response = on_request(req)
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
---@param on_request fun(req: string): string
---@return Server
Tcp.createServer = function(host, port, on_request)
  local socket = uv.new_tcp()

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
    print(term.colors.bold(term.colors.cyan_bright(string.format("Server listening on %s:%d", host, port))))
    uv.run()
  end

  return {
    socket = socket,
    start = start
  }
end

return Tcp
