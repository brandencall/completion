local ts_utils = require("completion.lang.ts_util")
local helper = require("tests.helper")

describe("treesitter (lua)", function()
    local function find_identifier(root, buf, name)
        local query = vim.treesitter.query.parse("lua", [[
      (identifier) @id
    ]])

        for _, node in query:iter_captures(root, buf, 0, -1) do
            local text = vim.treesitter.get_node_text(node, buf)
            if text == name then
                return node
            end
        end
    end

    it("get_function_node(): gets the current function", function()
        local buf, root = helper.parse_lines({
            "local function test()",
            "  local x = 1",
            "  print(x)",
            "end",
        }, "lua")

        -- Get node inside function body
        local query = vim.treesitter.query.parse("lua", [[
            (identifier) @id
        ]])

        local id_node = find_identifier(root, buf, "x")

        assert(id_node)

        local func_node = ts_utils.get_function_node(id_node, "function")

        assert(func_node)
        assert.equals("function_declaration", func_node:type())
    end)

    it("get_current_scope(): returns the enclosing function node", function()
        local buf, root = helper.parse_lines({
            "local function test()",
            "  local x = 10",
            "  print(x)",
            "end",
        }, "lua")

        local id_node = find_identifier(root, buf, "x")
        assert(id_node)

        local scope = ts_utils.get_current_scope(id_node)

        assert(scope)

        assert.equals("block", scope:type())
    end)

    it("get_current_scope(): returns block when inside do-end block", function()
        local buf, root = helper.parse_lines({
            "do",
            "  local y = 5",
            "end",
        }, "lua")

        local id_node = find_identifier(root, buf, "y")
        assert(id_node)

        local scope = ts_utils.get_current_scope(id_node)
        assert(scope)

        assert.equals("block", scope:type())
    end)

    it("get_current_scope(): returns nil if no scope found", function()
        local buf, root = helper.parse_lines({
            "local z = 1",
        }, "lua")

        local id_node = find_identifier(root, buf, "z")
        assert(id_node)

        local scope = ts_utils.get_current_scope(id_node)
        assert.is_nil(scope)
    end)

    it("contains_err_node(): returns false for valid syntax tree", function()
        local _, root = helper.parse_lines({
            "local a = 1",
            "print(a)",
        }, "lua")

        assert.is_false(ts_utils.contains_err_node(root))
    end)

    it("contains_err_node(): returns true when syntax error exists", function()
        local _, root = helper.parse_lines({
            "local a = ", -- incomplete statement → ERROR node
        }, "lua")

        assert.is_true(ts_utils.contains_err_node(root))
    end)

    it("contains_err_node(): returns false for nil node", function()
        assert.is_false(ts_utils.contains_err_node(nil))
    end)
end)

if helper.has_csharp_parser() then
    describe("treesitter (c_sharp)", function()
        local function find_identifier(root, buf, name)
            local query = vim.treesitter.query.parse("c_sharp", [[
              (identifier) @id
            ]])

            for _, node in query:iter_captures(root, buf, 0, -1) do
                local text = vim.treesitter.get_node_text(node, buf)
                if text == name then
                    return node
                end
            end
        end
        it("get_function_node(): gets the current function in the class", function()
            local buf, root = helper.parse_lines({
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
            }, "c_sharp")

            local id_node = find_identifier(root, buf, "x")

            assert(id_node)

            -- Call your function
            local func_node = ts_utils.get_function_node(
                id_node,
                "method_declaration"
            )

            assert(func_node)
            assert.equals("method_declaration", func_node:type())
        end)
        it("get_current_scope(): returns the enclosing block scope", function()
            local buf, root = helper.parse_lines({
                "public class Test {",
                "  public void Method() {",
                "    int x = 10;",
                "  }",
                "}",
            }, "c_sharp")

            local id_node = find_identifier(root, buf, "x")
            assert(id_node)

            local scope = ts_utils.get_current_scope(id_node)
            assert(scope)

            -- In C#, method body is a block node
            assert.equals("block", scope:type())
        end)

        it("get_current_scope(): returns nearest block when nested", function()
            local buf, root = helper.parse_lines({
                "public class Test {",
                "  public void Method() {",
                "    if (true) {",
                "      int y = 5;",
                "    }",
                "  }",
                "}",
            }, "c_sharp")

            local id_node = find_identifier(root, buf, "y")
            assert(id_node)

            local scope = ts_utils.get_current_scope(id_node)
            assert(scope)

            -- Should return inner block, not outer method
            assert.equals("block", scope:type())
        end)

        it("get_current_scope(): returns nil if no scope found", function()
            local buf, root = helper.parse_lines({
                "int z = 5;", -- top-level statement (C# 9+ style)
            }, "c_sharp")

            local id_node = find_identifier(root, buf, "z")
            assert(id_node)

            local scope = ts_utils.get_current_scope(id_node)
            assert.is_nil(scope)
        end)


        it("contains_err_node(): returns false for valid syntax tree", function()
            local _, root = helper.parse_lines({
                "public class Test {",
                "  public void Method() {",
                "    int a = 1;",
                "  }",
                "}",
            }, "c_sharp")

            assert.is_false(ts_utils.contains_err_node(root))
        end)

        it("contains_err_node(): returns true when syntax error exists", function()
            local _, root = helper.parse_lines({
                "public class Test {",
                "  public void Method() {",
                "    int a = ;", -- invalid syntax
                "  }",
                "}",
            }, "c_sharp")

            assert.is_true(ts_utils.contains_err_node(root))
        end)

        it("contains_err_node(): returns false for nil node", function()
            assert.is_false(ts_utils.contains_err_node(nil))
        end)
    end)
else
    describe("treesitter (csharp)", function()
        pending("c_sharp Treesitter parser not installed")
    end)
end
