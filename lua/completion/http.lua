local Job = require("plenary.job")
local debug = require("completion.debug")
local json = vim.json
local config = require("completion.config").get()

local M = {}

local active_job = nil

vim.api.nvim_create_autocmd("User", {
    pattern = "AgentRequest",
    callback = function(event)
        local prompt_request = event.data.request
        M.handle_completion(prompt_request)
    end,
})

vim.api.nvim_create_autocmd("User", {
    pattern = "IdleState",
    callback = function()
        if active_job then
            active_job:shutdown()
            active_job = nil
        end
    end,
})

local function stream_llm_post(url, body_table, suffix, on_chunk_callback, on_complete_callback)
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
            if not active_job then
                return
            end
            if data then
                local ok, parsed = pcall(json.decode, string.sub(data, 7))
                if ok and parsed.stop == true then
                    vim.schedule(function()
                        vim.api.nvim_exec_autocmds("User", {
                            pattern = "PromptFinished"
                        })
                    end)
                elseif ok and parsed.content then
                    on_chunk_callback(parsed.content)
                end
            end
        end,
        on_exit = function(j, return_code)
            active_job = nil
            if return_code == 0 and type(on_complete_callback) == "function" then
                on_complete_callback()
            elseif return_code ~= 0 then
                print(j:stderr_result())
            end
        end,
    })
    job:start()
    return job
end

--- This function is responible for sending prompt requests to agent server.
--- @param prompt_request PromptRequest
function M.handle_completion(prompt_request)
    local url = config.server.url .. config.server.endpoint
    local body = {
        input_prefix = prompt_request.prefix,
        input_suffix = prompt_request.suffix,
        max_tokens = config.max_tokens,
        temperature = config.temperature,
        stop = config.stop,
        top_p = config.top_p,
        top_k = config.top_k,
        repeat_penalty = config.repeat_penalty,
        presence_penalty = config.presence_penalty,
        frequency_penalty = config.frequency_penalty,
        stream = true
    }
    active_job = stream_llm_post(url, body, prompt_request.suffix,
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
