local categories = require("completion.categories")
local lang = require("completion.lang.lang")

local M = {}

---@type table<string, CategoryType>
local csharp_map = {
    block                   = categories.types.BLOCK,
    if_statement            = categories.types.CONTROL_FLOW,
    while_statement         = categories.types.LOOP,
    for_statement           = categories.types.LOOP,
    foreach_statement       = categories.types.LOOP,
    class_declaration       = categories.types.CLASS,
    method_declaration      = categories.types.FUNCTION,
    constructor_declaration = categories.types.FUNCTION,
    compilation_unit        = categories.types.TOP_LEVEL,
    interface_declaration   = categories.types.INTERFACE,
    struct_declaration      = categories.types.STRUCT,
    enum_declaration        = categories.types.ENUM,
    comment                 = categories.types.COMMENT,
    string_literal          = categories.types.STRING
}

---@type table<string, boolean>
local trigger_characters = {
    ["."] = true,
    ["("] = true,
    ["<"] = true,
    ["["] = true,
    [":"] = true,
    [","] = true,
    [">"] = true,
    ["="] = true,
}

---@type table<string, boolean>
local trigger_keywords = {
    ["if"] = true,
    ["for"] = true,
    ["while"] = true,
    ["return"] = true,
    ["new"] = true,
    ["throw"] = true,
    ["case"] = true,
    ["await"] = true,
}

---@type LangConfig
M.config = {
    parser_name = "c_sharp",
    node_map = csharp_map,
    trigger_characters = trigger_characters,
    trigger_keywords = trigger_keywords
}

function M.is_applicable(bufnr)
    return vim.bo[bufnr].filetype == "cs"
end

--- @param is_trigger boolean Collecting context based on if it is a trigger or not
--- @return ContextSnapshot?
function M.get_context_snapshot(is_trigger)
    return lang.get_context_snapshot(M.config, is_trigger)
end

return M
