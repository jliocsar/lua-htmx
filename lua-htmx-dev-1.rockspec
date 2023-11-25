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
   "lua >= 5.4",
   "luv >= 1.45",
   "template >= 0.2"
}
build = {
   type = "builtin",
   modules = {
      htmx = "lib/htmx.lua",
      ["http.init"] = "lib/http/init.lua",
      ["http.tcp"] = "lib/http/tcp.lua"
   }
}
