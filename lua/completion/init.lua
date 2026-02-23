local state = require("completion.state_manager")
local server = require("completion.server")
local config = require("completion.config")

local M = {}

function M.setup(user_config)
    config.setup(user_config or {})
    require("completion.http")
    require("completion.agent_response.render")
    require("completion.agent_response.display_response")
    local opts = config.get()
    server.start(opts)
    state.enable()
end

vim.api.nvim_create_user_command("CompletionEnable", function()
    state.enable()
    server.start(config.get())
    vim.notify("Completion enabled")
end, {})

vim.api.nvim_create_user_command("CompletionDisable", function()
    state.disable()
    state.clear_agent_response_state()
    vim.notify("Completion disabled")
end, {})

return M
