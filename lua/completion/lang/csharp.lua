local ts = require("completion.lang.ts_util")

local M = {}

function M.is_applicable(bufnr)
    return vim.bo[bufnr].filetype == "cs"
end

-- Could add: member_access_expression (even when error node present)
-- Could also do if current node == initializer_expression and ends with '.' then prompt (Ex: Console.)
---@param context ContextSnapshot
function M.is_eligible(context)
    if context.node_type == "block"
        or context.node_type == "if_statement"
        or context.node_type == "while_statement"
        or context.node_type == "for_statement"
    then
        if not context.err_node_present and
            context.curr_row > context.node_start
            and context.curr_row < context.node_end
        then
            return true
        end
    elseif context.node_type == "variable_declarator" or context.node_type == "binary_expression" then
        return true
    elseif context.node_type == "member_access_expression" then
        return true
    end
    return false
end

--- @return ContextSnapshot?
function M.get_context_snapshot()
    local curr_node = vim.treesitter.get_node()
    local func_node_start, func_node_end = ts.get_current_function_pos(curr_node, "method_declaration")
    if not curr_node or not func_node_start or not func_node_end then
        return nil
    end
    local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
    local scope = ts.get_current_scope(curr_node)
    --- @type ContextSnapshot
    return {
        node_type = curr_node:type(),
        node_start = curr_node:start(),
        node_end = curr_node:end_(),
        scope = not scope and "" or scope:type(),
        curr_row = row - 1,
        err_node_present = ts.contains_err_node(scope),
        func_node_start = func_node_start,
        func_node_end = func_node_end,
        curr_line_text = vim.api.nvim_get_current_line()
    }
end

return M
