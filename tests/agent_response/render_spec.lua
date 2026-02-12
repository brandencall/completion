local render = require("completion.agent_response.render")
local display = require("completion.agent_response.display_response")
local helper = require("tests.helper")

describe("render", function()
    local restore_mode
    local restore_schedule

    before_each(function()
        display.clear_text()
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
        render.show_agent_response("ABC", {})

        local ns = vim.api.nvim_get_namespaces()["agent_response"]

        local marks = vim.api.nvim_buf_get_extmarks(
            0,
            ns,
            0,
            -1,
            { details = true }
        )
        assert.is_true(#marks > 0)
        local _, row, col = unpack(marks[1])
        local expected_row = 0
        local expected_col = 5
        assert.are.equal(expected_row, row)
        assert.are.equal(expected_col, col)
    end)

    it("renders correct virtual lines and inline text for multi-block suggestion", function()
        -- Setup buffer
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "function test()",
            "  if test then",
            "",
            "  end",
            "  print('not generated')",
            "end"
        })

        -- Place cursor on blank line (row 3 in editor, 0-based row 2)
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

        -- Call renderer
        render.show_agent_response(generated, suffix)

        -- Flush scheduled calls
        vim.wait(20)

        local ns = vim.api.nvim_get_namespaces()["agent_response"]

        local marks = vim.api.nvim_buf_get_extmarks(
            0,
            ns,
            0,
            -1,
            { details = true }
        )

        -- We expect 7 marks total
        assert.are.equal(7, #marks)

        -- Helper to find a mark at row/col with virt_lines
        local function find_mark(row, col, key)
            for _, mark in ipairs(marks) do
                local _, r, c, details = unpack(mark)
                if r == row and c == col and details[key] then
                    return details
                end
            end
        end

        ------------------------------------------------------------------
        -- ✅ Row 2 (0-based) inline virt_text: print('test1')
        ------------------------------------------------------------------
        local inline_mark = find_mark(2, 0, "virt_text")
        assert(inline_mark, "Inline mark cant be nil")
        assert.are.same(
            { { "    print('test1')", "Comment" } },
            inline_mark.virt_text
        )
        assert.are.equal("inline", inline_mark.virt_text_pos)

        ------------------------------------------------------------------
        -- ✅ Row 2 virt_lines: print('test2')
        ------------------------------------------------------------------
        local virt2 = find_mark(2, 0, "virt_lines")
        assert(virt2, "Virt line 2 cant be nil")
        assert.are.same(
            { { { "    print('test2')", "Comment" } } },
            virt2.virt_lines
        )

        ------------------------------------------------------------------
        -- ✅ Row 3 virt_lines: test3 + test4
        ------------------------------------------------------------------
        local virt3 = find_mark(3, 5, "virt_lines")
        assert(virt3, "Virt line 3 cant be nil")
        assert.are.same(
            {
                { { "  print('test3')", "Comment" } },
                { { "  print('test4')", "Comment" } },
            },
            virt3.virt_lines
        )

        ------------------------------------------------------------------
        -- ✅ Row 4 virt_lines: test5 + test6
        ------------------------------------------------------------------
        local virt4 = find_mark(4, 24, "virt_lines")
        assert(virt4, "Virt line 4 cant be nil")
        assert.are.same(
            {
                { { "  print('test5')", "Comment" } },
                { { "  print('test6')", "Comment" } },
            },
            virt4.virt_lines
        )
    end)
end)
