-- Taken from ./sha1.lua

local bit = {}

-- set this to false if you don't want to build several 64k sized tables when
-- loading this file (takes a while but grants a boost of factor 13)
-- local cfg_caching = not iguana.isTest()
local cfg_caching = false

-- local storing of global functions (minor speedup)
local floor, modf = math.floor, math.modf
local format = string.char

-- merge 4 bytes to an 32 bit word
bit.bytes_to_w32 = function(a, b, c, d) return a * 0x1000000 + b * 0x10000 + c * 0x100 + d end
-- split a 32 bit word into four 8 bit numbers
bit.w32_to_bytes = function(i)
    return floor(i / 0x1000000) % 0x100, floor(i / 0x10000) % 0x100, floor(i / 0x100) % 0x100, i % 0x100
end

-- shift the bits of a 32 bit word. Don't use negative values for "bits"
bit.w32_rot = function(bits, a)
    local b2 = 2 ^ (32 - bits)
    local a, b = modf(a / b2)
    return a + b * b2 * (2 ^ (bits))
end

-- caching function for functions that accept 2 arguments, both of values between
-- 0 and 255. The function to be cached is passed, all values are calculated
-- during loading and a function is returned that returns the cached values (only)
bit.cache2arg = function(fn)
    if not cfg_caching then return fn end
    local lut = {}
    for i = 0, 0xffff do
        local a, b = floor(i / 0x100), i % 0x100
        lut[i] = fn(a, b)
    end
    return function(a, b)
        return lut[a * 0x100 + b]
    end
end

-- splits an 8-bit number into 8 bits, returning all 8 bits as booleans
bit.byte_to_bits = function(b)
    local b = function(n)
        local b = floor(b / n)
        return b % 2 == 1
    end
    return b(1), b(2), b(4), b(8), b(16), b(32), b(64), b(128)
end

-- builds an 8bit number from 8 booleans
bit.bits_to_byte = function(a, b, c, d, e, f, g, h)
    local function n(b, x) return b and x or 0 end
    return n(a, 1) + n(b, 2) + n(c, 4) + n(d, 8) + n(e, 16) + n(f, 32) + n(g, 64) + n(h, 128)
end

-- debug function for visualizing bits in a string
bit.bits_to_string = function(a, b, c, d, e, f, g, h)
    local function x(b) return b and "1" or "0" end
    return ("%s%s%s%s %s%s%s%s"):format(x(a), x(b), x(c), x(d), x(e), x(f), x(g), x(h))
end

-- debug function for converting a 8-bit number as bit string
bit.byte_to_bit_string = function(b)
    return bit.bits_to_string(bit.byte_to_bits(b))
end

-- debug function for converting a 32 bit number as bit string
bit.w32_to_bit_string = function(a)
    if type(a) == "string" then return a end
    local aa, ab, ac, ad = bit.w32_to_bytes(a)
    local s = bit.byte_to_bit_string
    return ("%s %s %s %s"):format(s(aa):reverse(), s(ab):reverse(), s(ac):reverse(), s(ad):reverse()):reverse()
end

-- bitwise "and" function for 2 8bit number
bit.band = bit.cache2arg(function(a, b)
    local A, B, C, D, E, F, G, H = bit.byte_to_bits(b)
    local a, b, c, d, e, f, g, h = bit.byte_to_bits(a)
    return bit.bits_to_byte(
        A and a, B and b, C and c, D and d,
        E and e, F and f, G and g, H and h)
end)

-- bitwise "or" function for 2 8bit numbers
bit.bor = bit.cache2arg(function(a, b)
    local A, B, C, D, E, F, G, H = bit.byte_to_bits(b)
    local a, b, c, d, e, f, g, h = bit.byte_to_bits(a)
    return bit.bits_to_byte(
        A or a, B or b, C or c, D or d,
        E or e, F or f, G or g, H or h)
end)

-- bitwise "xor" function for 2 8bit numbers
bit.bxor = bit.cache2arg(function(a, b)
    local A, B, C, D, E, F, G, H = bit.byte_to_bits(b)
    local a, b, c, d, e, f, g, h = bit.byte_to_bits(a)
    return bit.bits_to_byte(
        A ~= a, B ~= b, C ~= c, D ~= d,
        E ~= e, F ~= f, G ~= g, H ~= h)
end)

-- bitwise complement for one 8bit number
bit.bnot = function(x)
    return 255 - (x % 256)
end

-- creates a function to combine to 32bit numbers using an 8bit combination function
local function w32_comb(fn)
    return function(a, b)
        local aa, ab, ac, ad = bit.w32_to_bytes(a)
        local ba, bb, bc, bd = bit.w32_to_bytes(b)
        return bit.bytes_to_w32(fn(aa, ba), fn(ab, bb), fn(ac, bc), fn(ad, bd))
    end
end

-- create functions for and, xor and or, all for 2 32bit numbers
bit.w32_and = w32_comb(bit.band)
bit.w32_xor = w32_comb(bit.bxor)
bit.w32_or = w32_comb(bit.bor)

-- xor function that may receive a variable number of arguments
bit.w32_xor_n = function(a, ...)
    local aa, ab, ac, ad = bit.w32_to_bytes(a)
    for i = 1, select('#', ...) do
        local ba, bb, bc, bd = bit.w32_to_bytes(select(i, ...))
        aa, ab, ac, ad = bit.bxor(aa, ba), bit.bxor(ab, bb), bit.bxor(ac, bc), bit.bxor(ad, bd)
    end
    return bit.bytes_to_w32(aa, ab, ac, ad)
end

-- combining 3 32bit numbers through binary "or" operation
bit.w32_or3 = function(a, b, c)
    local aa, ab, ac, ad = bit.w32_to_bytes(a)
    local ba, bb, bc, bd = bit.w32_to_bytes(b)
    local ca, cb, cc, cd = bit.w32_to_bytes(c)
    return bit.bytes_to_w32(
        bit.bor(aa, bit.bor(ba, ca)), bit.bor(ab, bit.bor(bb, cb)), bit.bor(ac, bit.bor(bc, cc)),
        bit.bor(ad, bit.bor(bd, cd))
    )
end

-- binary complement for 32bit numbers
bit.w32_not = function(a)
    return 4294967295 - (a % 4294967296)
end

-- adding 2 32bit numbers, cutting off the remainder on 33th bit
bit.w32_add = function(a, b) return (a + b) % 4294967296 end

-- adding n 32bit numbers, cutting off the remainder (again)
bit.w32_add_n = function(a, ...)
    for i = 1, select('#', ...) do
        a = (a + select(i, ...)) % 4294967296
    end
    return a
end
-- converting the number to a hexadecimal string
bit.w32_to_hexstring = function(w) return ("%08x"):format(w) end

return bit
