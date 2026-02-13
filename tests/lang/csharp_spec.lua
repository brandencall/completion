local lang = require("completion.lang.csharp")
local helper = require("tests.helper")

if helper.has_csharp_parser() then
    describe("get_context_snapshot() (csharp)", function()
        it("get_context_snapshot()", function()
            helper.parse_csharp({
                "public class Test {",
                "  public void Method() {",
                "",
                "  }",
                "}",
            })
            vim.api.nvim_win_set_cursor(0, { 3, 0 })

            local snapshot = lang.get_context_snapshot()
            print(vim.inspect(snapshot))
        end)
    end)
else
    describe("treesitter (csharp)", function()
        pending("c_sharp Treesitter parser not installed")
    end)
end
