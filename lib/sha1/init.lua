local h = {
    "0x67452301",
    "0xEFCDAB89",
    "0x98BADCFE",
    "0x10325476",
    "0xC3D2E1F0",
}

local function get_bits_length(str)
    return #str * 8
end

local MESSAGE = "The quick brown fox jumps over the lazy dog"
local EXPECTED = "2fd4e1c67a2d28fced849ee1bb76e7391b93eb12"

local function to_big_endian(n)
    local hex = string.format("%x", n)
    local big_endian = ""
    for i = 1, #hex, 2 do
        local byte = string.sub(hex, i, i + 1)
        big_endian = byte .. big_endian
    end
    return big_endian
end

local function pre_process(message)
    -- append the bit '1' to the message
    local processed = message
    local ml = get_bits_length(processed)
    if ml % 8 ~= 0 then
        processed = processed .. "\x80"
    end
    -- append 0 ≤ k < 512 bits '0', such that the resulting message length in bits
    --      is congruent to −64 ≡ 448 (mod 512)
    local current_length = get_bits_length(processed)
    local padding_length = 448 - current_length
    local padding = string.rep("\x00", padding_length)
    processed = processed .. padding
    -- append ml, the original message length in bits, as a 64-bit big-endian integer.
    --      Thus, the total length is a multiple of 512 bits.
    print(ml)
    print(get_bits_length(processed))
end

print(pre_process(MESSAGE))
