local M = {}

local defaults = {
    model = "Qwen/Qwen2.5-Coder-7B-Instruct-GGUF:Q4_K_M",
    server = {
        startup_path = "/home/brabs/Applications/llama.cpp/build/bin/llama-server",
        host = "http://127.0.0.1",
        port = "8080",
        endpoint = "/infill",
    },
    max_tokens = 32,
    temperature = 0.2,
    stop = { "\n\n", "\n\n\n", "<fim_prefix>", "<fim_suffix>", "<fim_middle>", "```", "</" },
    top_p = 0.9,
    top_k = 40,
    repeat_penalty = 1.1,
    presence_penalty = 0.0,
    frequency_penalty = 0.0,
}

local config = vim.deepcopy(defaults)

function M.setup(user_config)
    config = vim.tbl_deep_extend("force", config, user_config)
end

function M.get()
    return config
end

return M
