local lang = require("completion.lang.csharp")
local helper = require("tests.helper")

if helper.has_csharp_parser() then
    describe("get_context_snapshot() (csharp)", function()
        before_each(function()
            vim.cmd("edit tests/fixtures/sample.cs")
            vim.bo.filetype = "cs"

            vim.treesitter.start(0, "c_sharp")
            vim.treesitter.start(0, "c_sharp")
        end)
        it("testing fixtures", function()
            -- place cursor inside method body
            vim.api.nvim_win_set_cursor(0, { 18, 12 })

            local context = lang.get_context_snapshot()
            print(vim.inspect(context))
            print(vim.inspect(context.node:parent():type()))
        end)
    end)
else
    describe("treesitter (csharp)", function()
        pending("c_sharp Treesitter parser not installed")
    end)
end
