---@class Htmx
local Htmx = {}

local source <const> = [[static/htmx.min.js]]

---@param head string
---@param body string
---@return string
Htmx.template = function(head, body)
    return [[
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1" />
        ]]
        .. "<script src=\"" .. source .. "\"></script>"
        .. head
        .. [[</head><body>]]
        .. body
        .. [[</body></html>]]
end

return Htmx
