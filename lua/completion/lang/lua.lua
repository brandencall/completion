local categories = require("completion.categories")
local lang = require("completion.lang.lang")

local M = {}

---@type table<string, CategoryType>
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
    comment = categories.types.COMMENT,
}

function M.is_applicable(bufnr)
    return vim.bo[bufnr].filetype == "lua"
end

--- @return ContextSnapshot?
function M.get_context_snapshot()
    return lang.get_context_snapshot("lua", lua_map)
end

return M
