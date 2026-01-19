local M = {}

--- @class PromptRequest
--- @field prefix string
--- @field suffix string
function M.prompt_request(prefix_n, suffix_n)
    local file_name = M.get_current_file_name()
    local prefix = M.text_before_cursor(prefix_n)
    local suffix = M.text_after_cursor(suffix_n)
    --- @type PromptRequest
    return {
        prefix = "<file>" .. file_name .. "</file>\n" .. prefix,
        -- Bug with missing the last line of the function (`end` for lua)
        suffix = suffix,
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
    --local start_row = math.max(0, cursor_pos[1] - n)
    local end_row = math.max(0, cursor_pos[1])
    --local prefix_table = vim.api.nvim_buf_get_lines(0, start_row, end_row, false)
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
    if n <= 0 then
        return ""
    end
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local buf_line_count = vim.api.nvim_buf_line_count(0)
    local start_row = math.min(cursor_pos[1], buf_line_count)
    --local end_row = math.min(cursor_pos[1] + n, buf_line_count)
    --local suffix_table = vim.api.nvim_buf_get_lines(0, start_row, end_row, false)
    local suffix_table = vim.api.nvim_buf_get_lines(0, start_row, n + 1, false)
    local current_line = vim.api.nvim_get_current_line()
    local current_line_suffix = string.sub(current_line, cursor_pos[2] + 2, #current_line)
    table.insert(suffix_table, 1, current_line_suffix)
    local suffix = table.concat(suffix_table, "\n")
    return suffix
end

--- Returns the treesitter node of the current function
---@return TSNode?
local function get_function_node()
    local current_node = vim.treesitter.get_node()
    if current_node then
        while current_node and current_node:type() ~= "function_declaration" do
            current_node = current_node:parent()
        end
        return current_node
    end
end

--- Returns the starting row and ending row of the current function. If no function node is found, returns -1 for both.
--- Note: Offset it by 1 (since nvim is 1 based and treesitter is 0 based)
---@return integer? start_row starting row of the function
---@return integer? end_row ending row of the function
function M.get_current_function_pos()
    local function_node = get_function_node()
    if function_node then
        local start_row, _, end_row, _ = function_node:range()
        return start_row, end_row
    end
end

--- @class TreesitterModel
--- @field current_node TSNode?
--- @field func_start number?
--- @field func_end number?

--- @return TreesitterModel
function M.get_treesitter_model()
    local start_row, end_row = M.get_current_function_pos()
    --- @type TreesitterModel
    return {
        current_node = vim.treesitter.get_node(),
        func_start = start_row,
        func_end = end_row
    }
end

function M.print_tree()
    local model = M.get_treesitter_model()
    print("Current node type: " .. model.current_node:type())
end

return M
