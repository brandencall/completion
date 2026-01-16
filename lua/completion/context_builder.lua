-- Current context gathering will on raw lines.
-- Later context gathering will query treesitter to see if in a function. If we are in a function,
-- Use function start -> cursor as prefix, and cursor -> function end as suffix
-- Else, we just fall back to raw lines

local M = {}

--- @class PromptRequest
--- @field type string
--- @field prefix string
--- @field suffix string
--- @field file_name string
function M.prompt_request(prefix_n, suffix_n)
    --- @type PromptRequest
    return {
        type = "prompt",
        prefix = M.text_before_cursor(prefix_n),
        suffix = M.text_after_cursor(suffix_n),
        file_name = M.get_current_file_name()
    }
end

--- Gets the text before the cursor including the lines above it
---@param n number
---@return string prefix
function M.text_before_cursor(n)
    if n <= 0 then
        return ""
    end
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local start_row = math.max(0, cursor_pos[1] - n)
    local end_row = math.max(0, cursor_pos[1] - 1)
    local prefix_table = vim.api.nvim_buf_get_lines(0, start_row, end_row, false)
    local current_line_prefix = string.sub(vim.api.nvim_get_current_line(), 1, cursor_pos[2] + 1)
    table.insert(prefix_table, current_line_prefix)
    local prefix = table.concat(prefix_table, "\n")
    return prefix
end

---@return string file_name returns the current file name with extension
function M.get_current_file_name()
    return vim.fn.expand("%:t")
end

--- Gets the text after the cursor including the lines below it
---@param n number
---@return string suffix
function M.text_after_cursor(n)
    if n <= 0 then
        return ""
    end
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local buf_line_count = vim.api.nvim_buf_line_count(0)
    local start_row = math.min(cursor_pos[1], buf_line_count)
    local end_row = math.min(cursor_pos[1] + n, buf_line_count)
    local suffix_table = vim.api.nvim_buf_get_lines(0, start_row, end_row, false)
    local current_line = vim.api.nvim_get_current_line()
    local current_line_suffix = string.sub(current_line, cursor_pos[2] + 2, #current_line)
    table.insert(suffix_table, 1, current_line_suffix)
    local suffix = table.concat(suffix_table, "\n")
    return suffix
end

return M
