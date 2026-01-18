local M = {}

local ns = vim.api.nvim_create_namespace("agent_response")
local buf_state = {
    buf = nil,
    mark_id = nil,
    text = "",
}

--- Shows the agent response as virtual text. Accumulates the text overtime for streamming and rerenders
--- the virtual text
---@param text string
function M.show_agent_response(text)
    buf_state.buf = vim.api.nvim_get_current_buf()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    row = row - 1 -- extmarks are 0-based
    buf_state.text = buf_state.text .. text

    vim.api.nvim_buf_clear_namespace(buf_state.buf, ns, 0, -1)

    local lines = {}
    local firstLine = {}
    for line in buf_state.text:gmatch("[^\r\n]+") do
        if #firstLine == 0 then
            table.insert(firstLine, {
                { line, "Comment" }
            })
        else
            table.insert(lines, {
                { line, "Comment" }
            })
        end
    end
    buf_state.mark_id = vim.api.nvim_buf_set_extmark(
        buf_state.buf,
        ns,
        row,
        col,
        {
            virt_text = firstLine[1],
            virt_text_pos = "inline",
            hl_mode = "combine"
        }
    )
    buf_state.mark_id = vim.api.nvim_buf_set_extmark(
        buf_state.buf,
        ns,
        row,
        col,
        {
            virt_lines = lines,
        }
    )
end

function M.clear_text()
    if not buf_state.buf then return end
    vim.api.nvim_buf_clear_namespace(buf_state.buf, ns, 0, -1)
    buf_state.mark_id = nil
    buf_state.text = ""
end

local function insert_agent_text()
    if buf_state.text == "" or not buf_state.mark_id then
        return
    end
    local row, col = unpack(
        vim.api.nvim_buf_get_extmark_by_id(buf_state.buf, ns, buf_state.mark_id, {})
    )

    local lines = vim.split(buf_state.text, "\n", { plain = true })

    vim.api.nvim_buf_set_text(
        buf_state.buf,
        row,
        col,
        row,
        col,
        lines
    )
    M.clear_text()
end

-- NEED TO CHANGE THIS TO BE INSERT MODE
vim.keymap.set('n', '<Tab>', function()
    insert_agent_text()
end)

return M
