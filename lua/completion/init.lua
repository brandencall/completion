local state = require("completion.state_manager")
local context_bulder = require("completion.context_builder")
local renderer = require("completion.renderer")
local http = require("completion.http")

local M = {}

function M.start()
    state.enable()
end

function M.stop()
    state.disable()
end

vim.api.nvim_create_autocmd("User", {
    pattern = "AgentRequest",
    callback = function(event)
        local prompt_request = event.data.request
        http.handle_completion(prompt_request)
    end,
})
vim.api.nvim_create_autocmd("User", {
    pattern = "AgentResponse",
    callback = function(event)
        local response = event.data.response
        renderer.show_agent_response(response)
    end,
})
vim.api.nvim_create_autocmd("User", {
    pattern = "PluginDisabled",
    callback = function()
        renderer.clear_text()
    end,
})

function M.print_tree()
    local model = context_bulder.get_treesitter_model()
    local parent = model.current_node:parent()
    print("Current node type: " .. model.current_node:type())
    if parent ~= nil then
        print("Parent node type: " .. parent:type())
    end
end

return M
