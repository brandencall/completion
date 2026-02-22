local lang = require("completion.lang.c")
local helper = require("tests.helper")

if helper.has_parser("c") then
    describe("get_context_snapshot() (c)", function()
        before_each(function()
            vim.cmd("edit tests/fixtures/sample.c")
            vim.bo.filetype = "c"

            vim.treesitter.start(0, "c")
        end)

        it("returns FULL context for function (calculator_add)", function()
            local row = helper.goto_marker("return a + b + calc->base;")

            local snapshot = lang.get_context_snapshot()
            assert(snapshot)

            assert.equals("func", snapshot.scope_set_category)
            assert.equals(row - 1, snapshot.curr_row)
            assert.is_false(snapshot.err_node_present)
        end)

        it("returns FULL context for enum", function()
            helper.parse_lines({
                "enum status {",
                "   STATUS_OK,",
                "   STATUS_ERROR,",
                "   STATUS_UNKNOWN,",
                "};",
            }, "c")

            vim.api.nvim_win_set_cursor(0, { 2, 10 })

            local snapshot = lang.get_context_snapshot()
            assert(snapshot)

            assert.equals("enum", snapshot.scope_set_category)

            assert.equals(0, snapshot.context_start)
            assert.equals(4, snapshot.context_end)
        end)

        it("returns FULL context for struct", function()
            helper.goto_marker("double y;")

            local snapshot = lang.get_context_snapshot()
            assert(snapshot)

            assert.equals("struct", snapshot.scope_set_category)
        end)

        it("returns FULL context for process_vector", function()
            helper.goto_marker("int result = 0;")

            local snapshot = lang.get_context_snapshot()
            assert(snapshot)

            assert.equals("func", snapshot.scope_set_category)
        end)

        it("returns FULL context inside main()", function()
            helper.goto_marker('printf("Large result')

            local snapshot = lang.get_context_snapshot()
            assert(snapshot)

            assert.equals("func", snapshot.scope_set_category)
        end)

        it("handles incomplete if statement", function()
            helper.parse_lines({
                "int main() {",
                "  if (",
                "}",
            }, "c")

            vim.api.nvim_win_set_cursor(0, { 2, 6 })

            local snapshot = lang.get_context_snapshot()
            assert(snapshot)

            assert.equals("func", snapshot.scope_set_category)
            assert.is_true(snapshot.err_node_present)
        end)

        it("handles incomplete expression assignment", function()
            helper.parse_lines({
                "int main() {",
                "  int x = 5 +",
                "}",
            }, "c")

            vim.api.nvim_win_set_cursor(0, { 2, 13 })

            local snapshot = lang.get_context_snapshot()
            assert(snapshot)

            assert.equals("func", snapshot.scope_set_category)
            assert.is_true(snapshot.err_node_present)
        end)
    end)
else
    describe("treesitter (c)", function()
        pending("c Treesitter parser not installed")
    end)
end
