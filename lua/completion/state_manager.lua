local M = {}

local state_group = vim.api.nvim_create_augroup("CompletionStateGroup", { clear = true })
local uv = vim.uv

---@alias State
---| 0  -- IDLE
---| 1  -- TYPING
---| 2  -- ELIGIBLE
---| 3  -- REQUESTING
---| 4  -- DISPLAYING
---| 5  -- SUSPENDING
M.States = {
    IDLE = 0,
    TYPING = 1,
    ELIGIBLE = 2,
    REQUESTING = 3,
    DISPLAYING = 4,
    SUSPENDING = 5
}

local current_state = M.States.IDLE
---@diagnostic disable: undefined-field
local eligible_timer = uv.new_timer()

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
        set_state(M.States.TYPING)
    else
        set_state(M.States.IDLE)
    end
end

function M.get_state()
    return current_state
end

local function user_typing()
    set_state(M.States.TYPING)
    eligible_timer:start(1000, 0, vim.schedule_wrap(function()
        local buftype = vim.api.nvim_get_option_value('buftype', { buf = 0 })
        if M.get_state() == M.States.TYPING and buftype == "" then
            set_state(M.States.ELIGIBLE)
        end
    end))
end

vim.api.nvim_create_autocmd("TextChangedI", {
    group = state_group,
    callback = function()
        user_typing()
    end,
    desc = "Trigger callback when text changes in insert mode"
})

return M
