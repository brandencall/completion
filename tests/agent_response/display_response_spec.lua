local render = require("completion.agent_response.render")
local state = require("completion.state_manager")
local display = require("completion.agent_response.display_response")
local helper = require("tests.helper")

describe("renderer", function()
    local restore_mode
    local restore_schedule

    before_each(function()
        state.clear_agent_response_state()
        vim.cmd("enew!")
        restore_mode = helper.mock_mode_insert()
        restore_schedule = helper.mock_schedule_sync()
    end)

    after_each(function()
        restore_mode()
        restore_schedule()
    end)

    it("inserts a single line completion", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "hello world"
        })

        -- place cursor after 'hello'
        vim.api.nvim_win_set_cursor(0, { 1, 5 })

        render.show_agent_response("ABC", {})
        display.insert_agent_text()

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

        render.show_agent_response(
            "  print('hi')\nend",
            {}
        )
        display.insert_agent_text()

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

        render.show_agent_response(
            "  foo()\nend",
            { "end" } -- suffix contains overlapping end
        )
        display.insert_agent_text()

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

        render.show_agent_response(generated, suffix)
        display.insert_agent_text()

        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

        assert.are.same({
            "  if",
            "    foo()",
            "  end",
            "  return test",
            "end"
        }, lines)
    end)

    --[[
    --Buffer contains:
    --function test()
    --  if test then
    --
    --  end
    --  print('not generated')
    --end
    --
    --LLM generates:
    --   print('test1')
    --   print('test2')
    -- end
    -- print('test3')
    -- print('test4')
    -- print('not generated')
    -- print('test5')
    -- print('test6')
    --
    -- full buffer should include:
    --function test()
    --  if test then
    --   print('test1') <-- generated
    --   print('test2') <-- generated
    --  end <-- og suffix
    --  print('test3') <-- generated
    --  print('test4') <-- generated
    --  print('not generated') <-- og suffix
    --  print('test5') <-- generated
    --  print('test6') <-- generated
    --end
    --
    --]]
    it("handles multiple multiline blocks with buffer overflow", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "function test()",
            "  if test then",
            "",
            "  end",
            "  print('not generated')",
            "end",
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

        render.show_agent_response(generated, suffix)
        display.insert_agent_text()

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

    it("handles multiple multiline blocks but buffer isn't overflown", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "function test()",
            "  if test then",
            "",
            "  end",
            "  print('not generated')",
            "end",
            "",
            "",
            "",
            "",
            "",
            "",
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

        render.show_agent_response(generated, suffix)
        display.insert_agent_text()

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
            "end",
            "",
            "",
            "",
            "",
            "",
            "",
        }, lines)
    end)

    it("handles realistic multiline block, buffer isn't overflown", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "        if values[i] == 0 then",
            "",
            "        end",
            "    end",
            "end",
            "",
            "",
            ""
        })
        vim.api.nvim_win_set_cursor(0, { 2, 0 })

        local generated = [[
            return true
        end
    end
    return false]]

        local suffix = {
            "        end",
            "    end",
            "end"
        }
        render.show_agent_response(generated, suffix)
        display.insert_agent_text()

        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

        assert.are.same({
            "        if values[i] == 0 then",
            "            return true",
            "        end",
            "    end",
            "    return false",
            "end",
            "",
            "",
            ""
        }, lines)
    end)
end)
