local lang = require("completion.lang.csharp")
local helper = require("tests.helper")

local function goto_marker(text)
    local row = vim.fn.search(text)
    assert.is_true(row > 0, "Marker not found: " .. text)
    vim.api.nvim_win_set_cursor(0, { row, 8 })
    return row
end

if helper.has_csharp_parser() then
    describe("get_context_snapshot() (csharp)", function()
        before_each(function()
            vim.cmd("edit tests/fixtures/sample.cs")
            vim.bo.filetype = "cs"

            vim.treesitter.start(0, "c_sharp")
            vim.treesitter.start(0, "c_sharp")
        end)
        it("returns FULL context for method", function()
            -- place cursor inside method body
            local row = goto_marker("return a + b + _base")

            local snapshot = lang.get_context_snapshot()
            assert(snapshot)

            assert.equals("block", snapshot.category)
            assert.equals("method_declaration", snapshot.node:parent():type())
            assert.equals(row - 1, snapshot.curr_row)
            assert.is_false(snapshot.err_node_present)
            assert.equals(39, snapshot.context_start)
            assert.equals(42, snapshot.context_end)
        end)

        it("returns PARTIAL context for class", function()
            local row = goto_marker("private readonly int _base")

            local snapshot = lang.get_context_snapshot()
            assert(snapshot)
            assert.equals(nil, snapshot.category)
            assert.equals("class", snapshot.scope_set_category)

            -- PARTIAL rule
            assert.is_true(snapshot.context_start < snapshot.curr_row)
            assert.is_true(snapshot.context_end > snapshot.curr_row)
        end)
        it("returns FULL context for enum", function()
            local row = goto_marker("Unknown")

            local snapshot = lang.get_context_snapshot()
            assert(snapshot)

            assert.equals("declaration", snapshot.category)
            assert.equals("enum", snapshot.scope_set_category)
            assert.equals(8, snapshot.context_start)
            assert.equals(13, snapshot.context_end)
        end)

        it("returns FULL context for struct", function()
            -- For the below goto_marker it is a lambda function. May need to figure out how to handle this situation
            --local row = goto_marker("public double Distance")
            local row = goto_marker("public double X")

            local snapshot = lang.get_context_snapshot()
            assert(snapshot)

            assert.equals(nil, snapshot.category)
            assert.equals("struct", snapshot.scope_set_category)
            assert.equals(15, snapshot.context_start)
            assert.equals(21, snapshot.context_end)
        end)
        it("returns FULL context for interface", function()
            -- For the below goto_marker, it is saying that it is a function. So just placing empty line below function
            -- definition to to get the correct snapshot category
            -- local row = goto_marker("int Add(int a, int b)")
            vim.api.nvim_win_set_cursor(0, { 27, 8 })

            local snapshot = lang.get_context_snapshot()
            assert(snapshot)

            assert.equals(nil, snapshot.category)
            assert.equals("interface", snapshot.scope_set_category)
            assert.equals(23, snapshot.context_start)
            assert.equals(26, snapshot.context_end)
        end)

        it("returns nil when no node at cursor", function()
            vim.api.nvim_win_set_cursor(0, { 1, 0 })

            local snapshot = lang.get_context_snapshot()
            assert.is_nil(snapshot)
        end)
    end)
else
    describe("treesitter (csharp)", function()
        pending("c_sharp Treesitter parser not installed")
    end)
end
