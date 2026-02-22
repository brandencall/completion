local categories = require("completion.categories")
local lang = require("completion.lang.lang")

local M = {}

---@type table<string, CategoryType>
local c_map = {
    compound_statement  = categories.types.BLOCK,
    if_statement        = categories.types.CONTROL_FLOW,
    switch_statement    = categories.types.CONTROL_FLOW,
    case_statement      = categories.types.CONTROL_FLOW,
    while_statement     = categories.types.LOOP,
    for_statement       = categories.types.LOOP,
    do_statement        = categories.types.LOOP,
    struct_specifier    = categories.types.STRUCT,
    enum_specifier      = categories.types.ENUM,
    union_specifier     = categories.types.STRUCT,
    translation_unit    = categories.types.TOP_LEVEL,
    function_definition = categories.types.FUNCTION,
    comment             = categories.types.COMMENT,
    string_literal      = categories.types.STRING,
}

---@type table<string, boolean>
local trigger_characters = {
    ["."] = true,
    ["("] = true,
    ["["] = true,
    ["]"] = true,
    [","] = true,
    ["="] = true,
    ["-"] = true,
    ["*"] = true,
    ["&"] = true,
    ["{"] = true,
}

---@type table<string, boolean>
local trigger_keywords = {
    ["if"] = true,
    ["for"] = true,
    ["while"] = true,
    ["switch"] = true,
    ["case"] = true,
    ["return"] = true,
    ["typedef"] = true,
    ["struct"] = true,
    ["enum"] = true,
    ["union"] = true,
    ["sizeof"] = true,
}

---@type LangConfig
M.config = {
    parser_name = "c",
    node_map = c_map,
    trigger_characters = trigger_characters,
    trigger_keywords = trigger_keywords
}

function M.is_applicable(bufnr)
    return vim.bo[bufnr].filetype == "c"
end

--- @param is_trigger boolean Collecting context based on if it is a trigger or not
--- @return ContextSnapshot?
function M.get_context_snapshot(is_trigger)
    return lang.get_context_snapshot(M.config, is_trigger)
end

return M
