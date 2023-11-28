# lua-htmx

Lua + MongoDB + HTMX + Tailwind

HTTP server built on top of [luv](https://github.com/luvit/luv) focused in high-performance.

- File-system routing for easy definition of new routes;
- Responses compressed with [zlib](https://www.zlib.net/);
- APIs for common use cases (HTTP, HTMX, routing, path resolving, plugins and such).

👷‍♂️ **Work in progress!**

## Structure

- `config/`: Contains `.lua` files with app-related configurations, such as the port number etc;
- `lib/`: Has all dependencies to build & bootstrap an HTTP server with routes, plugins and such. This folder is _and should be_ separated of all the server business logic; It is a framework _per se_;
- `public/`: The folder server as the static directory from the HTTP server by default;
- `server/`: The application itself;
- `install`: Installs all dependencies to run the server (rocks, `tailwindcss/cli` etc);
- `build`: Builds the app styles with Tailwind's CLI;
- `start`: Starts the HTTP server;
- `watch`: Starts the HTTP server in watch mode;
- `dev`: Runs both `build` in watch mode and `watch`.

## Requirements

- [`build-essential`](https://packages.debian.org/pt-br/sid/build-essential)
- [`mongo-c-driver`](https://github.com/mongodb/mongo-c-driver)
- [`mprocs`](https://github.com/pvolok/mprocs) _for dev_

## Instructions

### Installing dependencies

```sh
./install
# or if you have all dependencies except the rocks
luarocks make --local
```

### Starting the HTTP server

```sh
./start [port] # defaults to `39179`
```

### Development

This command will start the `tailwindcss` build in `--watch` mode; it'll also run the HTTP server in watch mode, meaning it'll restart on every file change detected.

```sh
./dev [port]
```

## To do

- [ ] Would `sqlite` be better?
