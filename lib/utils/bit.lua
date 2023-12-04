-- Taken & modified from external/sha1.lua
local bit = {}

-- local storing of global functions (minor speedup)
local floor = math.floor

-- caching function for functions that accept 2 arguments, both of values between
-- 0 and 255. The function to be cached is passed, all values are calculated
-- during loading and a function is returned that returns the cached values (only)
bit.memo = function(fn)
    local memo = {}
    for idx = 0, 0xffff do
        local a, b = floor(idx / 0x100), idx % 0x100
        memo[idx] = fn(a, b)
    end
    return function(a, b)
        return memo[a * 0x100 + b]
    end
end

-- splits an 8-bit number into 8 bits, returning all 8 bits as booleans
---@param b8 integer
---@return boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean
bit.byte_to_bits = function(b8)
    local to_bit = function(n)
        return floor(b8 / n) % 2 == 1
    end
    return to_bit(128), to_bit(64), to_bit(32), to_bit(16), to_bit(8), to_bit(4), to_bit(2), to_bit(1)
end

-- splits an 8-bit number into 4 bits, returning all 4 bits as booleans
---@param b8 integer
---@return boolean, boolean, boolean, boolean
bit.byte_to_four_bits = function(b8)
    local to_bit = function(n)
        return floor(b8 / n) % 2 == 1
    end
    return to_bit(8), to_bit(4), to_bit(2), to_bit(1)
end

-- builds an 8bit number from 8 booleans
---@param a128 boolean
---@param b64 boolean
---@param c32 boolean
---@param d16 boolean
---@param e8 boolean
---@param f4 boolean
---@param g2 boolean
---@param h1 boolean
---@return integer
bit.bits_to_byte = function(a128, b64, c32, d16, e8, f4, g2, h1)
    local nml = function(bx, x) return bx and x or 0 end
    return nml(a128, 128) + nml(b64, 64) + nml(c32, 32) + nml(d16, 16) + nml(e8, 8) + nml(f4, 4) + nml(g2, 2) +
        nml(h1, 1)
end

-- builds an 8bit number from 4 booleans
---@param a8 boolean
---@param b4 boolean
---@param c2 boolean
---@param d1 boolean
---@return integer
bit.four_bits_to_byte = function(a8, b4, c2, d1)
    local nml = function(bx, x) return bx and x or 0 end
    return nml(a8, 8) + nml(b4, 4) + nml(c2, 2) + nml(d1, 1)
end

-- debug function for visualizing bits in a string

---@param a128 boolean
---@param b64 boolean
---@param c32 boolean
---@param d16 boolean
---@param e8 boolean
---@param f4 boolean
---@param g2 boolean
---@param h1 boolean
---@return string
bit.bits_to_string = function(a128, b64, c32, d16, e8, f4, g2, h1)
    local x = function(bx) return bx and "1" or "0" end
    return ("%s%s%s%s %s%s%s%s"):format(x(a128), x(b64), x(c32), x(d16), x(e8), x(f4), x(g2), x(h1))
end

-- debug function for converting a 8-bit number as bit string
---@param b8 integer
---@return string
bit.byte_to_bit_string = function(b8)
    return bit.bits_to_string(bit.byte_to_bits(b8))
end

-- bitwise "and" function for 2 8bit number
bit.band = bit.memo(function(a8, b8)
    local Ax, Bx, Cx, Dx, Ex, Fx, Gx, Hx = bit.byte_to_bits(b8)
    local ax, bx, cx, dx, ex, fx, gx, hx = bit.byte_to_bits(a8)
    return bit.bits_to_byte(
        Ax and ax, Bx and bx, Cx and cx, Dx and dx,
        Ex and ex, Fx and fx, Gx and gx, Hx and hx)
end)

-- bitwise "or" function for 2 8bit numbers
bit.bor = bit.memo(function(a8, b8)
    local Ax, Bx, Cx, Dx, Ex, Fx, Gx, Hx = bit.byte_to_bits(b8)
    local ax, bx, cx, dx, ex, fx, gx, hx = bit.byte_to_bits(a8)
    return bit.bits_to_byte(
        Ax or ax, Bx or bx, Cx or cx, Dx or dx,
        Ex or ex, Fx or fx, Gx or gx, Hx or hx)
end)

-- bitwise "xor" function for 2 8bit numbers
bit.bxor = bit.memo(function(a8, b8)
    local Ax, Bx, Cx, Dx, Ex, Fx, Gx, Hx = bit.byte_to_bits(b8)
    local ax, bx, cx, dx, ex, fx, gx, hx = bit.byte_to_bits(a8)
    return bit.bits_to_byte(
        Ax ~= ax, Bx ~= bx, Cx ~= cx, Dx ~= dx,
        Ex ~= ex, Fx ~= fx, Gx ~= gx, Hx ~= hx)
end)

-- bitwise complement for one 8bit number
bit.bnot = function(b8)
    return 255 - (b8 % 256)
end

return bit
