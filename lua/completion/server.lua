local Job = require("plenary.job")

local M = {}

M.job = nil

local ref_file = vim.fn.stdpath("run") .. "/completion_server_ref"
local pid_file = vim.fn.stdpath("run") .. "/completion_server.pid"

local function increment_ref()
    local count = 0

    if vim.fn.filereadable(ref_file) == 1 then
        count = tonumber(vim.fn.readfile(ref_file)[1]) or 0
    end

    count = count + 1
    vim.fn.writefile({ tostring(count) }, ref_file)
end

local function start_server(config)
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
    vim.fn.writefile({ tostring(M.job.pid) }, pid_file)
end

function M.start(config)
    if M.job and M.job:is_running() then
        return
    end
    if config.server.startup_path == nil then
        return
    end
    increment_ref()
    if not vim.uv.fs_stat(pid_file) then
        start_server(config)
    end
end

local function stop()
    if vim.fn.filereadable(pid_file) == 0 then
        return
    end

    local pid = tonumber(vim.fn.readfile(pid_file)[1])
    if not pid then
        vim.fn.delete(pid_file)
        return
    end
    pcall(function()
        vim.loop.kill(pid, "sigterm")
    end)
    vim.defer_fn(function()
        pcall(function()
            vim.loop.kill(pid, "sigkill")
        end)
    end, 300)

    vim.fn.delete(pid_file)
end

local function decrement_and_maybe_stop()
    if vim.fn.filereadable(ref_file) == 0 then
        return
    end

    local count = tonumber(vim.fn.readfile(ref_file)[1]) or 0
    count = math.max(0, count - 1)

    if count == 0 then
        stop()
        vim.fn.delete(ref_file)
    else
        vim.fn.writefile({ tostring(count) }, ref_file)
    end
end

vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
        decrement_and_maybe_stop()
    end,
})

return M
