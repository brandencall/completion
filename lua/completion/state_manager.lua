local prompt_builder = require("completion.prompt_builder")
local lang_manager = require("completion.lang.lang_manager")

local M = {}

local state_group = vim.api.nvim_create_augroup("CompletionStateGroup", { clear = true })
local uv = vim.uv

---@alias State
---| 0  -- DISABLED
---| 1  -- ENABLED
---| 2  -- IDLE
---| 3  -- TYPING
---| 4  -- ELIGIBLE
---| 5  -- SUSPENDED
---| 6  -- DISPLAYING
M.States = {
    DISABLED = 0,
    ENABLED = 1,
    IDLE = 2,
    TYPING = 3,
    ELIGIBLE = 4,
    SUSPENDED = 5,
    DISPLAYING = 6
}

local current_state = M.States.DISABLED
---@diagnostic disable: undefined-field
local eligible_timer = uv.new_timer()
local suspend_timer = uv.new_timer()

---@param new_state State
local function set_state(new_state)
    if M.get_state() == M.States.DISABLED and new_state ~= M.States.ENABLED then
        return
    end
    if current_state == new_state then
        return
    end
    current_state = new_state
end

--- Updates the State to IDLE if we switch to anything but insert mode
local function on_mode_change()
    ---@type table<string, any>
    local event = vim.v.event
    local mode = event.new_mode
    if not mode:match("[iI]") then
        set_state(M.States.IDLE)
        vim.api.nvim_exec_autocmds("User", {
            pattern = "IdleState",
        })
    end
end

vim.api.nvim_create_autocmd("ModeChanged", {
    callback = on_mode_change,
    desc = "Callback function when mode changes"
})

function M.enable()
    set_state(M.States.ENABLED)
end

function M.disable()
    vim.api.nvim_exec_autocmds("User", {
        pattern = "PluginDisabled"
    })
    set_state(M.States.DISABLED)
end

function M.get_state()
    return current_state
end

local function suspend(suspend_time)
    set_state(M.States.SUSPENDED)
    suspend_timer:start(suspend_time, 0, function()
        set_state(M.States.IDLE)
    end)
end

local function user_typing()
    vim.api.nvim_exec_autocmds("User", {
        pattern = "UserTyping"
    })
    local buftype = vim.api.nvim_get_option_value('buftype', { buf = 0 })
    if buftype ~= "" then
        return
    end
    if M.get_state() == M.States.DISPLAYING then
        suspend(4000)
    end
    local lang = lang_manager.get_active_lang(vim.api.nvim_get_current_buf())
    if not lang then
        return
    end
    local context = lang.get_context_snapshot()
    if context == nil then
        return
    end
    eligible_timer:start(1000, 0, vim.schedule_wrap(function()
        if lang.is_eligible(context) and M.get_state() ~= M.States.SUSPENDED then
            local prompt_request = prompt_builder.prompt_request(context.func_node_start, context.func_node_end)
            vim.api.nvim_exec_autocmds("User", {
                pattern = "AgentRequest",
                data = { request = prompt_request },
            })
        end
    end))
end

vim.api.nvim_create_autocmd("User", {
    pattern = "PromptFinished",
    callback = function()
        set_state(M.States.DISPLAYING)
    end
})

vim.api.nvim_create_autocmd("TextChangedI", {
    group = state_group,
    callback = function()
        user_typing()
    end,
    desc = "Trigger callback when text changes in insert mode"
})

local cmp = require("cmp")

-- Event called when lsp autocomplete finishes
cmp.event:on("confirm_done", function()
    user_typing()
end)

return M
