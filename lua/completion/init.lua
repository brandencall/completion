local state = require("completion.state_manager")
local server = require("completion.server")
local config = require("completion.config")

local M = {}

function M.setup(user_config)
    config.setup(user_config or {})
    require("completion.http")
    require("completion.agent_response.render")
    require("completion.agent_response.display_response")
    local opts = config.get()
    server.start(opts)
    state.enable()

    vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function()
            server.stop()
        end,
    })
end

--function M.start()
--    state.enable()
--end

function M.stop()
    state.disable()
    server.stop()
end

return M
