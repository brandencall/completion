local d = require("completion.debug")
local M = {}

local ns = vim.api.nvim_create_namespace("agent_response")

local buf_state = {
    buf = nil,
    anchor_mark_id = nil,
    text = "",
    insert_plan = {}
}

function M.clear_text()
    if not buf_state.buf then return end
    vim.api.nvim_buf_clear_namespace(buf_state.buf, ns, 0, -1)
    buf_state.anchor_mark_id = nil
    buf_state.text = ""
    buf_state.insert_plan = nil
end

local function create_anchor_extmark(row, col)
    buf_state.anchor_mark_id = vim.api.nvim_buf_set_extmark(
        buf_state.buf,
        ns,
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

    for line in buf_state.text:gmatch("[^\r\n]+") do
        if line == suffix[suffix_match_idx] then
            local prev_render_chunk_len = #marks[render_row].firstLine + #marks[render_row].lines
            rendered_chunk_sum = rendered_chunk_sum + prev_render_chunk_len
            -- The actual row is the current render_row + the previous chunk that was rendered
            -- plus the offset of the amount of matching suffix (offset by 1)
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
        if not buf_state.insert_plan[actual_row] then
            buf_state.insert_plan[actual_row] = {}
        end

        table.insert(buf_state.insert_plan[actual_row], line)
        ::continue::
    end
    return marks
end

---@param marks table<integer, mark> Mapping of row to mark
local function set_extmarks_for_render(marks)
    for mark_row, mark in pairs(marks) do
        if mark.firstLine then
            vim.api.nvim_buf_set_extmark(
                buf_state.buf,
                ns,
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
            buf_state.buf,
            ns,
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
    buf_state.buf = vim.api.nvim_get_current_buf()
    buf_state.text = buf_state.text .. text
    buf_state.insert_plan = {}

    vim.api.nvim_buf_clear_namespace(buf_state.buf, ns, 0, -1)

    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    row = row - 1 -- extmarks are 0-based

    create_anchor_extmark(row, col)
    local marks = M.create_extmarks_for_render(row, col, suffix)
    set_extmarks_for_render(marks)
end

---@param row integer
---@param col integer
---@param lines table
---@return integer, integer (last_row_set last_col_set) returns the last row that was set and the column
function M.set_text_first_row(row, col, lines)
    local last_row_set = -1
    local last_col_set = -1

    local start_row = row
    local line_count = #lines

    local line = vim.api.nvim_buf_get_lines(
        buf_state.buf,
        row,
        row + 1,
        false
    )[1] or ""

    if col > #line then
        col = 0
    end

    local start_col = col
    local last_line = lines[#lines]
    vim.schedule(function()
        vim.api.nvim_buf_set_text(
            buf_state.buf,
            row,
            col,
            row,
            col,
            lines
        )
    end)
    last_row_set = start_row + line_count

    if line_count == 1 then
        last_col_set = start_col + vim.fn.strlen(last_line)
    else
        last_col_set = vim.fn.strlen(last_line)
    end
    return last_row_set, last_col_set
end

--- Inserts N blank lines at the end of the current buffer.
--- @param n integer The number of blank lines to insert.
local function insert_blank_lines_end_of_buffer(n)
    local lines_to_insert = {}
    -- Create a table with 'n' empty strings, each representing a new line.
    for _ = 1, n do
        table.insert(lines_to_insert, "")
    end

    -- Use 0 for the current buffer, -1 as both the start and end line to append at the end of the buffer.
    vim.api.nvim_buf_set_lines(buf_state.buf, -1, -1, false, lines_to_insert)
end

---@param row integer
---@param lines table
---@return integer, integer (last_row_set last_col_set) returns the last row that was set and the column
function M.set_text(row, lines)
    local last_row_set = -1
    local last_col_set = -1

    local start_row = row + 1
    local line_count = #lines + 1

    local last_line = lines[#lines]
    local buffer_count = vim.api.nvim_buf_line_count(buf_state.buf)

    if start_row >= buffer_count then
        insert_blank_lines_end_of_buffer(start_row - buffer_count)
        start_row = start_row - 1
    end
    vim.schedule(function()
        table.insert(lines, "")
        vim.api.nvim_buf_set_text(
            buf_state.buf,
            start_row,
            0,
            start_row,
            0,
            lines
        )
        table.remove(lines)
    end)
    last_row_set = start_row + line_count - 1
    last_col_set = vim.fn.strlen(last_line)

    return last_row_set, last_col_set
end

function M.insert_agent_text()
    if not buf_state.buf or not buf_state.insert_plan then
        return
    end

    local _, col = unpack(
        vim.api.nvim_buf_get_extmark_by_id(buf_state.buf, ns, buf_state.anchor_mark_id, {})
    )

    local rows = {}
    for r, _ in pairs(buf_state.insert_plan) do
        table.insert(rows, r)
    end
    table.sort(rows, function(a, b) return a < b end) -- bottom-up

    vim.api.nvim_buf_call(buf_state.buf, function()
        vim.cmd("undojoin")
    end)

    local last_row_set = -1
    local last_col_set = -1

    for i, row in ipairs(rows) do
        local lines = buf_state.insert_plan[row]
        if #lines > 0 then
            if i == 1 then
                last_row_set, last_col_set = M.set_text_first_row(row, col, lines)
            else
                last_row_set, last_col_set = M.set_text(row, lines)
            end
        end
    end

    vim.schedule(function()
        vim.api.nvim_win_set_cursor(0, { last_row_set, last_col_set })
    end)

    M.clear_text();
    return ""
end

--vim.keymap.set('i', '<Tab>', M.insert_agent_text, { expr = true, silent = true })

vim.keymap.set('i', '<Tab>', function()
    if buf_state.text ~= "" then
        M.insert_agent_text()
        return ""
    end
    return "<Tab>"
end, { expr = true, silent = true })

vim.api.nvim_create_autocmd("User", {
    pattern = "AgentResponse",
    callback = function(event)
        local response = event.data.response
        local suffix = event.data.suffix_table
        M.show_agent_response(response, suffix)
    end,
})

vim.api.nvim_create_autocmd("User", {
    pattern = "IdleState",
    callback = function()
        M.clear_text()
    end
})

vim.api.nvim_create_autocmd("User", {
    pattern = "UserTyping",
    callback = function()
        M.clear_text()
    end
})

vim.api.nvim_create_autocmd("User", {
    pattern = "AgentRequest",
    callback = function()
        M.clear_text()
    end
})

vim.api.nvim_create_autocmd("User", {
    pattern = "PluginDisabled",
    callback = function()
        M.clear_text()
    end,
})

return M
