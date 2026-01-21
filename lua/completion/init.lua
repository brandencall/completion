local state = require("completion.state_manager")

local M = {}

function M.setup()
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
