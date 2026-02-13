--- @class ContextSnapshot
--- @field node_type string
--- @field node_start integer
--- @field node_end integer
--- @field scope string
--- @field curr_row integer
--- @field err_node_present boolean
--- @field func_node_start integer?
--- @field func_node_end integer?
--- @field curr_line_text string
--- @field context_start integer? 
--- @field constext_end integer?


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

return lang
