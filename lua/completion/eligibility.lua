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
    if not context or not context.category then
        return false
    end

    local category = context.category
    -- Block-like structures (if, loops, block, class, etc.)
    if categories.sets.BLOCK_LIKE[category] then
        return not error_node_present(context)
            and inside_current_node(context)
    end

    -- Inline executable contexts
    if categories.sets.EXECUTABLE[category]
        or category == categories.types.MEMBER_ACCESS
    then
        return true
    end

    if categories.types.COMMENT then
        return false
    end

    -- Functions (Lua required error check)
    if category == categories.types.FUNCTION then
        return not error_node_present(context)
    end

    return false
end

return M
