local lang = require("completion.lang.lua")
local helper = require("tests.helper")

describe("get_context_snapshot() (lua)", function()
    it("get_context_snapshot()", function()
        helper.parse_lua({
            "local function test()",
            "  local x = 1",
            "",
            "end",
        })
        vim.api.nvim_win_set_cursor(0, { 3, 0 })

        local snapshot = lang.get_context_snapshot()
        print(vim.inspect(snapshot))
    end)
end)
