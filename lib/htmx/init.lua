local etlua = require "etlua"
local http = require "lib.http"
local path = require "lib.utils.path"

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
    file_content = layout_file:read "*a"
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
Htmx.render = function(template, data)
    local render = etlua.compile(template)
    return render(data)
end

---@param template_path string
---@param data? table
---@return Response, error?
Htmx.renderFromFile = function(template_path, data)
    local template = Htmx.readTemplateFile(template_path)
    if not template then
        return { status = http.Status.NOT_FOUND }
    end
    local body = Htmx.render(template, data)
    return {
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
    local template = Htmx.renderFromFile(template_path, options.data)
    local body = layout.file_content
        :gsub(layout.blocks.title, options.title or "Title")
        :gsub(layout.blocks.content, template.body)
    return {
        body = body
    }
end

return Htmx
