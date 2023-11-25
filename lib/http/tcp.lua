local uv = require 'luv'

local BACKLOG <const> = 128

local Tcp = {}

Tcp.handle_connection = function(client, on_request)
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

Tcp.createServer = function(host, port, on_request)
  local socket = uv.new_tcp()

  socket:bind(host, port)
  socket:listen(BACKLOG, function(err)
    assert(not err, err)
    local client = uv.new_tcp()
    socket:accept(client)
    Tcp.handle_connection(client, on_request)
  end)

  local function start()
    local current = socket:getsockname()
    if not current then
      print(("Could not start server, is the port %d available?"):format(port))
      os.exit(98)
    end
    print("HTTP server listening on " .. host .. ":" .. port)
    uv.run()
  end

  return {
    socket = socket,
    start = start
  }
end

return Tcp
