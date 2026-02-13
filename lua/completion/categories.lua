local M = {}


---@alias CategoryType
---| "control_flow"
---| "loop"
---| "function"
---| "class"
---| "scope_body"
---| "assignment"
---| "declaration"
---| "expression"
---| "call"
---| "argument_list"
---| "block"
---| "comment"
---| "top_level"
---| "member_access"

M.types = {
    CONTROL_FLOW = "control_flow",
    LOOP = "loop",
    FUNCTION = "function",
    CLASS = "class",
    SCOPE_BODY = "scope_body",
    ASSIGNMENT = "assignment",
    DECLARATION = "declaration",
    EXPRESSION = "expression",
    CALL = "call",
    ARGUMENT_LIST = "argument_list",
    BLOCK = "block",
    COMMENT = "comment",
    TOP_LEVEL = "top_level",
    MEMBER_ACCESS = "member_access"
}

-- Optional grouped sets (helps eligibility logic stay clean)
M.groups = {
    BLOCK_LIKE = {
        M.types.CONTROL_FLOW,
        M.types.LOOP,
        M.types.FUNCTION,
        M.types.CLASS,
        M.types.BLOCK,
        M.types.SCOPE_BODY,
    },

    EXECUTABLE = {
        M.types.ASSIGNMENT,
        M.types.EXPRESSION,
        M.types.CALL,
        M.types.DECLARATION,
        M.types.MEMBER_ACCESS
    }
}
local function to_set(list)
    local set = {}
    for _, v in ipairs(list) do
        set[v] = true
    end
    return set
end

-- Precompute sets for fast lookup
M.sets = {
    BLOCK_LIKE = to_set(M.groups.BLOCK_LIKE),
    EXECUTABLE = to_set(M.groups.EXECUTABLE),
}

return M
