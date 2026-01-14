local socket = require("socket")
local bit = require("bit")


local M = {}

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

local function int32_to_bytes(n)
    return string.char(
        bit.band(bit.rshift(n, 24), 0xff),
        bit.band(bit.rshift(n, 16), 0xff),
        bit.band(bit.rshift(n, 8), 0xff),
        bit.band(n, 0xff)
    )
end

function M.send_message(msg)
    local client = socket.tcp()
    assert(client:connect("127.0.0.1", 22222))

    local len = int32_to_bytes(#msg)

    send_all(client, len)
    send_all(client, msg)

    client:close()
end

return M
