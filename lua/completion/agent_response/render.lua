local state = require("completion.state_manager")

local M = {}
local function create_anchor_extmark(row, col)
    state.BufferState.anchor_mark_id = vim.api.nvim_buf_set_extmark(
        state.BufferState.buf,
        state.BufferState.ns,
        row,
        col,
        { right_gravity = false }
    )
end

---@class mark
---@field firstLine table
---@field lines table
---@field col integer

---@param row integer
---@param col integer
---@param suffix table
---@return table<integer, mark> marks Mapping of row to mark
function M.create_extmarks_for_render(row, col, suffix)
    local suffix_match_idx = 1
    local render_row = row
    local actual_row = row
    local marks = {}
    local rendered_chunk_sum = 0

    for line in state.BufferState.text:gmatch("[^\r\n]+") do
        if line == suffix[suffix_match_idx] then
            -- Nil check needed for marks!
            local prev_render_chunk_len = #marks[render_row].firstLine + #marks[render_row].lines
            rendered_chunk_sum = rendered_chunk_sum + prev_render_chunk_len
            -- The actual row is the current render_row + the previous chunk that was rendered
            actual_row = render_row + rendered_chunk_sum
            suffix_match_idx = suffix_match_idx + 1
            render_row = render_row + 1
            marks[render_row] = {
                firstLine = {},
                lines = {},
                col = vim.fn.strlen(vim.fn.getline(render_row + 1)),
            }
            goto continue
        end
        if not marks[row] then
            marks[row] = {
                firstLine = {},
                lines = {},
                col = col,
            }
            table.insert(marks[row].firstLine, {
                { line, "Comment" }
            })
        else
            table.insert(marks[render_row].lines, {
                { line, "Comment" }
            })
        end
        if not state.BufferState.insert_plan[actual_row] then
            state.BufferState.insert_plan[actual_row] = {}
        end

        table.insert(state.BufferState.insert_plan[actual_row], line)
        ::continue::
    end
    return marks
end

---@param marks table<integer, mark> Mapping of row to mark
local function set_extmarks_for_render(marks)
    for mark_row, mark in pairs(marks) do
        if mark.firstLine then
            vim.api.nvim_buf_set_extmark(
                state.BufferState.buf,
                state.BufferState.ns,
                mark_row,
                mark.col,
                {
                    virt_text = mark.firstLine[1],
                    virt_text_pos = "inline",
                    hl_mode = "combine"
                }
            )
        end
        vim.api.nvim_buf_set_extmark(
            state.BufferState.buf,
            state.BufferState.ns,
            mark_row,
            mark.col,
            {
                virt_lines = mark.lines,
            }
        )
    end
end

--- Shows the agent response as virtual text. Accumulates the text overtime for streamming and rerenders
--- the virtual text. Should only ever show the text while in insert mode
---@param text string
---@param suffix table
function M.show_agent_response(text, suffix)
    if vim.fn.mode() ~= "i" then
        return
    end
    state.BufferState.buf = vim.api.nvim_get_current_buf()
    state.BufferState.text = state.BufferState.text .. text
    state.BufferState.insert_plan = {}

    vim.api.nvim_buf_clear_namespace(state.BufferState.buf, state.BufferState.ns, 0, -1)

    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    row = row - 1 -- extmarks are 0-based

    create_anchor_extmark(row, col)
    local marks = M.create_extmarks_for_render(row, col, suffix)
    set_extmarks_for_render(marks)
end

vim.api.nvim_create_autocmd("User", {
    pattern = "AgentResponse",
    callback = function(event)
        local response = event.data.response
        local suffix = event.data.suffix_table
        M.show_agent_response(response, suffix)
    end,
})

return M
