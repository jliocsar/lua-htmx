local lfs = require "lfs"
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

---@alias filemode "file" | "directory" | "link"  | "other"
---@param mode filemode
local function is_dir(mode)
  return mode == "directory"
end

---@param mode filemode
local function is_file(mode)
  return mode == "file"
end

local function is_ignored(path)
  return path == ".." or path == "." or ignored:match(path) ~= nil
end

---@type table<string, integer>
local last_modified_cached = {}

local lfsattr = lfs.attributes
local lfsdir = lfs.dir

---@param where string
---@param callback fun(last_modified: integer)
local function notify_on_change(where, callback)
  local iter, dir = lfsdir(where)
  for target in iter, dir do
    if not is_ignored(target) then
      local target_path = where .. "/" .. target
      local target_attr = lfsattr(target_path)
      if target_attr == nil then
        print(term.colors.red_bright("Failed to get attributes for " .. target))
        os.exit(1)
      end
      local mode = target_attr.mode
      if is_file(mode) then
        local last_modified = target_attr.modification
        local cached = last_modified_cached[target_path]
        if cached and cached < last_modified then
          callback(last_modified)
        end
        last_modified_cached[target_path] = last_modified
      end
      if is_dir(mode) then
        notify_on_change(target_path, callback)
      end
    end
  end
end

---@param where string
---@param callback fun(last_modified: integer)
local function watch(where, callback)
  while true do
    notify_on_change(where, callback)
  end
end

---@class Dev
local Dev = {}

function Dev:new()
  return self
end

function Dev:run()
  os.execute("./start -LUA_HTMX=1 &")
end

function Dev:stop()
  os.execute("kill $(lsof -t -i:" .. config.PORT .. ")")
end

function Dev:restart()
  self:stop()
  self:run()
end

local dev = Dev:new()
local where = arg[1] or "."

signal.signal(signal.SIGINT, function(signum)
  print(term.colors.yellow_bright("Stopping server"))
  dev:stop()
  os.exit(128 + signum)
end)
dev:run()

watch(where, function()
  print(term.colors.blue_bright("File changed, restarting server"))
  dev:restart()
end)
