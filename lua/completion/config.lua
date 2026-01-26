local M = {}

local defaults = {
    model = nil,
    server = {
        url = "http://127.0.0.1:8080",
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
