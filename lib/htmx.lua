local etlua = require "etlua"
local http = require "lib.http"
local path = require "lib.utils.path"

---@alias templatedata table<string, unknown>
---@alias error string

---@class LayoutOptions
---@field data? templatedata
---@field title? string

local templates_path = path.resolve 'server/templates'

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

---@type table<string, Response>
local cache = {}
local layout = Htmx.readTemplateFile("layout.tpl")
local layout_render = etlua.compile(layout)

---@param template string
---@param data? templatedata
Htmx.render = function(template, data)
    local render = etlua.compile(template)
    return render(data)
end

---@param template_path string
---@param data table
---@return Response, error?
Htmx.renderFromFile = function(template_path, data)
    if cache[template_path] then
        return cache[template_path]
    end
    local template = Htmx.readTemplateFile(template_path)
    if not template then
        return { status = http.Status.NOT_FOUND }
    end
    local body = Htmx.render(template, data)
    cache[template_path] = {
        status = http.Status.NOT_MODIFIED,
        body = body
    }
    return {
        body = body
    }
end

---@param template_path string
---@param options LayoutOptions
---@return Response, error?
Htmx.layout = function(template_path, options)
    if cache[template_path] then
        return cache[template_path]
    end
    local template = Htmx.renderFromFile(template_path, options.data)
    local body = layout_render {
        title = options.title,
        content = template.body
    }
    cache[template_path] = {
        status = http.Status.NOT_MODIFIED,
        body = body
    }
    return {
        body = body
    }
end

return Htmx
