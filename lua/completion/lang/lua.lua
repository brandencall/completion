local ts = require("completion.lang.ts_util")
local categories = require("completion.categories")
local lang = require("completion.lang.lang")

local M = {}

local lua_map = {
    block = categories.types.BLOCK,
    if_statement = categories.types.CONTROL_FLOW,
    while_statement = categories.types.LOOP,
    for_statement = categories.types.LOOP,
    function_declaration = categories.types.FUNCTION,
    local_function = categories.types.FUNCTION,
    assignment_statement = categories.types.DECLARATION,
    binary_expression = categories.types.EXPRESSION,
    function_call = categories.types.EXPRESSION,
    arguments = categories.types.EXPRESSION,
    field_expression = categories.types.MEMBER_ACCESS,
    table_constructor = categories.types.EXPRESSION,
}

function M.is_applicable(bufnr)
    return vim.bo[bufnr].filetype == "lua"
end

--- @return ContextSnapshot?
function M.get_context_snapshot()
    local curr_node = vim.treesitter.get_node()
    local func_node_start, func_node_end = ts.get_current_function_pos(curr_node, "function")
    if not curr_node or not func_node_start or not func_node_end then
        return nil
    end
    local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
    local scope = ts.get_current_scope(curr_node)
    --- @type ContextSnapshot
    return {
        node_type = curr_node:type(),
        category = lang.get_category(curr_node:type(), lua_map),
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
