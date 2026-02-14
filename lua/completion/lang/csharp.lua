local categories = require("completion.categories")
local lang = require("completion.lang.lang")

local M = {}

---@type table<string, CategoryType>
local csharp_map = {
    block = categories.types.BLOCK,
    if_statement = categories.types.CONTROL_FLOW,
    while_statement = categories.types.LOOP,
    for_statement = categories.types.LOOP,
    foreach_statement = categories.types.LOOP,
    class_declaration = categories.types.CLASS,
    method_declaration = categories.types.FUNCTION,
    constructor_declaration = categories.types.FUNCTION,
    property_declaration = categories.types.DECLARATION,
    identifier = categories.types.DECLARATION,
    binary_expression = categories.types.EXPRESSION,
    invocation_expression = categories.types.EXPRESSION,
    argument_list = categories.types.EXPRESSION,
    member_access_expression = categories.types.MEMBER_ACCESS,
    compilation_unit = categories.types.TOPLEVEL,
    interface_declaration = categories.types.INTERFACE,
    struct_declaration = categories.types.STRUCT,
}

-- I feel like there has to be a better way of doing this so that you don't have to define this for ALL languages
-- All of the languages should have the "same" full_scoped_nodes. For example, they should all be passing the func_node
-- as a "full scope" node. 
---@type NodeConfig
local node_config = {
    full_scoped_nodes = {
        func_node = "method_declaration",
        interface_node = "interface_declaration",
        struct_node = "struct_declaration",
    },
    file_node = "compilation_unit"
}

function M.is_applicable(bufnr)
    return vim.bo[bufnr].filetype == "cs"
end

--- @return ContextSnapshot?
function M.get_context_snapshot()
    return lang.get_context_snapshot("c_sharp", csharp_map, node_config)
end

return M
