local prompt_builder = require("completion.prompt_builder")
local lang_manager = require("completion.lang.lang_manager")
local eligibile = require("completion.eligibility")

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

M.BufferState = {
    buf = nil,
    anchor_mark_id = nil,
    text = "",
    insert_plan = {},
    ns = vim.api.nvim_create_namespace("agent_response")
}

function M.clear_agent_response_state()
    if not M.BufferState.buf then return end
    vim.api.nvim_buf_clear_namespace(M.BufferState.buf, M.BufferState.ns, 0, -1)
    M.BufferState.anchor_mark_id = nil
    M.BufferState.text = ""
    M.BufferState.insert_plan = nil
end

local pending = {
    lang = nil,
    is_trigger = false,
}

local current_state = M.States.DISABLED

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

local function on_timer()
    local lang = pending.lang
    if not lang then
        return
    end
    local context = lang.get_context_snapshot(pending.is_trigger)
    if not context then return end

    if eligibile.is_eligible(context)
        and M.get_state() ~= M.States.SUSPENDED
    then
        local prompt_request = prompt_builder.prompt_request(context.context_start, context.context_end)
        vim.api.nvim_exec_autocmds("User", {
            pattern = "AgentRequest",
            data = { request = prompt_request },
        })
    end
end

local function restart_eligible_timer(delay, lang, is_trigger)
    pending.lang = lang
    pending.is_trigger = is_trigger

    if not eligible_timer then
        return
    end

    eligible_timer:stop()
    eligible_timer:start(delay, 0, vim.schedule_wrap(on_timer))
end

---@param col integer
---@return string | nil
local function get_last_char(col)
    local line = vim.api.nvim_get_current_line()

    if col == 0 then
        return nil
    end

    local before = line:sub(1, col + 1)
    return before:match(".*(%S)%s*$")
end

---@param col integer
---@return string | nil
local function get_last_token(col)
    local current_line = vim.api.nvim_get_current_line()

    local line = current_line:sub(1, col + 1)
    return line:match("(%w+)$")
end

local function suspend()
    if not suspend_timer then
        return
    end
    set_state(M.States.SUSPENDED)
    suspend_timer:start(4000, 0, vim.schedule_wrap(function()
        set_state(M.States.IDLE)
    end))
end


local function user_typing()
    if M.get_state() == M.States.DISABLED or M.get_state() == M.States.SUSPENDED then
        return
    end
    if vim.api.nvim_get_option_value('buftype', { buf = 0 }) ~= "" then return end
    vim.api.nvim_exec_autocmds("User", { pattern = "UserTyping" })

    if M.get_state() == M.States.DISPLAYING then
        suspend()
        return
    end

    set_state(M.States.TYPING)
    local lang = lang_manager.get_active_lang(0)
    if not lang then return end

    local _, col = unpack(vim.api.nvim_win_get_cursor(0))
    local char = get_last_char(col)
    local is_trigger = false
    local trigger_chars = lang.config.trigger_characters or {}
    local trigger_keywords = lang.config.trigger_keywords or {}

    if trigger_chars[char] then
        is_trigger = true
    end

    if not is_trigger then
        local word = get_last_token(col)
        if trigger_keywords[word] then
            is_trigger = true
        end
    end
    local delay = is_trigger and 200 or 400

    restart_eligible_timer(delay, lang, is_trigger)
end

vim.api.nvim_create_autocmd("User", {
    pattern = "AgentResponse",
    callback = function()
        set_state(M.States.DISPLAYING)
    end,
})

vim.api.nvim_create_autocmd("User", {
    pattern = "UserAcceptPrompt",
    callback = function()
        set_state(M.States.IDLE)
    end
})

vim.api.nvim_create_autocmd("TextChangedI", {
    group = state_group,
    callback = function()
        user_typing()
        vim.api.nvim_exec_autocmds("User", {
            pattern = "StopProcessingAgentResponse",
        })
    end,
    desc = "Trigger callback when text changes in insert mode"
})

return M
