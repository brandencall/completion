local categories = require("completion.categories")
local lang = require("completion.lang.lang")

local M = {}

---@type table<string, CategoryType>
local csharp_map = {
    block                    = categories.types.BLOCK,
    if_statement             = categories.types.CONTROL_FLOW,
    while_statement          = categories.types.LOOP,
    for_statement            = categories.types.LOOP,
    foreach_statement        = categories.types.LOOP,
    class_declaration        = categories.types.CLASS,
    method_declaration       = categories.types.FUNCTION,
    constructor_declaration  = categories.types.FUNCTION,
    property_declaration     = categories.types.DECLARATION,
    identifier               = categories.types.DECLARATION,
    binary_expression        = categories.types.EXPRESSION,
    invocation_expression    = categories.types.EXPRESSION,
    argument_list            = categories.types.EXPRESSION,
    member_access_expression = categories.types.MEMBER_ACCESS,
    compilation_unit         = categories.types.TOP_LEVEL,
    interface_declaration    = categories.types.INTERFACE,
    struct_declaration       = categories.types.STRUCT,
    enum_declaration         = categories.types.ENUM,
    comment                  = categories.types.COMMENT
}

function M.is_applicable(bufnr)
    return vim.bo[bufnr].filetype == "cs"
end

--- @return ContextSnapshot?
function M.get_context_snapshot()
    return lang.get_context_snapshot("c_sharp", csharp_map)
end

return M
