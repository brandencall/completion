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
    for line in buf_state.text:gmatch("[^\r\n]+") do
        table.insert(lines, {
            { line, "Comment" }
        })
    end

    buf_state.mark_id = vim.api.nvim_buf_set_extmark(
        buf_state.buf,
        ns,
        row,
        col,
        {
            virt_text_pos = "overlay",
            virt_lines = lines
        }
    )
end

function M.clear_text()
    if not buf_state.buf then return end
    vim.api.nvim_buf_clear_namespace(buf_state.buf, ns, 0, -1)
    buf_state.mark_id = nil
    buf_state.text = ""
end

return M
