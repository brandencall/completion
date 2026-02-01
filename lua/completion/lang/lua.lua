local M = {}

function M.is_applicable(bufnr)
    return vim.bo[bufnr].filetype == "lua"
end

---@param context ContextSnapshot
function M.is_eligible(context)
    if context.node_type == "if_statement"
        or context.node_type == "while_statement"
        or context.node_type == "for_statement"
    then
        if not context.err_node_present and
            context.curr_row > context.node_start
            and context.curr_row < context.node_end
        then
            return true
        end
    elseif context.node_type == "assignment_statement" or context.node_type == "binary_expression" then
        return true
    elseif context.node_type:match("function") and not context.err_node_present then
        return true
    end
    return false
end

--- Returns the treesitter node of the current function
---@return TSNode?
local function get_function_node(current_node)
    while current_node and not current_node:type():match("function") do
        current_node = current_node:parent()
    end
    return current_node
end

--- Returns the starting row and ending row of the current function. If no function node is found, returns -1 for both.
--- Note: Offset it by 1 (since nvim is 1 based and treesitter is 0 based)
---@return integer? start_row starting row of the function
---@return integer? end_row ending row of the function
local function get_current_function_pos(curr_node)
    local function_node = get_function_node(curr_node)
    if function_node then
        local start_row, _, end_row, _ = function_node:range()
        return start_row, end_row
    end
end

local function get_current_scope(node)
    local scope = node
    while scope and scope:type() ~= "block"
        and not scope:type():match("function") do
        scope = scope:parent()
    end
    return scope
end

local function contains_err_node(node)
    if not node or node:child_count() == 0 then
        return false
    end
    if node:type() == "ERROR" then
        return true
    end
    for i = 0, node:child_count() - 1 do
        if contains_err_node(node:child(i)) then
            return true
        end
    end
    return false
end

--- @class ContextSnapshot
--- @field node_type string
--- @field node_start integer
--- @field node_end integer
--- @field scope string
--- @field curr_row integer
--- @field err_node_present boolean
--- @field func_node_start integer
--- @field func_node_end integer
--- @field curr_line_text string
--- @return ContextSnapshot?
function M.get_context_snapshot()
    local curr_node = vim.treesitter.get_node()
    local func_node_start, func_node_end = get_current_function_pos(curr_node)
    if not curr_node or not func_node_start or not func_node_end then
        return nil
    end
    local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
    local scope = get_current_scope(curr_node)
    --- @type ContextSnapshot
    return {
        node_type = curr_node:type(),
        node_start = curr_node:start(),
        node_end = curr_node:end_(),
        scope = not scope and "" or scope:type(),
        curr_row = row - 1,
        err_node_present = contains_err_node(scope),
        func_node_start = func_node_start,
        func_node_end = func_node_end,
        curr_line_text = vim.api.nvim_get_current_line()
    }
end

return M
