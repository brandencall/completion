local context_bulder = require("completion.context_builder")
local renderer = require("completion.renderer")

local M = {}

local state_group = vim.api.nvim_create_augroup("CompletionStateGroup", { clear = true })
local uv = vim.uv

---@alias State
---| -1  -- DISABLED
---| 0  -- ENABLED
---| 1  -- IDLE
---| 2  -- TYPING
---| 3  -- ELIGIBLE
---| 4  -- REQUESTING
---| 5  -- DISPLAYING
---| 6  -- SUSPENDING
M.States = {
    DISABLED = -1,
    ENABLED = 0,
    IDLE = 1,
    TYPING = 2,
    ELIGIBLE = 3,
    REQUESTING = 4,
    DISPLAYING = 5,
    SUSPENDING = 6
}

local current_state = M.States.DISABLED
---@diagnostic disable: undefined-field
local eligible_timer = uv.new_timer()

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
        renderer.clear_text()
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

local function is_curr_node_type_valid(cur_node_type)
    if cur_node_type == "string_literal"
        or cur_node_type == "string"
        or cur_node_type == "string_content"
        or cur_node_type == "comment"
    then
        return false
    end
    return true
end

-- The logic that decides whether or not to prompt the llm
local function validate_eligibility()
    local treesitter_model = context_bulder.get_treesitter_model()
    -- If not in a function just return
    if treesitter_model.func_start == nil or treesitter_model.func_end == nil then
        return
    end
    local cur_node_type = treesitter_model.current_node:type()
    if not is_curr_node_type_valid(cur_node_type) then
        return
    end
    local prompt_request = context_bulder.prompt_request(treesitter_model.func_start, treesitter_model.func_end)
    vim.api.nvim_exec_autocmds("User", {
        pattern = "AgentRequest",
        data = { request = prompt_request },
    })
end

local function user_typing()
    set_state(M.States.TYPING)
    renderer.clear_text()
    eligible_timer:start(1000, 0, vim.schedule_wrap(function()
        local buftype = vim.api.nvim_get_option_value('buftype', { buf = 0 })
        if M.get_state() == M.States.TYPING and buftype == "" then
            set_state(M.States.ELIGIBLE)
            validate_eligibility()
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
