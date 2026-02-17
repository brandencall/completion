local categories = require("completion.categories")
local lang = require("completion.lang.lang")

local M = {}

---@type table<string, CategoryType>
local lua_map = {
    block                = categories.types.BLOCK,
    if_statement         = categories.types.CONTROL_FLOW,
    while_statement      = categories.types.LOOP,
    for_statement        = categories.types.LOOP,
    function_declaration = categories.types.FUNCTION,
    local_function       = categories.types.FUNCTION,
    chunk                = categories.types.TOP_LEVEL,
    comment              = categories.types.COMMENT,
    string               = categories.types.STRING
}

---@type table<string, boolean>
local trigger_characters = {
    ["."] = true,
    [":"] = true,
    ["("] = true,
    ["{"] = true,
    ["["] = true,
    [","] = true,
    ["="] = true,
}

local trigger_keywords = {
    ["if"] = true,
    ["for"] = true,
    ["while"] = true,
    ["return"] = true,
}

---@type LangConfig
M.config = {
    parser_name = "lua",
    node_map = lua_map,
    trigger_characters = trigger_characters,
    trigger_keywords = trigger_keywords
}

function M.is_applicable(bufnr)
    return vim.bo[bufnr].filetype == "lua"
end

--- @param is_trigger boolean Collecting context based on if it is a trigger or not
--- @return ContextSnapshot?
function M.get_context_snapshot(is_trigger)
    return lang.get_context_snapshot(M.config, is_trigger)
end

return M
