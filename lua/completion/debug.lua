local M = {}

local function debug(text)
    local file = assert(io.open("test.txt", "a"))
    file:write(text)
    file:close()
end

function M.DebugTreesitterAtCursor()
    local buftype = vim.api.nvim_get_option_value('buftype', { buf = 0 })
    if buftype ~= "" then
        return
    end
    local api = vim.api
    local ts = vim.treesitter

    local buf = api.nvim_get_current_buf()
    local row, col = unpack(api.nvim_win_get_cursor(0))
    row = row - 1

    local byte = api.nvim_buf_get_offset(buf, row) + col

    local named_node = ts.get_node()
    if not named_node then
        debug("No named node at cursor")
        return
    end

    ---@type TSNode?
    local raw_node = named_node
    while raw_node and raw_node:type() == named_node:type() do
        raw_node = raw_node:parent()
    end

    debug("\n=== CURSOR ===\n")
    debug("Current line: " .. vim.api.nvim_get_current_line() .. "\n")
    debug("Row: " .. row + 1 .. " , Col:" .. col .. "\n")
    debug("Byte offset: " .. byte)

    debug("\n=== NODE UNDER CURSOR ===\n")
    debug("Named node: " .. named_node:type() .. "\n")
    debug("Range: " .. named_node:start() .. ", " .. named_node:end_())

    debug("\n=== PARENT CHAIN ===\n")
    ---@type TSNode?
    local cur = named_node
    while cur do
        debug("-" .. cur:type())
        if cur:type():match("function")
            or cur:type():match("method")
            or cur:type() == "block" then
            break
        end
        cur = cur:parent()
    end

    debug("\n=== CHILDREN OF NEAREST SCOPE ===\n")
    -- Add method check along with function
    ---@type TSNode?
    local scope = named_node
    while scope and scope:type() ~= "block"
        and not scope:type():match("function") do
        scope = scope:parent()
    end

    if scope then
        debug("Scope: " .. scope:type() .. "\n")
        for i = 0, scope:child_count() - 1 do
            local child = scope:child(i)
            if child ~= nil then
                debug(string.format(
                    "   [%d] %s (%d → %d)\n",
                    i,
                    child:type(),
                    child:start(),
                    child:end_()
                ))
            end
        end
    end

    debug("\n=== ERROR NODES IN SCOPE ===\n")
    local function scan(n)
        if n:type() == "ERROR" then
            debug("ERROR:" .. n:start() .. "→" .. n:end_())
        elseif n:type() == "MISSING" then
            debug("MISSING:" .. n:start() .. "→" .. n:end_())
        end
        for i = 0, n:child_count() - 1 do
            scan(n:child(i))
        end
    end

    if scope then
        scan(scope)
    end

    debug("\n=== DONE ===\n\n")
end

return M
