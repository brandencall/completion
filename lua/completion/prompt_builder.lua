local d = require("completion.debug")

local M = {}

local function split_lines(text)
    local lines = {}
    for line in text:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end
    if lines[#lines] == "" then table.remove(lines) end
    return lines
end

--- @class PromptRequest
--- @field prefix string
--- @field suffix string
--- @field suffix_table table
function M.prompt_request(prefix_n, suffix_n)
    local file_name = M.get_current_file_name()
    local prefix = M.text_before_cursor(prefix_n)
    local suffix = M.text_after_cursor(suffix_n)
    local suffix_table = split_lines(suffix)
    --- @type PromptRequest
    return {
        prefix = "<file>" .. file_name .. "</file>\n" .. prefix,
        suffix = suffix,
        suffix_table = suffix_table
    }
end

--- Gets the text before the cursor including the lines above it
---@param n number
---@return string prefix
function M.text_before_cursor(n)
    if not n or n <= 0 then
        return ""
    end
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local end_row = math.max(0, cursor_pos[1])
    local prefix_table = vim.api.nvim_buf_get_lines(0, n, end_row, false)
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
    if not n or n <= 0 then
        return ""
    end
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local buf_line_count = vim.api.nvim_buf_line_count(0)
    local start_row = math.min(cursor_pos[1], buf_line_count)
    -- Need to add 1 to n becuase nvim_buf_get_lines is exclusive
    local suffix_table = vim.api.nvim_buf_get_lines(0, start_row, n + 1, false)
    local current_line = vim.api.nvim_get_current_line()
    local current_line_suffix = string.sub(current_line, cursor_pos[2] + 2, #current_line)
    table.insert(suffix_table, 1, current_line_suffix)
    local suffix = table.concat(suffix_table, "\n")
    return suffix
end

return M
