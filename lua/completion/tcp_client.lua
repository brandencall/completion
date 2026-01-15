local socket = require("socket")

local TcpClient = {}
TcpClient.__index = TcpClient

local function send_all(sock, data)
    local total = 0
    while total < #data do
        local sent, err = sock:send(data, total + 1)
        if not sent then
            error(err)
        end
        total = total + sent
    end
end

-- Create 32-bit unsigned int in big-endian (network byte order)
local function int32_to_bytes(n)
    return string.char(
        bit.band(bit.rshift(n, 24), 0xff),
        bit.band(bit.rshift(n, 16), 0xff),
        bit.band(bit.rshift(n, 8), 0xff),
        bit.band(n, 0xff)
    )
end

function TcpClient:new(port)
    local client = socket.tcp()
    assert(client:connect("127.0.0.1", port))
    local newObj = { client = client }
    setmetatable(newObj, TcpClient)
    return newObj
end

--- This function is responible for sending prompt requests to agent server. Note
--- suffix is optional
--- @param prompt_request table { type: string, prefix: string, suffix: string }
function TcpClient:send_message(prompt_request)
    local json = {
        type = prompt_request.type,
        prefix = prompt_request.prefix,
        suffix = prompt_request.suffix or ""
    }
    local jsonStr = vim.json.encode(json)

    local len = int32_to_bytes(#jsonStr)

    send_all(self.client, len)
    send_all(self.client, jsonStr)
end

function TcpClient:disconnect()
    self.client:close()
end

return TcpClient
