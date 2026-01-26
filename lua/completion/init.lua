local state = require("completion.state_manager")
local config = require("completion.config")

local M = {}

function M.setup(user_config)
    config.setup(user_config or {})
    require("completion.context_builder")
    require("completion.renderer")
    require("completion.http")
end

function M.start()
    state.enable()
end

function M.stop()
    state.disable()
end

return M
