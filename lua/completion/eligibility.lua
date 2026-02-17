local categories = require("completion.categories")
local M = {}

local function error_node_present(context)
    return context.error_node_present
end

local function inside_current_node(context)
    return context.curr_row > context.node:start()
        and context.curr_row < context.node:end_()
end

function M.is_eligible(context)
    if not context or not context.scope_set_category then
        return false
    end

    local category = context.category
    if category == categories.types.COMMENT or category == categories.types.STRING then
        return false
    end
    if context.is_trigger then
        return true
    end
    -- Block-like structures (if, loops, block, class, etc.)
    if categories.sets.BLOCK_LIKE[category] then
        return not error_node_present(context)
            and inside_current_node(context)
            and context.row_empty
    end


    return false
end

return M
