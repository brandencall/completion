local Job = require("plenary.job")

local M = {}

M.job = nil

function M.start(config)
    if M.job and M.job:is_running() then
        return
    end
    if config.server.startup_path == nil then
        return
    end

    M.job = Job:new({
        command = config.server.startup_path,
        args = {
            "-hf",
            config.model,
        },
        on_exit = function(_, _)
            M.job = nil
        end,
    })

    M.job:start()
end

function M.stop()
    if not M.job or not M.job.pid then
        return
    end

    local pid = M.job.pid

    vim.loop.kill(pid, "sigterm")

    vim.defer_fn(function()
        pcall(function()
            vim.loop.kill(pid, "sigkill")
        end)
    end, 200)

    M.job = nil
end

return M
