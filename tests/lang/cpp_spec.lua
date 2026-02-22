local lang = require("completion.lang.cpp")
local helper = require("tests.helper")

if helper.has_cpp_parser() then
    describe("get_context_snapshot() (cpp)", function()
        before_each(function()
            vim.cmd("edit tests/fixtures/sample.cpp")
            vim.bo.filetype = "cpp"

            vim.treesitter.start(0, "cpp")
        end)

        it("returns FULL context for class method (add)", function()
            local row = helper.goto_marker("return a + b + base_;")

            local snapshot = lang.get_context_snapshot()
            assert(snapshot)

            assert.equals("func", snapshot.scope_set_category)
            assert.equals(row - 1, snapshot.curr_row)
            assert.is_false(snapshot.err_node_present)

            assert.equals(19, snapshot.context_start)
            assert.equals(19, snapshot.context_end)
        end)

        it("returns FULL context for enum", function()
            helper.parse_lines({
                "enum class status {",
                "   Ok,",
                "   Error,",
                "   Unknown,",
                "}",
            }, "cpp")
            vim.api.nvim_win_set_cursor(0, { 2, 9 })
            --helper.goto_marker("Unknown")

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

            assert.equals(9, snapshot.context_start)
            assert.equals(12, snapshot.context_end)
        end)

        it("returns FULL context for template free function", function()
            helper.goto_marker("result += item;")

            local snapshot = lang.get_context_snapshot()
            assert(snapshot)

            assert.equals("func", snapshot.scope_set_category)

            -- process_vector lines 29–38
            assert.equals(27, snapshot.context_start)
            assert.equals(35, snapshot.context_end)
        end)

        it("returns FULL context inside main()", function()
            helper.goto_marker('std::cout << "Large result')

            local snapshot = lang.get_context_snapshot()
            assert(snapshot)

            assert.equals("func", snapshot.scope_set_category)

            assert.equals(39, snapshot.context_start)
            assert.equals(81, snapshot.context_end)
        end)

        it("handles incomplete if statement", function()
            helper.parse_lines({
                "int main() {",
                "  if (",
                "}",
            }, "cpp")

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
            }, "cpp")

            vim.api.nvim_win_set_cursor(0, { 2, 13 })

            local snapshot = lang.get_context_snapshot()
            assert(snapshot)

            assert.equals("func", snapshot.scope_set_category)
            assert.is_true(snapshot.err_node_present)
        end)
    end)
else
    describe("treesitter (cpp)", function()
        pending("cpp Treesitter parser not installed")
    end)
end
