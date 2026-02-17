local lang = require("completion.lang.lua")
local eligibility = require("completion.eligibility")

describe("get_context_snapshot() (lua)", function()
    before_each(function()
        vim.cmd("enew")
        vim.bo.filetype = "lua"
    end)

    -- =========================
    -- Context / Block Tests
    -- =========================

    it("is eligible inside incomplete if block while typing", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "local function test()",
            "    if true then",
            "        print(\"Hello\")",
            "        ",
            "    end",
            "end",
        })

        local row = 4
        local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
        vim.api.nvim_win_set_cursor(0, { row, #line })

        local context = lang.get_context_snapshot(false)
        assert.is_true(eligibility.is_eligible(context))
    end)

    it("is eligible inside broken if condition. Trigger on 'if'", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "local function test()",
            "    if ",
            "end",
        })

        local row = 2
        local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
        vim.api.nvim_win_set_cursor(0, { row, #line })

        local context = lang.get_context_snapshot(true)
        assert.is_true(eligibility.is_eligible(context))
    end)

    -- =========================
    -- Character Trigger Tests
    -- =========================

    it("is eligible during table member access '.'", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "local t = {}",
            "t.",
        })

        local row = 2
        local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
        vim.api.nvim_win_set_cursor(0, { row, #line })

        local context = lang.get_context_snapshot(true)
        assert.is_true(eligibility.is_eligible(context))
    end)

    it("is eligible after ':' trigger", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "local obj = {}",
            "obj:",
        })

        local row = 2
        local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
        vim.api.nvim_win_set_cursor(0, { row, #line })

        local context = lang.get_context_snapshot(true)
        assert.is_true(eligibility.is_eligible(context))
    end)

    it("is eligible after '(' trigger", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "print(",
        })

        local row = 1
        local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
        vim.api.nvim_win_set_cursor(0, { row, #line })

        local context = lang.get_context_snapshot(true)
        assert.is_true(eligibility.is_eligible(context))
    end)

    it("is eligible after '{' trigger", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "local t = {",
        })

        local row = 1
        local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
        vim.api.nvim_win_set_cursor(0, { row, #line })

        local context = lang.get_context_snapshot(true)
        assert.is_true(eligibility.is_eligible(context))
    end)

    it("is eligible after '[' trigger", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "local t = {}",
            "t[",
        })

        local row = 2
        local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
        vim.api.nvim_win_set_cursor(0, { row, #line })

        local context = lang.get_context_snapshot(true)
        assert.is_true(eligibility.is_eligible(context))
    end)

    it("is eligible after ',' trigger", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "print(\"a\",",
        })

        local row = 1
        local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
        vim.api.nvim_win_set_cursor(0, { row, #line })

        local context = lang.get_context_snapshot(true)
        assert.is_true(eligibility.is_eligible(context))
    end)

    it("is eligible after '=' trigger", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "local x =",
        })

        local row = 1
        local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
        vim.api.nvim_win_set_cursor(0, { row, #line })

        local context = lang.get_context_snapshot(true)
        assert.is_true(eligibility.is_eligible(context))
    end)

    -- =========================
    -- Keyword Trigger Tests
    -- =========================

    it("is eligible after 'if' keyword", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "if",
        })

        local row = 1
        local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
        vim.api.nvim_win_set_cursor(0, { row, #line })

        local context = lang.get_context_snapshot(true)
        assert.is_true(eligibility.is_eligible(context))
    end)

    it("is eligible after 'for' keyword", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "for",
        })

        local row = 1
        local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
        vim.api.nvim_win_set_cursor(0, { row, #line })

        local context = lang.get_context_snapshot(true)
        assert.is_true(eligibility.is_eligible(context))
    end)

    it("is eligible after 'while' keyword", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "while",
        })

        local row = 1
        local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
        vim.api.nvim_win_set_cursor(0, { row, #line })

        local context = lang.get_context_snapshot(true)
        assert.is_true(eligibility.is_eligible(context))
    end)

    it("is eligible after 'return' keyword", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "local function test()",
            "    return",
            "end",
        })

        local row = 2
        local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
        vim.api.nvim_win_set_cursor(0, { row, #line })

        local context = lang.get_context_snapshot(true)
        assert.is_true(eligibility.is_eligible(context))
    end)

    -- =========================
    -- Safety Tests
    -- =========================

    it("is not eligible inside a comment", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "local function test()",
            "    -- typing here",
            "end",
        })

        local row = 2
        local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
        vim.api.nvim_win_set_cursor(0, { row, #line })

        local context = lang.get_context_snapshot(false)
        assert.is_false(eligibility.is_eligible(context))
    end)

    it("is not eligible inside a string", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "local s = \"hello world\"",
        })

        local row = 1
        local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
        vim.api.nvim_win_set_cursor(0, { row, #line })

        local context = lang.get_context_snapshot(false)
        assert.is_false(eligibility.is_eligible(context))
    end)

    it("is not eligible inside block scope when line is not empty", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "function M.sum_upto(n)",
            "    local sum = 0",
            "    local i = 1",
            "    while i <= n do",
            "        local test ",
            "    end",
            "end"
        })

        local row = 5
        local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
        vim.api.nvim_win_set_cursor(0, { row, #line })

        local context = lang.get_context_snapshot(false)
        assert.is_false(eligibility.is_eligible(context))
    end)
end)
