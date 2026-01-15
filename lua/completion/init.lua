local RequestManager = require("completion.request_manager")
local state = require("completion.state_manager")
local context_bulder = require("completion.context_builder")

local M = {}
local client = nil

function M.start()
    --client = RequestManager:new(22222)
    --local msg = [[int sum_positive(int *arr, int len) {
    --                int total = 0;
    --                for (int i = 0; i < len; i++) {
    --                    if (arr[i] > 0) {
    --                        total +=]]
    --local prompt_request = {
    --    type = "test",
    --    prefix = msg
    --}
    --client:send_message(prompt_request)
    print(state.get_state())
end

function M.context()
    local prefix = context_bulder.text_before_cursor(10)
    local suffix = context_bulder.text_after_cursor(5)
end
function M.stop()
    if client ~= nil then
        print("here")
        client:disconnect()
    end
end

return M
