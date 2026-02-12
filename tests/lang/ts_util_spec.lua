local ts_utils = require("completion.lang.ts_util")
vim.opt.runtimepath:append(
    vim.fn.stdpath("data") .. "/lazy/nvim-treesitter"
)

local function has_csharp_parser()
    local data = vim.fn.stdpath("data")

    -- Add lazy treesitter path if it exists
    local ts_path = data .. "/lazy/nvim-treesitter"
    if vim.loop.fs_stat(ts_path) then
        vim.opt.runtimepath:append(ts_path)
    end

    local parsers = vim.api.nvim_get_runtime_file("parser/c_sharp.so", false)
    return #parsers > 0
end

describe("treesitter (lua)", function()
    it("finds the parent function node", function()
        -- Create scratch buffer
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_set_current_buf(buf)

        -- Set filetype so treesitter loads parser
        vim.bo[buf].filetype = "lua"

        -- Insert test code
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
            "local function test()",
            "  local x = 1",
            "  print(x)",
            "end",
        })

        -- Parse
        local parser = vim.treesitter.get_parser(buf, "lua")
        local tree = parser:parse()[1]
        local root = tree:root()

        -- Get node inside function body
        local query = vim.treesitter.query.parse("lua", [[
            (identifier) @id
        ]])

        local found_node
        for _, node in query:iter_captures(root, buf, 0, -1) do
            if vim.treesitter.get_node_text(node, buf) == "x" then
                found_node = node
                break
            end
        end

        assert(found_node)

        -- Call your function
        local func_node = ts_utils.get_function_node(found_node, "function")

        assert(func_node)
        assert.equals("function_declaration", func_node:type())
    end)
end)

if has_csharp_parser() then
    describe("treesitter (c_sharp)", function()
        it("finds the parent function node", function()
            local buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_set_current_buf(buf)

            -- Set filetype so treesitter loads parser
            vim.bo[buf].filetype = "cs"

            -- Insert C# test code
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
                "using System;",
                "",
                "public class TestClass",
                "{",
                "    public void TestMethod()",
                "    {",
                "        int x = 42;",
                "        Console.WriteLine(x);",
                "    }",
                "}",
            })

            -- Parse
            local parser = vim.treesitter.get_parser(buf, "c_sharp")
            local tree = parser:parse()[1]
            local root = tree:root()

            -- Query for identifier "x"
            local query = vim.treesitter.query.parse("c_sharp", [[
            (identifier) @id
        ]])

            local target_node
            for _, node in query:iter_captures(root, buf, 0, -1) do
                local text = vim.treesitter.get_node_text(node, buf)
                if text == "x" then
                    target_node = node
                    break
                end
            end

            assert(target_node)

            -- Call your function
            local func_node = ts_utils.get_function_node(
                target_node,
                "method_declaration"
            )

            assert(func_node)
            assert.equals("method_declaration", func_node:type())
        end)
    end)
else
    describe("treesitter (csharp)", function()
        pending("c_sharp Treesitter parser not installed")
    end)
end
