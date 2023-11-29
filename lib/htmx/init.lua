local etlua = require "etlua"
local http = require "lib.http"
local env = require "lib.env"
local path = require "lib.utils.path"
local html = require "lib.utils.html"
local term = require "lib.utils.term"

---@alias templatedata table<string, unknown>

---@class LayoutOptions
---@field data? templatedata
---@field title? string

local DEFAULT_LAYOUT_ROOT_PATH <const> = path.resolve "lib/htmx"
local DEFAULT_TEMPLATES_ROOT <const> = "server/templates"

---@class Htmx
---@field templates_root string
---@field layout_render fun(data: LayoutOptions): string
local Htmx = {}

---@param templates_root? string defaults to `"server/templates"`
function Htmx:new(templates_root)
    if not templates_root then
        templates_root = DEFAULT_TEMPLATES_ROOT
    end
    templates_root = path.resolveFromRoot(templates_root)
    self.templates_root = templates_root
    local layout_content = self:readLayoutTemplateFile()
    if not layout_content then
        local tmp = self.templates_root
        self.templates_root = DEFAULT_LAYOUT_ROOT_PATH
        layout_content = self:readLayoutTemplateFile()
        self.templates_root = tmp
    end
    local compiled_layout = assert(etlua.compile(layout_content), "Failed to compile layout template")
    self.layout_render = compiled_layout
    return self
end

---@private
function Htmx:readLayoutTemplateFile()
    return self:readTemplateFile "layout.tpl"
end

---@async
---@private
---@param template_path string
---@return string?, error?
function Htmx:readTemplateFile(template_path)
    local file = io.open(self.templates_root .. "/" .. template_path, "r")
    if not file then
        return nil, "Template not found: " .. template_path
    end
    local template = file:read "*a"
    file:close()
    return template
end

---@param template string
---@param data? templatedata
---@return string?, error?
function Htmx:render(template, data)
    local render = etlua.compile(template)
    if not render then
        return nil, "Failed to compile template"
    end
    local rendered = render(data)
    return html.minify(rendered)
end

---@param template_path string
---@param data? table
---@return Response?, error?
function Htmx:renderFromFile(template_path, data)
    local template = self:readTemplateFile(template_path)
    if not template then
        return nil, string.format("Failed to read template file \"%s\"", template_path)
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

---@param template_path string
---@param options? LayoutOptions
---@return Response, error?
function Htmx:layout(template_path, options)
    if not options then
        options = {}
    end
    local template, render_err = self:renderFromFile(template_path, options.data)
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
    local body = self.layout_render {
        title = options.title,
        content = content
    }
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
    local four_oh_four, render_err = self:renderFromFile "404.tpl"
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
