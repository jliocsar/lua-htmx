local etlua = require "etlua"
local http = require "lib.http"
local env = require "lib.env"
local html = require "lib.utils.html"
local path = require "lib.utils.path"
local term = require "lib.utils.term"

---@alias templatedata table<string, unknown>

---@class LayoutOptions
---@field data? templatedata
---@field title? string
-- TODO: support <link /> and <script src>
---@field style? string -- inlined css
---@field script? string -- inlined JS

---@class HtmxOptions
---@field pages_root? string -- defaults to `"server/pages"`
---@field components_root? string -- defaults to `"server/components"`

local DEFAULT_LAYOUT_ROOT_PATH <const> = path.resolve "lib/htmx"
local DEFAULT_PAGES_ROOT <const> = "server/pages"
local DEFAULT_COMPONENTS_ROOT <const> = "server/components"

---@class Htmx
---@field pages_root string
---@field components_root string
---@field layout_render fun(data: LayoutOptions): string
local Htmx = {}

---@param file_path string
local function readFileContent(file_path)
    local file = io.open(file_path, "r")
    if not file then
        return nil, "Page not found: " .. file_path
    end
    local content = file:read "*a"
    file:close()
    return content
end

---Creates a new Htmx instance
---@param options? HtmxOptions
function Htmx:new(options)
    if not options then
        options = {}
    end
    if not options.pages_root then
        options.pages_root = DEFAULT_PAGES_ROOT
    end
    if not options.components_root then
        options.components_root = DEFAULT_COMPONENTS_ROOT
    end
    options.pages_root = path.resolveFromRoot(options.pages_root)
    options.components_root = path.resolveFromRoot(options.components_root)
    self.pages_root = options.pages_root
    self.components_root = options.components_root
    local layout_content = self:readLayoutTemplateFile()
    if not layout_content then
        local tmp = self.pages_root
        self.pages_root = DEFAULT_LAYOUT_ROOT_PATH
        layout_content = self:readLayoutTemplateFile()
        self.pages_root = tmp
    end
    local compiled_layout = assert(etlua.compile(layout_content), "Failed to compile layout template")
    self.layout_render = compiled_layout
    return self
end

---Reads the default layout template content and returns it
---@private
function Htmx:readLayoutTemplateFile()
    return self:readPageFile "layout.etlua"
end

---Reads a page template content and returns it
---@private
---@param page_path string
---@return string?, error?
function Htmx:readPageFile(page_path)
    local resolved_page_path = self.pages_root .. "/" .. page_path
    return readFileContent(resolved_page_path)
end

---Reads a component template content and returns it
---@private
---@param component_path string
---@return string?, error?
function Htmx:readComponentFile(component_path)
    local resolved_component_path = self.components_root .. "/" .. component_path
    return readFileContent(resolved_component_path)
end

---Alias to `Htmx:readComponentFile`
---@private
---@param component_path string
---@return string?, error?
local function include(component_path)
    return Htmx:readComponentFile(component_path)
end

---Renders a template string with the given data
---@param template string
---@param data? templatedata
---@return string?, error?
function Htmx:render(template, data)
    local render = etlua.compile(template)
    if not render then
        return nil, "Failed to compile template"
    end
    data = data or {}
    data.include = include
    local rendered = render(data)
    return rendered
end

---Renders a page template and returns the response
---Keep in mind this won't add the layout to the page, meaning you'll have to
---do that yourself (e.g. create your own layout by hand or just use the page content rendered)
---@param page_path string
---@param data? table
---@return Response?, error?
function Htmx:renderPage(page_path, data)
    local template, read_err = self:readPageFile(page_path)
    if not template then
        return nil, string.format("Failed to read template file\n%s", read_err)
    end
    local body, render_err = self:render(template, data)
    if not body then
        return nil, render_err
    end
    return {
        headers = {
            ["Content-Type"] = http.MimeType.HTML
        },
        body = body
    }
end

---Adds the layout to a page template and returns the response
---@param page_path string
---@param options? LayoutOptions
---@return Response, error?
function Htmx:layout(page_path, options)
    if not options then
        options = {}
    end
    local template, render_err = self:renderPage(page_path, options.data)
    if not template then
        print(term.colors.red_bright(render_err))
        return {
            status = http.Status.INTERNAL_SERVER_ERROR,
        }
    end
    local content = template.body
    if env.IS_DEV then
        content = self:injectDevTools(content)
    end
    local body = html.minify(self.layout_render {
        title = options.title,
        content = content
    })
    return {
        headers = {
            ["Content-Type"] = http.MimeType.HTML
        },
        body = body
    }
end

-- TODO: Support websockets
---@private
function Htmx:injectDevTools(content)
    local dev_tools = [[
        <div
            id="devtools"
            hx-get="/devtools"
            hx-trigger="load, every 1s"
        ></div>
    ]]
    return content .. "\r\n" .. dev_tools
end

function Htmx:render404()
    local four_oh_four, render_err = self:layout("404.etlua", {
        title = "404",
    })
    if not four_oh_four then
        return {
            status = http.Status.NOT_FOUND,
            body = tostring(render_err)
        }
    end
    local response = http.cached(four_oh_four)
    response.status = http.Status.NOT_FOUND
    return response
end

return Htmx
