-- sample.lua

-- Global variable
GLOBAL_VALUE = 42

-- Local variable
local pi = 3.14159

-- Table (object-like)
local Point = {}
Point.__index = Point

function Point:new(x, y)
    local obj = setmetatable({}, self)
    obj.x = x
    obj.y = y
    return obj
end

function Point:distance()
    return math.sqrt(self.x * self.x + self.y * self.y)
end

-- Enum-like table
local Status = {
    OK = 1,
    ERROR = 2,
    UNKNOWN = 3
}

-- Generic function with varargs
local function sum(...)
    local total = 0
    for _, value in ipairs({ ... }) do
        total = total + value
    end
    return total
end

-- Higher-order function
local function apply(fn, value)
    return fn(value)
end

-- Closure
local function make_counter(start)
    local count = start or 0
    return function()
        count = count + 1
        return count
    end
end

-- Coroutine example
local function coroutine_example()
    return coroutine.create(function()
        for i = 1, 3 do
            coroutine.yield(i)
        end
    end)
end

-- Main execution block
local function main()
    local numbers = { 1, 2, 3, 4 }
    local result = sum(table.unpack(numbers))

    local p = Point:new(3, 4)

    if result > 5 then
        print("Result is large")
    elseif result == 0 then
        print("Result is zero")
    else
        print("Result is small")
    end

    -- Numeric for
    for i = 1, 3 do
        print("i:", i)
    end

    -- Generic for
    for key, value in pairs(Status) do
        print(key, value)
    end

    -- While loop
    local counter = 0
    while counter < 2 do
        counter = counter + 1
    end

    -- Repeat until
    repeat
        counter = counter - 1
    until counter == 0

    -- Goto + label
    local x = 0
    ::retry::
    x = x + 1
    if x < 2 then
        goto retry
    end

    -- Protected call
    local ok, err = pcall(function()
        error("Something went wrong")
    end)

    if not ok then
        print("Caught error:", err)
    end

    -- Local function inside scope
    local function inner()
        return "inner value"
    end

    print(inner())

    -- Anonymous function
    local squared = apply(function(n)
        return n * n
    end, 5)

    print("Squared:", squared)

    -- Multi-line string
    local text = [[
This is a multi-line string.
It spans multiple lines.
]]

    print(text)
end

main()
