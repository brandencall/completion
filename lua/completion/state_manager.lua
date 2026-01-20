local context_bulder = require("completion.context_builder")
local renderer = require("completion.renderer")

local M = {}

local function debug(text)
    local file = assert(io.open("test.txt", "a"))
    file:write(text)
    file:close()
end

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

---@type ContextSnapshot?
local current_snapshot = nil
---@type ContextSnapshot?
local last_snapshot = nil


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

---@param context ContextSnapshot
---@return boolean
local function is_curr_node_valid(context)
    if context.node_type == "string_literal"
        or context.node_type == "string"
        or context.node_type == "string_content"
        or context.node_type == "comment"
    then
        return false
    end
    return true
end

---@param context ContextSnapshot
local function determine_if_eligible(context)
    if context.node_type == "if_statement"
        or context.node_type == "while_statement"
        or context.node_type == "for_statement"
    then
        if context.curr_row > context.node_start and context.curr_row < context.node_end then
            set_state(M.States.ELIGIBLE)
        end
    end
end

local function DebugTreesitterAtCursor()
    local buftype = vim.api.nvim_get_option_value('buftype', { buf = 0 })
    if buftype ~= "" then
        return
    end
    local api = vim.api
    local ts = vim.treesitter

    local buf = api.nvim_get_current_buf()
    local row, col = unpack(api.nvim_win_get_cursor(0))
    row = row - 1

    local byte = api.nvim_buf_get_offset(buf, row) + col

    local named_node = ts.get_node()
    if not named_node then
        debug("No named node at cursor")
        return
    end

    ---@type TSNode?
    local raw_node = named_node
    while raw_node and raw_node:type() == named_node:type() do
        raw_node = raw_node:parent()
    end

    debug("\n=== CURSOR ===\n")
    debug("Current line: " .. vim.api.nvim_get_current_line() .. "\n")
    debug("Row: " .. row + 1 .. " , Col:" .. col .. "\n")
    debug("Byte offset: " .. byte)

    debug("\n=== NODE UNDER CURSOR ===\n")
    debug("Named node: " .. named_node:type() .. "\n")
    debug("Range: " .. named_node:start() .. ", " .. named_node:end_())

    debug("\n=== PARENT CHAIN ===\n")
    ---@type TSNode?
    local cur = named_node
    while cur do
        debug("-" .. cur:type())
        if cur:type():match("function")
            or cur:type():match("method")
            or cur:type() == "block" then
            break
        end
        cur = cur:parent()
    end

    debug("\n=== CHILDREN OF NEAREST SCOPE ===\n")
    -- Add method check along with function
    ---@type TSNode?
    local scope = named_node
    while scope and scope:type() ~= "block"
        and not scope:type():match("function") do
        scope = scope:parent()
    end

    if scope then
        debug("Scope: " .. scope:type() .. "\n")
        for i = 0, scope:child_count() - 1 do
            local child = scope:child(i)
            if child ~= nil then
                debug(string.format(
                    "   [%d] %s (%d → %d)\n",
                    i,
                    child:type(),
                    child:start(),
                    child:end_()
                ))
            end
        end
    end

    debug("\n=== ERROR NODES IN SCOPE ===\n")
    local function scan(n)
        if n:type() == "ERROR" then
            debug("ERROR:" .. n:start() .. "→" .. n:end_())
        elseif n:type() == "MISSING" then
            debug("MISSING:" .. n:start() .. "→" .. n:end_())
        end
        for i = 0, n:child_count() - 1 do
            scan(n:child(i))
        end
    end

    if scope then
        scan(scope)
    end

    debug("\n=== DONE ===\n\n")
end

local function user_typing()
    local buftype = vim.api.nvim_get_option_value('buftype', { buf = 0 })
    if buftype ~= "" then
        return
    end
    set_state(M.States.TYPING)
    renderer.clear_text()
    local context_test = context_bulder.get_context_snapshot()
    if context_test == nil then
        return
    end
    determine_if_eligible(context_test)
    eligible_timer:start(1000, 0, vim.schedule_wrap(function()
        if M.get_state() == M.States.ELIGIBLE then
            debug("Prompting...\n")
            local prompt_request = context_bulder.prompt_request(context_test.func_node_start, context_test
            .func_node_end)
            vim.api.nvim_exec_autocmds("User", {
                pattern = "AgentRequest",
                data = { request = prompt_request },
            })
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

local cmp = require("cmp")

-- Event called when lsp autocomplete finishes
cmp.event:on("confirm_done", function()
    user_typing()
end)

return M
