-- test_macros.lua - Tests for the Macros module

describe("Macros", function()
    local Macros
    local sent_messages = {}

    before_each(function()
        Macros = require("Macros")
        sent_messages = {}

        -- Mock SendChatMessage and BGCommsCharDB
        _G.SendChatMessage = function(message, channel)
            table.insert(sent_messages, { message = message, channel = channel })
        end
        _G.BGCommsCharDB = { customMacros = {} }
    end)

    describe("AddMacro", function()
        it("should add a custom macro", function()
            Macros:AddMacro("test", "Test Message")
            local macros = Macros:GetMacros()
            assert.is_equal("Test Message", macros["test"])
        end)
    end)

    describe("RemoveMacro", function()
        it("should remove a custom macro", function()
            Macros:AddMacro("test", "Test Message")
            Macros:RemoveMacro("test")
            local macros = Macros:GetMacros()
            assert.is_nil(macros["test"])
        end)
    end)

    describe("ExecuteMacro", function()
        it("should execute a macro and send its message", function()
            Macros:AddMacro("test", "Test Message")
            Macros:ExecuteMacro("test")
            assert.is_equal(1, #sent_messages)
            assert.is_true(string.find(sent_messages[1].message, "Test Message") ~= nil)
        end)

        it("should return false for non-existent macro", function()
            local result = Macros:ExecuteMacro("nonexistent")
            assert.is_false(result)
        end)
    end)

    describe("GetMacros", function()
        it("should return empty table if no macros exist", function()
            local macros = Macros:GetMacros()
            assert.is_equal(0, #macros)
        end)

        it("should return all stored macros", function()
            Macros:AddMacro("macro1", "Message 1")
            Macros:AddMacro("macro2", "Message 2")
            local macros = Macros:GetMacros()
            assert.is_equal("Message 1", macros["macro1"])
            assert.is_equal("Message 2", macros["macro2"])
        end)
    end)
end)
