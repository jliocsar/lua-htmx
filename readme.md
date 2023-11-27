# lua-htmx

Simple example of a Lua HTTP server serving HTMX/HTML pages.

## Requirements

- [`luarocks`](https://luarocks.org/#quick-start)
- [`mongo-c-driver`](https://github.com/mongodb/mongo-c-driver)
- [TailwindCSS](https://tailwindcss.com/docs/installation)

## Instructions

### Installing dependencies

```sh
./install
# or if you have all dependencies except the rocks
luarocks install --only-deps ./lua-htmx-dev-1.rockspec
```

### Starting HTTP server

```sh
./start [port] # defaults to `39179`
```

## To do

- [x] gzip compression;
- [x] minify css/html;
- [x] improve caching layer (headers, static requests etc);
- [x] mongodb connection.
