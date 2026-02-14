local ts = require("completion.lang.ts_util")
--- @class ContextSnapshot
--- @field node TSNode
--- @field node_type string
--- @field node_start integer
--- @field node_end integer
--- @field scope string
--- @field curr_row integer
--- @field err_node_present boolean
--- @field curr_line_text string
--- @field context_start integer
--- @field context_end integer

---@class ScopedNodes
---@field func_node string
---@field interface_node? string
---
---@class NodeConfig
---@field full_scope_catagories ScopedNodes
---@field file_node string

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

---@param row integer
---@param curr_node TSNode
---@param node_config NodeConfig
---@return integer | nil context_start
---@return integer | nil context_end
local function get_context_range(row, curr_node, node_config)
    local context_start, context_end = nil, nil
    local scoped_node = ts.try_get_scope_node(curr_node, node_config.full_scoped_nodes)
    if not scoped_node then
        local file_node = ts.get_node(curr_node, node_config.file_node)
        if file_node then
            context_start, _, _, _ = file_node:range()
            -- stop at the current row so we don't actually load the whole file
            context_end = row
        end
    else
        context_start, _, context_end, _ = scoped_node:range()
    end
    return context_start, context_end
end

---@alias GetContextRange fun(row: integer, curr_node: TSNode): integer, integer

---@param ts_lang string The language that treesitter defines for it
---@param node_map table<string, CategoryType>
---@param node_config NodeConfig
---@return _ ContextSnapshot
function lang.get_context_snapshot(ts_lang, node_map, node_config)
    local curr_node = ts.get_node_at_cursor(0, ts_lang)
    if not curr_node then
        return nil
    end
    local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
    local context_start, context_end = get_context_range(row, curr_node, node_config)
    if not context_start and not context_end then
        return nil
    end
    local scope = ts.get_current_scope(curr_node)
    --- @type ContextSnapshot
    return {
        node = curr_node,
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
