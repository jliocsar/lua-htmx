local lfs = require "lfs"

local git_ignore_file = io.open(".gitignore", "r")
if not git_ignore_file then
  print("No .gitignore file found")
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
  return path == ".." or path == "." or ignored:find(path)
end

---@type table<string, number>
local last_modified_cached = {}

---@param where string
---@param callback fun(last_modified: number)
local function notify_on_change(where, callback)
  local iter, dir = lfs.dir(where)
  for target in iter, dir do
    if not is_ignored(target) then
      local target_path = where .. "/" .. target
      local target_attr = lfs.attributes(target_path)
      if target_attr == nil then
        print("Failed to get attributes for " .. target)
        os.exit(1)
      end
      if is_file(target_attr.mode) then
        local last_modified = target_attr.modification
        local cached = last_modified_cached[target_path]
        if cached and cached < last_modified then
          print("boink")
          callback(last_modified)
        end
        last_modified_cached[target_path] = last_modified
      end
      if is_dir(target_attr.mode) then
        notify_on_change(target_path, callback)
      end
    end
  end
end

---@param where string
---@param callback fun(last_modified: number)
local function watch(where, callback)
  notify_on_change(where, callback)
  return watch(where, callback)
end

---@class Dev
local Dev = {}

function Dev:new()
  return self
end

function Dev:run()
  os.execute("./start &")
end

function Dev:stop()
  local pid_proc = assert(io.popen("pgrep --full './bin/sh start'", "r"))
  local pid = pid_proc:read "*a"
  pid_proc:close()
  if pid == "" then
    print("No server running")
    os.exit(1)
  end
  os.execute("kill " .. pid)
end

function Dev:restart()
  self:stop()
  self:run()
end

local dev = Dev:new()
local where = arg[1] or "."
watch(where, function()
  print("File changed, restarting server")
  -- dev:restart()
end)
dev:run()
