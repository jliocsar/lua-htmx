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

---@class CreateServerOptions
---@field host string
---@field port integer
---@field on_request? fun(req: string, client: Socket): unknown
---@field on_response? fun(res: unknown, client: Socket)
---@field on_socket? fun(socket: Socket)

local BACKLOG <const> = 128

local format = string.format
local colors = term.colors

---@class Tcp
local Tcp = {}

---@private
---@param client Socket
---@param on_request? fun(req: string, client: Socket): unknown
---@param on_response? fun(res: unknown, client: Socket)
Tcp.handleConnection = function(client, on_request, on_response)
  client:read_start(function(read_err, req)
    assert(not read_err, read_err)
    if on_request then
      local response = on_request(req, client)
      if on_response then
        on_response(response, client)
      else
        client:write(response, function(write_err)
          assert(not write_err, write_err)
          client:close()
        end)
      end
    else
      client:close()
    end
  end)
end

Tcp.run = function()
  uv.run()
end

---@param options CreateServerOptions
---@return Server
Tcp.createServer = function(options)
  ---@type Socket
  local socket = uv.new_tcp()
  local host = options.host
  local port = options.port

  if options.on_socket then
    options.on_socket(socket)
  end

  socket:bind(host, port)
  socket:listen(BACKLOG, function(err)
    assert(not err, err)
    local client = uv.new_tcp()
    socket:accept(client)
    Tcp.handleConnection(client, options.on_request, options.on_response)
  end)

  local server = {
    socket = socket
  }

  function server:start()
    local current = socket:getsockname()
    if not current then
      print(colors.red_bright(format("Could not start server, is the port %d available?\n", port)))
      os.exit(98)
    end
    local now = colors.blue_bright(os.date "%c")
    local address = colors.underline(format("http://%s:%d", host, port))
    local listening = colors.cyan_bright("Server listening on " .. address)
    print(colors.bold((format("[%s] %s", now, listening))))
  end

  return server
end

return Tcp
