local Job = require("plenary.job")
local json = vim.json

local RequestManager = {}
RequestManager.__index = RequestManager

local uv = vim.uv

local State = {
    READ_LEN = 0,
    READ_PAYLOAD = 1
}

-- Create 32-bit unsigned int in big-endian (network byte order)
local function int32_to_bytes(n)
    return string.char(
        bit.band(bit.rshift(n, 24), 0xff),
        bit.band(bit.rshift(n, 16), 0xff),
        bit.band(bit.rshift(n, 8), 0xff),
        bit.band(n, 0xff)
    )
end

--- Create a new Request Manager object and connect to the given port
---@param port number Port to connect to
---@return table newObj New Request manager object
function RequestManager:new(port)
    ---@diagnostic disable: undefined-field
    local tcp = uv.new_tcp()
    local obj = {
        tcp = tcp,
        buffer = "",
        state = State.READ_LEN,
        expected_len = 0
    }
    setmetatable(obj, self)
    self.__index = self

    obj.tcp:connect("127.0.0.1", port, function(err)
        if err then
            print("Connection error" .. err)
            return
        end
        obj:_start_read()
    end)

    return obj
end

function RequestManager:_start_read()
    self.tcp:read_start(function(err, chunk)
        if err then
            print("Read error: ", err)
            return
        end
        if chunk then
            self:_read_chunk(chunk)
        end
    end)
end

--- Reads a chunk of data. Will continue to read data if the buffer is less than the expected_len that is
--- passed from the server.
---@param chunk string Chunk of data
function RequestManager:_read_chunk(chunk)
    self.buffer = self.buffer .. chunk
    while true do
        if self.state == State.READ_LEN then
            if #self.buffer >= 4 then
                self:_read_chunk_len()
            else
                break
            end
        end
        if self.state == State.READ_PAYLOAD then
            if #self.buffer >= self.expected_len then
                self:read_chunk_payload()
            else
                break
            end
        end
    end
end

function RequestManager:_read_chunk_len()
    local b1, b2, b3, b4 = self.buffer:byte(1, 4)
    self.expected_len = b1 * 2 ^ 24 + b2 * 2 ^ 16 + b3 * 2 ^ 8 + b4
    self.buffer = self.buffer:sub(5)
    self.state = State.READ_PAYLOAD
end

function RequestManager:read_chunk_payload()
    local payload = self.buffer:sub(1, self.expected_len)
    self.buffer = self.buffer:sub(self.expected_len + 1)
    self.state = State.READ_LEN
    vim.schedule(function()
        vim.api.nvim_exec_autocmds("User", {
            pattern = "AgentResponse",
            data = { response = payload },
        })
    end)
end

--- This function is responible for sending prompt requests to agent server.
--- @param prompt_request PromptRequest
function RequestManager:send_message_json(prompt_request)
    local jsonStr = vim.json.encode(prompt_request)

    local len = int32_to_bytes(#jsonStr)
    self.tcp:write(len .. jsonStr)
end

function RequestManager:send_message_string(prompt_request)
    local len = int32_to_bytes(#prompt_request)
    self.tcp:write(len .. prompt_request)
end

function RequestManager:disconnect()
    self.tcp:close()
end

return RequestManager
