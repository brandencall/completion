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
--- @field is_trigger boolean
--- @field row_empty boolean

---@class NodeConfig
---@field full_scope_categories string[]
---@field file_scope_category string

---@class LangConfig
---@field parser_name string
---@field node_map table<string, CategoryType>
---@field trigger_characters table<string, boolean>?
---@field trigger_keywords table<string, boolean>?

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
---@return TSNode | nil
local function get_context_range(row, curr_node, node_map)
    local node = curr_node
    local start_row, end_row, category, scope_node = nil, nil, nil, nil
    while node do
        local cur_category = node_map[node:type()]
        if cur_category then
            if categories.scope_sets.FULL[cur_category] and cur_category == "func" then
                start_row, _, end_row, _ = node:range()
                category = cur_category
                scope_node = node
            elseif categories.scope_sets.FULL[cur_category] then
                start_row, _, end_row, _ = node:range()
                category = cur_category
                scope_node = node
                return start_row, end_row, category, scope_node
            end
            if categories.scope_sets.PARTIAL[cur_category] and not start_row and not end_row then
                start_row, _, _, _ = node:range()
                category = cur_category
                scope_node = node
                return start_row, row, category, scope_node
            end
        end

        node = node:parent()
    end
    return start_row, end_row, category, scope_node
end

local function is_row_empty(current_line)
    if not current_line then
        return true
    end
    return current_line:match("^%s*$") ~= nil
end

---@param config LangConfig
---@return _ ContextSnapshot
function lang.get_context_snapshot(config, is_trigger)
    local curr_node = ts.get_node_at_cursor(0, config.parser_name)
    if not curr_node then
        return nil
    end
    local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
    local current_line = vim.api.nvim_get_current_line()

    local context_start, context_end, scope_set_category, scope_node = get_context_range(row, curr_node, config.node_map)
    if not context_start and not context_end and not scope_set_category then
        return nil
    end
    --- @type ContextSnapshot
    return {
        node = curr_node,
        category = config.node_map[curr_node:type()],
        ---@diagnostic disable-next-line: assign-type-mismatch
        scope_set_category = scope_set_category,
        curr_row = row - 1,
        err_node_present = ts.contains_err_node(scope_node),
        ---@diagnostic disable-next-line: assign-type-mismatch
        context_start = context_start,
        ---@diagnostic disable-next-line: assign-type-mismatch
        context_end = context_end,
        is_trigger = is_trigger,
        row_empty = is_row_empty(current_line)
    }
end

return lang
