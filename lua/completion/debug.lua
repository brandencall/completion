local M = {}

function M.debug(text)
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
        M.debug("No named node at cursor")
        return
    end

    ---@type TSNode?
    local raw_node = named_node
    while raw_node and raw_node:type() == named_node:type() do
        raw_node = raw_node:parent()
    end

    M.debug("\n=== CURSOR ===\n")
    M.debug("Current line: " .. vim.api.nvim_get_current_line() .. "\n")
    M.debug("Row: " .. row + 1 .. " , Col:" .. col .. "\n")
    M.debug("Byte offset: " .. byte)

    M.debug("\n=== NODE UNDER CURSOR ===\n")
    M.debug("Named node: " .. named_node:type() .. "\n")
    M.debug("Range: " .. named_node:start() .. ", " .. named_node:end_())

    M.debug("\n=== PARENT CHAIN ===\n")
    ---@type TSNode?
    local cur = named_node
    while cur do
        M.debug("-" .. cur:type())
        if cur:type():match("function")
            or cur:type():match("method")
            or cur:type() == "block" then
            break
        end
        cur = cur:parent()
    end

    M.debug("\n=== CHILDREN OF NEAREST SCOPE ===\n")
    -- Add method check along with function
    ---@type TSNode?
    local scope = named_node
    while scope and scope:type() ~= "block"
        and not scope:type():match("function") do
        scope = scope:parent()
    end

    if scope then
        M.debug("Scope: " .. scope:type() .. "\n")
        for i = 0, scope:child_count() - 1 do
            local child = scope:child(i)
            if child ~= nil then
                M.debug(string.format(
                    "   [%d] %s (%d → %d)\n",
                    i,
                    child:type(),
                    child:start(),
                    child:end_()
                ))
            end
        end
    end

    M.debug("\n=== ERROR NODES IN SCOPE ===\n")
    local function scan(n)
        if n:type() == "ERROR" then
            M.debug("ERROR:" .. n:start() .. "→" .. n:end_())
        end
        for i = 0, n:child_count() - 1 do
            scan(n:child(i))
        end
    end

    if scope then
        scan(scope)
    end

    M.debug("\n=== DONE ===\n\n")
end

return M
