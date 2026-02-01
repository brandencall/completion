local Job = require("plenary.job")

local M = {}

M.job = nil

function M.start(config)
    if M.job and config.server.startup_path == nil then
        return
    end

    M.job = Job:new({
        command = config.server.startup_path,
        args = {
            "-hf",
            config.model,
        },
        on_exit = function(_, code)
            M.job = nil
            if code ~= 0 then
                vim.notify("LLaMA server exited with code " .. code, vim.log.levels.WARN)
            end
        end,
    })

    M.job:start()
end

function M.stop()
    if not M.job then
        return
    end

    -- Try graceful shutdown first
    pcall(function()
        M.job:shutdown()
    end)

    M.job = nil
end

return M
