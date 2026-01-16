local RequestManager = require("completion.request_manager")
local state = require("completion.state_manager")
local context_bulder = require("completion.context_builder")

local M = {}
local client = nil

function M.start()
    client = RequestManager:new(22222)
    vim.api.nvim_create_autocmd("User", {
        pattern = "AgentResponse",
        callback = function(event)
            local response = event.data.response
            print("response: " .. response)
        end,
    })
end

function M.send()
    --local msg = [[int sum_positive(int *arr, int len) {
    --                int total = 0;
    --                for (int i = 0; i < len; i++) {
    --                    if (arr[i] > 0) {
    --                        total +=]]
    --local msg = context_bulder.text_before_cursor(10)
    --local prompt_request = {
    --    type = "prompt",
    --    prefix = msg
    --}
    local prompt_request = context_bulder.prompt_request(10, 2)
    if client ~= nil then
        client:send_message_json(prompt_request)
        --client:send_message_string(msg)
    end
end

function M.context()
    local prefix = context_bulder.text_before_cursor(10)
    local suffix = context_bulder.text_after_cursor(5)
end

function M.stop()
    if client ~= nil then
        client:disconnect()
    end
end

return M
