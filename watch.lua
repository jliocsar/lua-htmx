local inotify = require 'inotify'
local signal = require "posix.signal"
local lfs = require "lfs"

local config = require "config.const"
local term = require "lib.utils.term"
local path = require "lib.utils.path"

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
local watchers = {}

local function is_ignored(target)
  return target == ".." or target == "." or ignored:match(target) ~= nil
end

local function create_dir_watch(dir_path)
  if watchers[dir_path] then
    return watchers[dir_path]
  end
  local watcher = handle:addwatch(dir_path, inotify.IN_MODIFY)
  watchers[dir_path] = watcher
  return watcher
end

local function create_watchers(from)
  local itr, dir = lfs.dir(from)
  create_dir_watch(from)
  for target in itr, dir do
    local is_watchable = target ~= "." and target ~= ".." and not is_ignored(target)
    if is_watchable then
      local resolved_target_path = target
      if from ~= "." then
        resolved_target_path = path.resolve(from, target)
      end
      local attr = lfs.attributes(resolved_target_path)
      if attr then
        if attr.mode == "directory" then
          create_watchers(resolved_target_path)
        end
      end
    end
  end
end

---@param callback fun(last_modified: integer)
local function watch_where(from, callback)
  create_watchers(from)
  local noop = false -- trick around `IN_MODIFY` being triggered twice
  for event in handle:events() do
    if not noop then
      if event.mask == inotify.IN_MODIFY then
        callback(event.wd)
      end
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
  term.resetTerm()
  self:run()
end

local function watch()
  local dev = Dev:new()

  signal.signal(signal.SIGINT, function(signum)
    print(term.colors.yellow_bright("Stopping server"))
    dev:stop()
    handle:close()
    os.exit(128 + signum)
  end)

  dev:run()

  watch_where(where, function()
    print(term.colors.blue_bright("File changed, restarting server"))
    dev:restart()
  end)
end

watch()
