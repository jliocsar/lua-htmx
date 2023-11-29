local inotify = require 'inotify'
local signal = require "posix.signal"

local config = require "config.const"
local term = require "lib.utils.term"

local git_ignore_file = io.open(".gitignore", "r")
if not git_ignore_file then
  print(term.colors.red_bright("No .gitignore file found"))
  os.exit(1)
end
local git_ignore = git_ignore_file:read "*a"
git_ignore_file:close()
local ignored = git_ignore .. "\n.git\n.gitignore"
local where = arg[1] or "."
local handle = inotify.init()
local wd = handle:addwatch(where, inotify.IN_MODIFY)

local function is_ignored(path)
  return path == ".." or path == "." or ignored:match(path) ~= nil
end

---@param callback fun(last_modified: integer)
local function watch_where(callback)
  local noop = false -- TODO: understand why
  for ev in handle:events() do
    local ev_name = ev.name
    if not noop and not is_ignored(ev_name) then
      callback(ev_name)
    end
    noop = not noop
  end
end

---@class Dev
local Dev = {}

function Dev:new()
  return self
end

function Dev:run()
  coroutine.wrap(function()
    os.execute("./start -LUA_HTMX=1 &")
  end)()
end

function Dev:stop()
  os.execute("kill $(lsof -t -i:" .. config.PORT .. ")")
end

function Dev:restart()
  self:stop()
  self:run()
end

local dev = Dev:new()

signal.signal(signal.SIGINT, function(signum)
  print(term.colors.yellow_bright("Stopping server"))
  dev:stop()
  handle:rmwatch(wd)
  handle:close()
  os.exit(128 + signum)
end)
dev:run()

watch_where(function()
  print(term.colors.blue_bright("File changed, restarting server"))
  dev:restart()
end)
