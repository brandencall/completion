local state = require("completion.state_manager")

local M = {}

function M.clear_text()
    if not state.BufferState.buf then return end
    vim.api.nvim_buf_clear_namespace(state.BufferState.buf, state.BufferState.ns, 0, -1)
    state.BufferState.anchor_mark_id = nil
    state.BufferState.text = ""
    state.BufferState.insert_plan = nil
end

---@param row integer
---@param col integer
---@param lines table
---@return integer, integer (last_row_set last_col_set) returns the last row that was set and the column
function M.set_text_first_row(row, col, lines)
    local last_row_set = -1
    local last_col_set = -1

    local start_row = row
    local line_count = #lines

    local line = vim.api.nvim_buf_get_lines(
        state.BufferState.buf,
        row,
        row + 1,
        false
    )[1] or ""

    if col > #line then
        col = 0
    end

    local start_col = col
    local last_line = lines[#lines]
    vim.schedule(function()
        vim.api.nvim_buf_set_text(
            state.BufferState.buf,
            row,
            col,
            row,
            col,
            lines
        )
    end)
    last_row_set = start_row + line_count

    if line_count == 1 then
        last_col_set = start_col + vim.fn.strlen(last_line)
    else
        last_col_set = vim.fn.strlen(last_line)
    end
    return last_row_set, last_col_set
end

--- Inserts N blank lines at the end of the current buffer.
--- @param n integer The number of blank lines to insert.
local function insert_blank_lines_end_of_buffer(n)
    local lines_to_insert = {}
    -- Create a table with 'n' empty strings, each representing a new line.
    for _ = 1, n do
        table.insert(lines_to_insert, "")
    end

    -- Use 0 for the current buffer, -1 as both the start and end line to append at the end of the buffer.
    vim.api.nvim_buf_set_lines(state.BufferState.buf, -1, -1, false, lines_to_insert)
end

---@param row integer
---@param lines table
---@return integer, integer (last_row_set last_col_set) returns the last row that was set and the column
function M.set_text(row, lines)
    local last_row_set = -1
    local last_col_set = -1

    local start_row = row + 1
    local line_count = #lines + 1

    local last_line = lines[#lines]
    local buffer_count = vim.api.nvim_buf_line_count(state.BufferState.buf)

    if start_row >= buffer_count then
        insert_blank_lines_end_of_buffer(start_row - buffer_count)
        start_row = start_row - 1
    end
    vim.schedule(function()
        table.insert(lines, "")
        vim.api.nvim_buf_set_text(
            state.BufferState.buf,
            start_row,
            0,
            start_row,
            0,
            lines
        )
        table.remove(lines)
    end)
    last_row_set = start_row + line_count - 1
    last_col_set = vim.fn.strlen(last_line)

    return last_row_set, last_col_set
end

function M.insert_agent_text()
    if not state.BufferState.buf or not state.BufferState.insert_plan then
        return
    end

    local _, col = unpack(
        vim.api.nvim_buf_get_extmark_by_id(state.BufferState.buf, state.BufferState.ns, state.BufferState.anchor_mark_id, {})
    )

    local rows = {}
    for r, _ in pairs(state.BufferState.insert_plan) do
        table.insert(rows, r)
    end
    table.sort(rows, function(a, b) return a < b end) -- bottom-up

    vim.api.nvim_buf_call(state.BufferState.buf, function()
        vim.cmd("undojoin")
    end)

    local last_row_set = -1
    local last_col_set = -1

    for i, row in ipairs(rows) do
        local lines = state.BufferState.insert_plan[row]
        if #lines > 0 then
            if i == 1 then
                last_row_set, last_col_set = M.set_text_first_row(row, col, lines)
            else
                last_row_set, last_col_set = M.set_text(row, lines)
            end
        end
    end

    vim.schedule(function()
        vim.api.nvim_win_set_cursor(0, { last_row_set, last_col_set })
    end)

    M.clear_text();
    return ""
end

vim.keymap.set('i', '<Tab>', function()
    if state.BufferState.text ~= "" then
        M.insert_agent_text()
        return ""
    end
    return "<Tab>"
end, { expr = true, silent = true })

vim.api.nvim_create_autocmd("User", {
    pattern = "IdleState",
    callback = function()
        M.clear_text()
    end
})

vim.api.nvim_create_autocmd("User", {
    pattern = "UserTyping",
    callback = function()
        M.clear_text()
    end
})

vim.api.nvim_create_autocmd("User", {
    pattern = "AgentRequest",
    callback = function()
        M.clear_text()
    end
})

vim.api.nvim_create_autocmd("User", {
    pattern = "PluginDisabled",
    callback = function()
        M.clear_text()
    end,
})

return M
