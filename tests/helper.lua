local M = {}

function M.mock_mode_insert()
    local original = vim.fn.mode
    rawset(vim.fn, "mode", function() return "i" end)
    return function()
        rawset(vim.fn, "mode", original)
    end
end

function M.mock_schedule_sync()
    local original = vim.schedule
    rawset(vim, "schedule", function(fn) fn() end)
    return function()
        rawset(vim, "schedule", original)
    end
end

return M
