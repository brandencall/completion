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
    vim.api.nvim_create_autocmd("User", {
        pattern = "AgentRequest",
        callback = function(event)
            local prompt_request = event.data.request
            if client ~= nil then
                client:send_message_json(prompt_request)
            end
        end,
    })
end

function M.print_tree()
    local model = context_bulder.get_treesitter_model()
    print("Current node type: " .. model.current_node:type())
end

function M.send()
    local start_row, end_row = context_bulder.get_current_function_pos()
    if start_row == nil or end_row == nil then
        local cursor_pos = vim.api.nvim_win_get_cursor(0)
        start_row = cursor_pos[1] - 40
        end_row = 20
    end
    local prompt_request = context_bulder.prompt_request(start_row, end_row)
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
