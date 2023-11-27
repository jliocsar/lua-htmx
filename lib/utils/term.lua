local Term = {}

local _reset = "\x1b[0m"

---@param open integer
---@param close integer
---@param close_suffix? string
local function color(open, close, close_suffix)
    local start = ("\x1b[%dm"):format(open)
    local finish = ("\x1b[%dm"):format(close)
    if close_suffix then
        finish = finish .. close_suffix
    end
    return function(text)
        return start .. text .. finish .. _reset
    end
end

local colors = {}

colors.reset = color(0, 0)
colors.bold = color(1, 22, "\x1b[1m")
colors.dim = color(2, 22, "\x1b[2m")
colors.italic = color(3, 23)
colors.underline = color(4, 24)
colors.inverse = color(7, 27)
colors.hidden = color(8, 28)
colors.strikethrough = color(9, 29)
colors.black = color(30, 39)
colors.red = color(31, 39)
colors.green = color(32, 39)
colors.yellow = color(33, 39)
colors.blue = color(34, 39)
colors.magenta = color(35, 39)
colors.cyan = color(36, 39)
colors.white = color(37, 39)
colors.gray = color(90, 39)
colors.bg_black = color(40, 49)
colors.bg_red = color(41, 49)
colors.bg_green = color(42, 49)
colors.bg_yellow = color(43, 49)
colors.bg_blue = color(44, 49)
colors.bg_magenta = color(45, 49)
colors.bg_cyan = color(46, 49)
colors.bg_white = color(47, 49)
colors.black_bright = color(90, 39)
colors.red_bright = color(91, 39)
colors.green_bright = color(92, 39)
colors.yellow_bright = color(93, 39)
colors.blue_bright = color(94, 39)
colors.magenta_bright = color(95, 39)
colors.cyan_bright = color(96, 39)
colors.white_bright = color(97, 39)
colors.bg_black_bright = color(100, 49)
colors.bg_red_bright = color(101, 49)
colors.bg_green_bright = color(102, 49)
colors.bg_yellow_bright = color(103, 49)
colors.bg_blue_bright = color(104, 49)
colors.bg_magenta_bright = color(105, 49)
colors.bg_cyan_bright = color(106, 49)
colors.bg_white_bright = color(107, 49)

Term.colors = colors

Term.resetTerm = function()
    os.execute("tput reset")
end

return Term
