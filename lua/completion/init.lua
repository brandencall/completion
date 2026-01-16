local RequestManager = require("completion.request_manager")
local state = require("completion.state_manager")
local context_bulder = require("completion.context_builder")
local renderer = require("completion.renderer")

local M = {}
local client = nil

function M.start()
    client = RequestManager:new(22222)
    vim.api.nvim_create_autocmd("User", {
        pattern = "AgentResponse",
        callback = function(event)
            local response = event.data.response
            renderer.show_agent_response(response)
        end,
    })
end

function M.send()
    local prompt_request = context_bulder.prompt_request(10, 2)
    if client ~= nil then
        client:send_message_json(prompt_request)
    end
end

function M.clear()
    renderer.clear_text()
end

function M.stop()
    if client ~= nil then
        client:disconnect()
    end
end

return M
