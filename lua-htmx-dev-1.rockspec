package = "lua-htmx"
version = "dev-1"
source = {
   url = "git+ssh://git@github.com/jliocsar/lua-htmx.git"
}
description = {
   homepage = "*** please enter a project homepage ***",
   license = "*** please specify a license ***"
}
dependencies = {
   "etlua >= 1.3",
   "lua >= 5.4",
   "lua-zlib >= 1.2",
   "luv >= 1.45",
}
build = {
   type = "builtin",
   modules = {
      htmx = "lib/htmx.lua",
      ["http.init"] = "lib/http/init.lua",
      ["http.tcp"] = "lib/http/tcp.lua"
   }
}
