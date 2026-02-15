local M = {}

---@param current_node TSNode?
---@param func_node string A string that denotes the lang specific func ("function", "method_declaration")
---@return TSNode?
function M.get_function_node(current_node, func_node)
    local result = current_node
    while result and not result:type():match(func_node) do
        result = result:parent()
    end
    return result
end

--- Returns the starting row and ending row of the current function.
--- Note: Offset it by 1 (since nvim is 1 based and treesitter is 0 based)
--- To be able to get the function declaration, we don't offset the start row by 1
---@param current_node TSNode?
---@param func_node string A string that denotes the lang specific func ("function", "method_declaration")
---@return integer? start_row starting row of the function
---@return integer? end_row ending row of the function
function M.get_current_function_pos(current_node, func_node)
    local function_node = M.get_function_node(current_node, func_node)
    if function_node then
        local start_row, _, end_row, _ = function_node:range()
        return start_row, end_row
    end
end

-- Probably need to update this so that it isn't hardcoded with "block" and "function"
---@param current_node TSNode?
function M.get_current_scope(current_node)
    local scope = current_node
    while scope and scope:type() ~= "block"
        and not scope:type():match("function") do
        scope = scope:parent()
    end
    return scope
end

function M.contains_err_node(node)
    if not node or node:child_count() == 0 then
        return false
    end
    if node:type() == "ERROR" then
        return true
    end
    for i = 0, node:child_count() - 1 do
        if M.contains_err_node(node:child(i)) then
            return true
        end
    end
    return false
end

---@return _ TSNode?
function M.get_node_at_cursor(buf, parser_type)
    local parser = vim.treesitter.get_parser(buf, parser_type)
    local tree = parser:parse()[1]
    local root = tree:root()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    return root:named_descendant_for_range(row - 1, col, row - 1, col)
end

return M
