local M = {}

---@alias CategoryType
---| "control_flow"
---| "loop"
---| "func"
---| "class"
---| "interface"
---| "struct"
---| "enum"
---| "scope_body"
---| "block"
---| "comment"
---| "top_level"
---| "string"

M.types = {
    CONTROL_FLOW = "control_flow",
    LOOP = "loop",
    FUNCTION = "func",
    CLASS = "class",
    INTERFACE = "interface",
    STRUCT = "struct",
    ENUM = "enum",
    SCOPE_BODY = "scope_body",
    BLOCK = "block",
    COMMENT = "comment",
    TOP_LEVEL = "top_level",
    STRING = "string"
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

    --EXECUTABLE = {
    --    M.types.ASSIGNMENT,
    --    M.types.EXPRESSION,
    --    M.types.CALL,
    --    M.types.DECLARATION,
    --    M.types.MEMBER_ACCESS
    --}
}

M.scope_rules = {
    FULL = {
        M.types.FUNCTION,
        M.types.INTERFACE,
        M.types.STRUCT,
        M.types.ENUM
    },

    PARTIAL = {
        M.types.CLASS,
        M.types.TOP_LEVEL,
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
    --EXECUTABLE = to_set(M.groups.EXECUTABLE),
}

M.scope_sets = {
    FULL = to_set(M.scope_rules.FULL),
    PARTIAL = to_set(M.scope_rules.PARTIAL),
}

return M
