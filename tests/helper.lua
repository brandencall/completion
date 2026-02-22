local M = {}

function M.mock_mode_insert()
    local original = vim.fn.mode
    rawset(vim.fn, "mode", function() return "i" end)
    return function()
        rawset(vim.fn, "mode", original)
    end
end

function M.mock_schedule_sync()
    local original = vim.schedule
    rawset(vim, "schedule", function(fn) fn() end)
    return function()
        rawset(vim, "schedule", original)
    end
end

function M.goto_marker(text)
    local row = vim.fn.search(text)
    assert.is_true(row > 0, "Marker not found: " .. text)

    local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
    local col = #line

    vim.api.nvim_win_set_cursor(0, { row, col })

    return row
end

function M.has_parser(parser_name)
    local data = vim.fn.stdpath("data")
    local parser_path = "parser/" .. parser_name .. ".so"

    -- Add lazy treesitter path if it exists
    local ts_path = data .. "/lazy/nvim-treesitter"
    if vim.loop.fs_stat(ts_path) then
        vim.opt.runtimepath:append(ts_path)
    end

    local parsers = vim.api.nvim_get_runtime_file(parser_path, false)
    return #parsers > 0
end

function M.parse_lines(lines, parser_name)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buf)

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    local parser = vim.treesitter.get_parser(buf, parser_name)
    local tree = parser:parse()[1]

    return buf, tree:root()
end

function M.find_identifier(root, buf, name, parser_name)
    local query = vim.treesitter.query.parse(parser_name, [[
              (identifier) @id
            ]])

    for _, node in query:iter_captures(root, buf, 0, -1) do
        local text = vim.treesitter.get_node_text(node, buf)
        if text == name then
            return node
        end
    end
end

return M
