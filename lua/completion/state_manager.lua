local M = {}

---@alias State
---| 0  -- IDLE
---| 1  -- INSERT_MODE
---| 2  -- ACTIVE_REQUEST
M.States = {
    IDLE = 0,
    INSERT_MODE = 1,
    ACTIVE_REQUEST = 2,
}

local current_state = M.States.IDLE

---comment
---@param new_state State the new state
local function set_state(new_state)
    if current_state == new_state then
        return
    end
    current_state = new_state
end

local function on_mode_change()
    ---@type table<string, any>
    local event = vim.v.event
    local mode = event.new_mode
    if mode:match("[iI]") then
        set_state(M.States.INSERT_MODE)
    else
        set_state(M.States.IDLE)
    end
end

function M.get_state()
    return current_state
end

vim.api.nvim_create_autocmd("ModeChanged", {
    callback = on_mode_change,
    desc = "Callback function when mode changes"
})

return M
