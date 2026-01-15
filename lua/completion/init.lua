local TcpClient = require("completion.tcp_client")

local M = {}
local client = nil

function M.start()
    client = TcpClient:new(22222)
    local msg = [[int sum_positive(int *arr, int len) {
                    int total = 0;
                    for (int i = 0; i < len; i++) {
                        if (arr[i] > 0) {
                            total +=]]
    local prompt_request = {
        type = "test",
        prefix = msg
    }
    client:send_message(prompt_request)
end

function M.stop()
    if client ~= nil then
        print("here")
        client:disconnect()
    end
end

return M
