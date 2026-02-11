local renderer = require("completion.renderer")
local helper = require("tests.helper")

describe("renderer", function()
    local restore_mode
    local restore_schedule

    before_each(function()
        renderer.clear_text()
        vim.cmd("enew!")
        restore_mode = helper.mock_mode_insert()
        restore_schedule = helper.mock_schedule_sync()
    end)

    after_each(function()
        restore_mode()
        restore_schedule()
    end)

    it("renders extmarks in insert mode", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "hello world" })
        vim.api.nvim_win_set_cursor(0, { 1, 5 })
        renderer.show_agent_response("ABC", {})

        local ns = vim.api.nvim_get_namespaces()["agent_response"]

        local extmarks = vim.api.nvim_buf_get_extmarks(
            0,
            ns,
            0,
            -1,
            { details = true }
        )

        assert.is_true(#extmarks > 0)
    end)

    it("inserts a single line completion", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "hello world"
        })

        -- place cursor after 'hello'
        vim.api.nvim_win_set_cursor(0, { 1, 5 })

        renderer.show_agent_response("ABC", {})
        renderer.insert_agent_text()

        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

        assert.are.same({
            "helloABC world"
        }, lines)
    end)

    it("renders a multi-line completion", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "function test()",
            ""
        })

        -- cursor at empty second line
        vim.api.nvim_win_set_cursor(0, { 2, 0 })

        renderer.show_agent_response(
            "  print('hi')\nend",
            {}
        )
        renderer.insert_agent_text()

        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

        assert.are.same({
            "function test()",
            "  print('hi')",
            "end"
        }, lines)
    end)

    --[[
    --Buffer contains:
    --  function test()
    --
    --  end
    --
    --LLM generates:
    --    foo()
    --  end
    --
    -- full buffer should include:
    --  function test()
    --    foo() <-- generated
    --  end <-- og suffix
    --
    --]]
    it("does not duplicate overlapping suffix content", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "function test()",
            "",
            "end"
        })

        -- cursor before existing 'end'
        vim.api.nvim_win_set_cursor(0, { 2, 0 })

        renderer.show_agent_response(
            "  foo()\nend",
            { "end" } -- suffix contains overlapping end
        )
        renderer.insert_agent_text()

        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

        -- The 'end' should NOT be duplicated
        assert.are.same({
            "function test()",
            "  foo()",
            "end"
        }, lines)
    end)
    --[[
    --Buffer contains:
    --  if
    --
    --  end
    --end
    --
    --LLM generates:
    --    foo()
    --  end
    --  return test
    --
    -- full buffer should include:
    --  if
    --    foo() <-- generated
    --  end <-- og suffix
    --  return test <-- generated
    --end <-- og suffix
    --
    --]]
    it("does not duplicate layered suffix blocks", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "  if",
            "",
            "  end",
            "end"
        })

        vim.api.nvim_win_set_cursor(0, { 2, 0 })

        local generated = [[
    foo()
  end
  return test]]

        local suffix = {
            "  end",
            "end"
        }

        renderer.show_agent_response(generated, suffix)
        renderer.insert_agent_text()

        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

        assert.are.same({
            "  if",
            "    foo()",
            "  end",
            "  return test",
            "end"
        }, lines)
    end)

    it("handles multiple multiline blocks", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "function test()",
            "  if test then",
            "",
            "  end",
            "  print('not generated')",
            "end"
        })

        vim.api.nvim_win_set_cursor(0, { 3, 0 })

        local generated = [[
    print('test1')
    print('test2')
  end
  print('test3')
  print('test4')
  print('not generated')
  print('test5')
  print('test6')]]

        local suffix = {
            "  end",
            "  print('not generated')",
            "end"
        }

        renderer.show_agent_response(generated, suffix)
        renderer.insert_agent_text()

        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

        assert.are.same({
            "function test()",
            "  if test then",
            "    print('test1')",
            "    print('test2')",
            "  end",
            "  print('test3')",
            "  print('test4')",
            "  print('not generated')",
            "  print('test5')",
            "  print('test6')",
            "end"
        }, lines)
    end)
end)
