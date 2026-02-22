local ts_utils = require("completion.lang.ts_util")
local helper = require("tests.helper")

describe("treesitter (lua)", function()
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

        local id_node = helper.find_identifier(root, buf, "x", "lua")

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

        local id_node = helper.find_identifier(root, buf, "x", "lua")
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

        local id_node = helper.find_identifier(root, buf, "y", "lua")
        assert(id_node)

        local scope = ts_utils.get_current_scope(id_node)
        assert(scope)

        assert.equals("block", scope:type())
    end)

    it("get_current_scope(): returns nil if no scope found", function()
        local buf, root = helper.parse_lines({
            "local z = 1",
        }, "lua")

        local id_node = helper.find_identifier(root, buf, "z", "lua")
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

if helper.has_parser("c_sharp") then
    describe("treesitter (c_sharp)", function()
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

            local id_node = helper.find_identifier(root, buf, "x", "c_sharp")

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

            local id_node = helper.find_identifier(root, buf, "x", "c_sharp")
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

            local id_node = helper.find_identifier(root, buf, "y", "c_sharp")
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

            local id_node = helper.find_identifier(root, buf, "z", "c_sharp")
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

if helper.has_parser("cpp") then
    describe("treesitter (cpp)", function()
        it("get_function_node(): gets the current function in the class", function()
            local buf, root = helper.parse_lines({
                "#include <iostream>",
                "",
                "class TestClass {",
                "public:",
                "    void TestMethod() {",
                "        int x = 42;",
                "        std::cout << x;",
                "    }",
                "};",
            }, "cpp")

            local id_node = helper.find_identifier(root, buf, "x", "cpp")
            assert(id_node)

            local func_node = ts_utils.get_function_node(
                id_node,
                "function_definition"
            )

            assert(func_node)
            assert.equals("function_definition", func_node:type())
        end)

        it("get_current_scope(): returns the enclosing compound_statement", function()
            local buf, root = helper.parse_lines({
                "class Test {",
                "public:",
                "  void Method() {",
                "    int x = 10;",
                "  }",
                "};",
            }, "cpp")

            local id_node = helper.find_identifier(root, buf, "x", "cpp")
            assert(id_node)

            local scope = ts_utils.get_current_scope(id_node)
            assert(scope)

            assert.equals("function_definition", scope:type())
        end)

        it("get_current_scope(): returns nearest compound_statement when nested", function()
            local buf, root = helper.parse_lines({
                "class Test {",
                "public:",
                "  void Method() {",
                "    if (true) {",
                "      int y = 5;",
                "    }",
                "  }",
                "};",
            }, "cpp")

            local id_node = helper.find_identifier(root, buf, "y", "cpp")
            assert(id_node)

            local scope = ts_utils.get_current_scope(id_node)
            assert(scope)

            assert.equals("function_definition", scope:type())
        end)

        it("get_current_scope(): returns nil if no compound scope found", function()
            local buf, root = helper.parse_lines({
                "int z = 5;",
            }, "cpp")

            local id_node = helper.find_identifier(root, buf, "z", "cpp")
            assert(id_node)

            local scope = ts_utils.get_current_scope(id_node)

            -- No compound_statement at top level
            assert.is_nil(scope)
        end)

        it("contains_err_node(): returns false for valid syntax tree", function()
            local _, root = helper.parse_lines({
                "class Test {",
                "public:",
                "  void Method() {",
                "    int a = 1;",
                "  }",
                "};",
            }, "cpp")

            assert.is_false(ts_utils.contains_err_node(root))
        end)

        it("contains_err_node(): returns true when syntax error exists", function()
            local _, root = helper.parse_lines({
                "class Test {",
                "public:",
                "  void Method() {",
                "    int a = ;", -- invalid syntax
                "  }",
                "};",
            }, "cpp")

            assert.is_true(ts_utils.contains_err_node(root))
        end)

        it("contains_err_node(): returns false for nil node", function()
            assert.is_false(ts_utils.contains_err_node(nil))
        end)
    end)
else
    describe("treesitter (cpp)", function()
        pending("cpp Treesitter parser not installed")
    end)
end
