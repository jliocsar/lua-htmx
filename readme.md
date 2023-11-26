# lua-htmx

Simple example of a Lua HTTP server serving HTMX/HTML pages.

## Requirements

- [Lua 5.4](https://www.lua.org/manual/5.4/manual.html)
- [`liblua5.4-dev`](https://packages.debian.org/sid/liblua5.4-dev)
- [`luarocks`](https://luarocks.org/#quick-start)

## Instructions

### Installing dependencies

```sh
./install
```

### Starting HTTP server

```sh
./start [port] # defaults to `39179`
```

## To do

- [ ] gzip compression;
- [ ] minify css/html;
- [ ] improve caching layer (headers, static requests etc);
- [ ] mongodb connection.
