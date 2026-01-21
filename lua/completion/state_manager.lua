local context_bulder = require("completion.context_builder")
--local renderer = require("completion.renderer")
--local debug = require("completion.debug")

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
---| 7  -- ACCEPTED
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

---@param context ContextSnapshot
local function is_eligible(context)
    if context.node_type == "if_statement"
        or context.node_type == "while_statement"
        or context.node_type == "for_statement"
    then
        if not context.err_node_present and
            context.curr_row > context.node_start
            and context.curr_row < context.node_end
        then
            return true
        end
    elseif context.node_type == "assignment_statement" or context.node_type == "binary_expression" then
        return true
    elseif context.node_type:match("function") and not context.err_node_present then
        return true
    end
    return false
end

local function suspend(suspend_time)
    set_state(M.States.SUSPENDED)
    suspend_timer:start(suspend_time, 0, function()
        set_state(M.States.IDLE)
    end)
end

local function user_typing()
    local buftype = vim.api.nvim_get_option_value('buftype', { buf = 0 })
    if buftype ~= "" then
        return
    end
    if M.get_state() == M.States.DISPLAYING then
        suspend(4000)
    end
    vim.api.nvim_exec_autocmds("User", {
        pattern = "UserTyping"
    })
    local context = context_bulder.get_context_snapshot()
    if context == nil then
        return
    end
    eligible_timer:start(1000, 0, vim.schedule_wrap(function()
        if is_eligible(context) and M.get_state() ~= M.States.SUSPENDED then
            local prompt_request = context_bulder.prompt_request(context.func_node_start, context
                .func_node_end)
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
