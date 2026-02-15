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
    vim.api.nvim_win_set_cursor(0, { row, 8 })
    return row
end

function M.parse_lua(lines)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buf)
    vim.bo[buf].filetype = "lua"

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    local parser = vim.treesitter.get_parser(buf, "lua")
    local tree = parser:parse()[1]
    return buf, tree:root()
end

function M.has_csharp_parser()
    local data = vim.fn.stdpath("data")

    -- Add lazy treesitter path if it exists
    local ts_path = data .. "/lazy/nvim-treesitter"
    if vim.loop.fs_stat(ts_path) then
        vim.opt.runtimepath:append(ts_path)
    end

    local parsers = vim.api.nvim_get_runtime_file("parser/c_sharp.so", false)
    return #parsers > 0
end

function M.parse_csharp(lines)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buf)
    vim.bo[buf].filetype = "cs"

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    vim.treesitter.start(buf, "c_sharp") -- important
    local parser = vim.treesitter.get_parser(buf, "c_sharp")
    local tree = parser:parse()[1]

    return buf, tree:root()
end

return M
