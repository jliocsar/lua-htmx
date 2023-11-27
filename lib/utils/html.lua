---@class Html
local Html = {}

Html.minify = function(html)
    -- TODO: pls send halp from the lua gigachads
    local minified = html:gsub("\n", "")
        :gsub("%s+>", ">")
        :gsub("%s+/>", "/>")
        :gsub("%s+<", "<")
        :gsub("%s+/<", "/<")
        :gsub(">%s+<", "><")
    return minified
end

return Html
