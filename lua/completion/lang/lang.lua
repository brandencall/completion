local ts = require("completion.lang.ts_util")
local categories = require("completion.categories")

--- @class ContextSnapshot
--- @field node TSNode
--- @field category CategoryType
--- @field scope_set_category CategoryType
--- @field curr_row integer
--- @field err_node_present boolean
--- @field context_start integer
--- @field context_end integer

---@class NodeConfig
---@field full_scope_categories string[]
---@field file_scope_category string


local lang = {}

lang.required_methods = {
    "is_applicable",
    "get_context_snapshot"
}

function lang.validate(l, name)
    for _, method in ipairs(lang.required_methods) do
        if not l[method] then
            error("Language '" .. name .. "' is missing required method: " .. method)
        end
    end
end

---@param row integer
---@param curr_node TSNode?
---@param node_map table<string, CategoryType>
---@return integer | nil
---@return integer | nil
---@return CategoryType | nil
local function get_context_range(row, curr_node, node_map)
    local node = curr_node
    while node do
        local category = node_map[node:type()]
        if category then
            if categories.scope_sets.FULL[category] then
                local start_row, _, end_row, _ = node:range()
                return start_row, end_row, category
            end
            if categories.scope_sets.PARTIAL[category] then
                local start_row, _, _, _ = node:range()
                return start_row, row, category
            end
        end

        node = node:parent()
    end

    return nil, nil, nil
end

---@param ts_lang string The language that treesitter defines for it
---@param node_map table<string, CategoryType>
---@return _ ContextSnapshot
function lang.get_context_snapshot(ts_lang, node_map)
    local curr_node = ts.get_node_at_cursor(0, ts_lang)
    if not curr_node then
        return nil
    end
    local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
    local context_start, context_end, scope_set_category = get_context_range(row, curr_node, node_map)
    if not context_start and not context_end and not scope_set_category then
        return nil
    end
    local scope = ts.get_current_scope(curr_node)
    --- @type ContextSnapshot
    return {
        node = curr_node,
        category = node_map[curr_node:type()],
        ---@diagnostic disable-next-line: assign-type-mismatch
        scope_set_category = scope_set_category,
        curr_row = row - 1,
        err_node_present = ts.contains_err_node(scope),
        ---@diagnostic disable-next-line: assign-type-mismatch
        context_start = context_start,
        ---@diagnostic disable-next-line: assign-type-mismatch
        context_end = context_end,
    }
end

return lang
