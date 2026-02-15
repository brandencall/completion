local lang = require("completion.lang.lua")
local helper = require("tests.helper")

describe("get_context_snapshot() (lua)", function()
    before_each(function()
        vim.cmd("edit tests/fixtures/sample.lua")
        vim.bo.filetype = "lua"

        vim.treesitter.start(0, "lua")
        vim.treesitter.get_parser(0):parse()
    end)

    it("returns FULL context for method-style function", function()
        local row = helper.goto_marker("return math.sqrt")

        local snapshot = lang.get_context_snapshot()
        assert(snapshot)

        assert.equals("func", snapshot.scope_set_category)
        assert.equals("block", snapshot.node:parent():type())
        assert.equals(row - 1, snapshot.curr_row)
        assert.is_false(snapshot.err_node_present)

        assert.is_true(snapshot.context_start < snapshot.context_end)
    end)

    it("returns FULL context for local function", function()
        local _ = helper.goto_marker("local function sum")

        -- move cursor inside body
        local row = helper.goto_marker("return total")

        local snapshot = lang.get_context_snapshot()
        assert(snapshot)

        assert.equals("func", snapshot.scope_set_category)
        assert.is_true(snapshot.context_start < snapshot.context_end)
    end)

    it("returns FULL context for nested inner function", function()
        local row = helper.goto_marker("return \"inner value\"")

        local snapshot = lang.get_context_snapshot()
        assert(snapshot)

        assert.equals("func", snapshot.scope_set_category)
        assert.is_true(snapshot.context_start < snapshot.context_end)
    end)

    it("returns PARTIAL context for top level", function()
        -- put cursor on GLOBAL_VALUE
        local row = helper.goto_marker("GLOBAL_VALUE")

        local snapshot = lang.get_context_snapshot()
        assert(snapshot)

        assert.equals(nil, snapshot.category)
        assert.equals("top_level", snapshot.scope_set_category)

        assert.is_true(snapshot.context_start < snapshot.curr_row)
        assert.is_true(snapshot.context_end > snapshot.curr_row)
    end)

    it("detects loop inside function", function()
        local row = helper.goto_marker("for i = 1, 3 do")

        local snapshot = lang.get_context_snapshot()
        assert(snapshot)

        -- your categorizer may label this as "loop"
        assert.equals("loop", snapshot.category)
        assert.equals("func", snapshot.scope_set_category)
    end)

    it("returns comment context at top of file", function()
        -- cursor at first line (comment)
        vim.api.nvim_win_set_cursor(0, { 1, 0 })

        local snapshot = lang.get_context_snapshot()
        assert(snapshot)

        assert.equals("comment", snapshot.category)
        assert.equals("top_level", snapshot.scope_set_category)

        assert.equals(0, snapshot.curr_row)
        assert.equals(false, snapshot.err_node_present)

        assert.equals(0, snapshot.context_start)
        assert.equals(1, snapshot.context_end)

        assert.equals("comment", snapshot.node:type())
    end)
end)
