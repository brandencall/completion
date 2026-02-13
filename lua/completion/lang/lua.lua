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
    chunk = categories.types.TOP_LEVEL,
}

function M.is_applicable(bufnr)
    return vim.bo[bufnr].filetype == "lua"
end

local function get_context_range(row, curr_node)
    local context_start, context_end = nil, nil
    local func_node = ts.get_node(curr_node, "function_declaration")
    if not func_node then
        -- chunk includes the whole file
        local file_node = ts.get_node(curr_node, "chunk")
        if file_node then
            context_start, _, _, _ = file_node:range()
            -- stop at the current row so we don't actually load the whole file
            context_end = row
        end
    else
        context_start, _, context_end, _ = func_node:range()
    end
    return context_start, context_end
end

--- @return ContextSnapshot?
function M.get_context_snapshot()
    local curr_node = ts.get_node_at_cursor(0, "lua")
    if not curr_node then
        return nil
    end
    local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
    local context_start, context_end = get_context_range(row, curr_node)
    if not context_start and not context_end then
        return nil
    end
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
        curr_line_text = vim.api.nvim_get_current_line(),
        context_start = context_start,
        constext_end = context_end,
    }
end

return M
