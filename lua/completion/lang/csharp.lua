local M = {}

function M.is_applicable(bufnr)
    return vim.bo[bufnr].filetype == "cs"
end

---@param context ContextSnapshot
function M.is_eligible(context)
end

function M.get_context_snapshot()
end

return M
