local Job = require("plenary.job")
local json = vim.json

local M = {}

local function debug(text)
    local file = assert(io.open("test.txt", "a"))
    file:write(text)
    file:close()
end

local function stream_llm_post(url, body_table, on_chunk_callback, on_complete_callback)
    local body_json = json.encode(body_table)

    local job = Job:new({
        command = "curl",
        args = {
            "-X", "POST",
            "-H", "Content-Type: application/json",
            "--data", body_json,
            "-N", -- No buffering: enables streaming
            url
        },
        on_stdout = function(err, data)
            if err then
                print("There was an err: " .. err .. "\n")
                return
            end
            if data then
                local ok, parsed = pcall(json.decode, string.sub(data, 7))
                if ok and parsed.content then
                    on_chunk_callback(parsed.content)
                end
            end
        end,
        on_exit = function(j, return_code)
            if return_code == 0 and type(on_complete_callback) == "function" then
                on_complete_callback()
            elseif return_code ~= 0 then
                print(j:stderr_result())
            end
        end,
    })
    job:start()
end

--- This function is responible for sending prompt requests to agent server.
--- TODO: Should add request configs to a config doc
--- @param prompt_request PromptRequest
function M.handle_completion(prompt_request)
    local url =
    "http://localhost:8080/infill" -- Or remote host
    local body = {
        input_prefix = prompt_request.prefix,
        input_suffix = prompt_request.suffix,
        max_tokens = 32,
        tempeture = 0.7,
        stop = { "\n\n", "\n\n\n", "<fim_prefix>", "<fim_suffix>", "<fim_middle>", "```", "</" },
        top_p = 0.9,
        top_k = 40,
        repeat_penalty = 1.1,
        presence_penalty = 0.0,
        frequency_penalty = 0.0,
        stream = true
    }
    stream_llm_post(url, body,
        function(payload)
            vim.schedule(function()
                vim.api.nvim_exec_autocmds("User", {
                    pattern = "AgentResponse",
                    data = { response = payload },
                })
            end)
        end
    )
end

return M
