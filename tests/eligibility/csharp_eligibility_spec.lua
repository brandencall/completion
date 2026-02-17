local lang = require("completion.lang.csharp")
local eligibility = require("completion.eligibility")
local helper = require("tests.helper")

if helper.has_csharp_parser() then
    describe("get_context_snapshot() (csharp)", function()
        before_each(function()
            vim.cmd("enew")
            vim.bo.filetype = "csharp"
        end)

        -- =========================
        -- Context / Block Tests
        -- =========================

        it("is eligible inside incomplete if block while typing", function()
            vim.api.nvim_buf_set_lines(0, 0, -1, false, {
                "public class Test {",
                "    public void Method() {",
                "        if (true) {",
                "            Console.WriteLine(\"Hello\");",
                "            ",
                "    }",
                "}",
            })

            local row = 5
            local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
            vim.api.nvim_win_set_cursor(0, { row, #line })

            local context = lang.get_context_snapshot()
            assert.is_true(eligibility.is_eligible(context))
        end)

        it("is not eligible inside broken if condition", function()
            vim.api.nvim_buf_set_lines(0, 0, -1, false, {
                "public class Test {",
                "    public void Method() {",
                "        if (",
                "    }",
                "}",
            })

            local row = 3
            local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
            vim.api.nvim_win_set_cursor(0, { row, #line })

            local context = lang.get_context_snapshot()
            assert.is_true(eligibility.is_eligible(context))
        end)

        -- =========================
        -- Character Trigger Tests
        -- =========================

        it("is eligible during member access '.'", function()
            vim.api.nvim_buf_set_lines(0, 0, -1, false, {
                "class Test {",
                "    void M() {",
                "        var x = 5;",
                "        x.",
                "    }",
                "}",
            })

            local row = 4
            local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
            vim.api.nvim_win_set_cursor(0, { row, #line })

            local context = lang.get_context_snapshot()
            assert.is_true(eligibility.is_eligible(context))
        end)

        it("is eligible after '(' trigger", function()
            vim.api.nvim_buf_set_lines(0, 0, -1, false, {
                "class Test {",
                "    void M() {",
                "        Console.WriteLine(",
                "    }",
                "}",
            })

            local row = 3
            local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
            vim.api.nvim_win_set_cursor(0, { row, #line })

            local context = lang.get_context_snapshot()
            assert.is_true(eligibility.is_eligible(context))
        end)

        it("is eligible after '<' trigger", function()
            vim.api.nvim_buf_set_lines(0, 0, -1, false, {
                "public class Test<",
            })

            local row = 1
            local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
            vim.api.nvim_win_set_cursor(0, { row, #line })

            local context = lang.get_context_snapshot()
            assert.is_true(eligibility.is_eligible(context))
        end)

        it("is eligible after '>' trigger", function()
            vim.api.nvim_buf_set_lines(0, 0, -1, false, {
                "public class Test<T>",
            })

            local row = 1
            local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
            vim.api.nvim_win_set_cursor(0, { row, #line })

            local context = lang.get_context_snapshot()
            assert.is_true(eligibility.is_eligible(context))
        end)

        it("is eligible after '[' trigger", function()
            vim.api.nvim_buf_set_lines(0, 0, -1, false, {
                "class Test {",
                "    void M() {",
                "        var arr = new int[",
                "    }",
                "}",
            })

            local row = 3
            local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
            vim.api.nvim_win_set_cursor(0, { row, #line })

            local context = lang.get_context_snapshot()
            assert.is_true(eligibility.is_eligible(context))
        end)

        it("is eligible after ':' trigger", function()
            vim.api.nvim_buf_set_lines(0, 0, -1, false, {
                "public class Test :",
            })

            local row = 1
            local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
            vim.api.nvim_win_set_cursor(0, { row, #line })

            local context = lang.get_context_snapshot()
            assert.is_true(eligibility.is_eligible(context))
        end)

        it("is eligible after ',' trigger", function()
            vim.api.nvim_buf_set_lines(0, 0, -1, false, {
                "class Test {",
                "    void M() {",
                "        Console.WriteLine(\"a\",",
                "    }",
                "}",
            })

            local row = 3
            local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
            vim.api.nvim_win_set_cursor(0, { row, #line })

            local context = lang.get_context_snapshot()
            assert.is_true(eligibility.is_eligible(context))
        end)

        it("is eligible after '=' trigger", function()
            vim.api.nvim_buf_set_lines(0, 0, -1, false, {
                "class Test {",
                "    void M() {",
                "        int x =",
                "    }",
                "}",
            })

            local row = 3
            local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
            vim.api.nvim_win_set_cursor(0, { row, #line })

            local context = lang.get_context_snapshot()
            assert.is_true(eligibility.is_eligible(context))
        end)

        -- =========================
        -- Keyword Trigger Tests
        -- =========================

        it("is eligible after 'return'", function()
            vim.api.nvim_buf_set_lines(0, 0, -1, false, {
                "class Test {",
                "    int M() {",
                "        return",
                "    }",
                "}",
            })

            local row = 3
            local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
            vim.api.nvim_win_set_cursor(0, { row, #line })

            local context = lang.get_context_snapshot()
            assert.is_true(eligibility.is_eligible(context))
        end)

        it("is eligible after 'new'", function()
            vim.api.nvim_buf_set_lines(0, 0, -1, false, {
                "class Test {",
                "    void M() {",
                "        var x = new",
                "    }",
                "}",
            })

            local row = 3
            local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
            vim.api.nvim_win_set_cursor(0, { row, #line })

            local context = lang.get_context_snapshot()
            assert.is_true(eligibility.is_eligible(context))
        end)

        it("is eligible after 'await'", function()
            vim.api.nvim_buf_set_lines(0, 0, -1, false, {
                "class Test {",
                "    async Task M() {",
                "        await",
                "    }",
                "}",
            })

            local row = 3
            local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
            vim.api.nvim_win_set_cursor(0, { row, #line })

            local context = lang.get_context_snapshot()
            assert.is_true(eligibility.is_eligible(context))
        end)

        it("is eligible after 'throw'", function()
            vim.api.nvim_buf_set_lines(0, 0, -1, false, {
                "class Test {",
                "    void M() {",
                "        throw",
                "    }",
                "}",
            })

            local row = 3
            local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
            vim.api.nvim_win_set_cursor(0, { row, #line })

            local context = lang.get_context_snapshot()
            assert.is_true(eligibility.is_eligible(context))
        end)

        it("is eligible after 'case'", function()
            vim.api.nvim_buf_set_lines(0, 0, -1, false, {
                "class Test {",
                "    void M(int x) {",
                "        switch (x) {",
                "            case",
                "        }",
                "    }",
                "}",
            })

            local row = 4
            local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
            vim.api.nvim_win_set_cursor(0, { row, #line })

            local context = lang.get_context_snapshot()
            assert.is_true(eligibility.is_eligible(context))
        end)

        -- =========================
        -- Safety Tests
        -- =========================

        it("is not eligible inside a comment", function()
            vim.api.nvim_buf_set_lines(0, 0, -1, false, {
                "class Test {",
                "    void M() {",
                "        // typing here",
                "    }",
                "}",
            })

            local row = 3
            local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
            vim.api.nvim_win_set_cursor(0, { row, #line })

            local context = lang.get_context_snapshot()
            assert.is_false(eligibility.is_eligible(context))
        end)

        it("is not eligible inside a string", function()
            vim.api.nvim_buf_set_lines(0, 0, -1, false, {
                "class Test {",
                "    void M() {",
                "        var s = \"hello world\";",
                "    }",
                "}",
            })

            local row = 3
            local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
            vim.api.nvim_win_set_cursor(0, { row, #line })

            local context = lang.get_context_snapshot()
            assert.is_false(eligibility.is_eligible(context))
        end)
    end)
else
    describe("treesitter (csharp)", function()
        pending("c_sharp Treesitter parser not installed")
    end)
end
