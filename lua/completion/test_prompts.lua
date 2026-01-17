-- EXPECTED OUTPUT:
--         sum = sum + i
--         i = i + 1
--     end
--
--     return sum
-- end
local function sum_upto(n)
    local sum = 0
    local i = 1

    while i <= n do

    end
end


-- EXPECTED OUTPUT:
--         return true
--     end
--
--     return false
-- end
local function contains_zero(values)
    for i = 1, #values do
        if values[i] == 0 then

        end
    end
end

-- EXPECTED OUTPUT:
--             result[#result + 1] = values[i]
--         end
--     end
--
--     return result
-- end
local function filter_positive(values)
    local result = {}

    for i = 1, #values do
        if values[i] > 0 then

        end
    end
end


-- EXPECTED OUTPUT:
--         return nil
--     end
--
--     return a / b
-- end
local function safe_div(a, b)
    if b == 0 then

    end
end


-- EXPECTED OUTPUT:
--             break
--         end
--         i = i + 1
--     end
--
--     return i
-- end
local function find_first_nil(values)
    local i = 1

    while i <= #values do
        if values[i] == nil then

        end
    end
end
