local etlua = require "etlua"
local http = require "lib.http"
local path = require "lib.utils.path"
local html = require "lib.utils.html"

---@alias templatedata table<string, unknown>
---@alias error string

---@class LayoutOptions
---@field data? templatedata
---@field title? string

---@param block string
local function internal_tplb(block)
    return "%<%!%-%-%[" .. block .. "%]%-%-%>"
end

local layout_file = io.open(path.resolve '/lib/htmx/layout.html', "r")
if not layout_file then
    error "Could not find layout.html"
end
local layout = {
    blocks = {
        title = internal_tplb "title",
        content = internal_tplb "content"
    },
    file_content = html.minify(layout_file:read "*a")
}
layout_file:close()
local templates_path = path.resolve '/server/templates'

---@class Htmx
local Htmx = {}

---@async
---@param template_path string
---@return string?, error?
Htmx.readTemplateFile = function(template_path)
    local file = io.open(templates_path .. '/' .. template_path, "r")
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
Htmx.render = function(template, data)
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
Htmx.renderFromFile = function(template_path, data)
    local template = Htmx.readTemplateFile(template_path)
    if not template then
        return { status = http.Status.NOT_FOUND }
    end
    local body, render_err = Htmx.render(template, data)
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
Htmx.layout = function(template_path, options)
    if not options then
        options = {}
    end
    local template, render_err = Htmx.renderFromFile(template_path, options.data)
    if not template then
        print(render_err)
        return {
            status = http.Status.INTERNAL_SERVER_ERROR,
        }
    end
    local body = layout.file_content
        :gsub(layout.blocks.title, options.title or "Title")
        :gsub(layout.blocks.content, template.body)
    return {
        headers = {
            ["Content-Type"] = http.MimeType.HTML
        },
        body = body
    }
end

return Htmx
