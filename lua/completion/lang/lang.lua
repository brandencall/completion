local ts = require("completion.lang.ts_util")
--- @class ContextSnapshot
--- @field node_type string
--- @field node_start integer
--- @field node_end integer
--- @field scope string
--- @field curr_row integer
--- @field err_node_present boolean
--- @field curr_line_text string
--- @field context_start integer
--- @field context_end integer


local lang = {}

lang.required_methods = {
    "is_applicable",
    "get_context_snapshot"
}

function lang.get_category(node_type, node_map)
    return node_map[node_type]
end

function lang.validate(l, name)
    for _, method in ipairs(lang.required_methods) do
        if not l[method] then
            error("Language '" .. name .. "' is missing required method: " .. method)
        end
    end
end

---@alias GetContextRange fun(row: integer, curr_node: TSNode): integer, integer

---@param ts_lang string The language that treesitter defines for it
---@param get_context_range GetContextRange
---@param node_map table<string, CategoryType>
---@return _ ContextSnapshot
function lang.get_context_snapshot(ts_lang, get_context_range, node_map)
    local curr_node = ts.get_node_at_cursor(0, ts_lang)
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
        category = lang.get_category(curr_node:type(), node_map),
        node_start = curr_node:start(),
        node_end = curr_node:end_(),
        scope = not scope and "" or scope:type(),
        curr_row = row - 1,
        err_node_present = ts.contains_err_node(scope),
        curr_line_text = vim.api.nvim_get_current_line(),
        ---@diagnostic disable-next-line: assign-type-mismatch
        context_start = context_start,
        ---@diagnostic disable-next-line: assign-type-mismatch
        context_end = context_end,
    }
end

return lang
