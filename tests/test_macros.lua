-- test_macros.lua - Tests for the Macros module

describe("Macros", function()
    local Macros
    local sent_messages = {}

    before_each(function()
        Macros = require("Macros")
        sent_messages = {}

        -- Mock SendChatMessage
        _G.SendChatMessage = function(message, channel)
            table.insert(sent_messages, { message = message, channel = channel })
            return true
        end

        -- Mock BGCommsCharDB
        _G.BGCommsCharDB = { customMacros = {} }

        -- Mock logger
        _G.BGCommsLogger = {
            DEBUG = 10,
            INFO = 20,
            WARNING = 30,
            ERROR = 40,
            CRITICAL = 50,
            Debug = function() end,
            Info = function() end,
            Warning = function() end,
            Error = function() end,
            Critical = function() end,
        }

        -- Mock Communications module
        _G.BGCommsCommunications = {
            SendMessage = function(msg)
                table.insert(sent_messages, { message = msg })
            end
        }
    end)

    describe("AddMacro", function()
        it("should add a custom macro", function()
            Macros:AddMacro("testmacro", "Test Message")
            local macros = Macros:GetMacros()
            assert.is_equal("Test Message", macros["testmacro"])
        end)

        it("should persist to BGCommsCharDB", function()
            Macros:AddMacro("test", "Message")
            assert.is_equal("Message", _G.BGCommsCharDB.customMacros["test"])
        end)

        it("should handle multiple macros", function()
            Macros:AddMacro("macro1", "Message 1")
            Macros:AddMacro("macro2", "Message 2")
            local macros = Macros:GetMacros()
            assert.is_equal("Message 1", macros["macro1"])
            assert.is_equal("Message 2", macros["macro2"])
        end)
    end)

    describe("RemoveMacro", function()
        it("should remove a custom macro", function()
            Macros:AddMacro("test", "Test Message")
            local removed = Macros:RemoveMacro("test")
            assert.is_true(removed)
            local macros = Macros:GetMacros()
            assert.is_nil(macros["test"])
        end)

        it("should return false for non-existent macro", function()
            local removed = Macros:RemoveMacro("nonexistent")
            assert.is_false(removed)
        end)

        it("should update BGCommsCharDB", function()
            Macros:AddMacro("test", "Message")
            Macros:RemoveMacro("test")
            assert.is_nil(_G.BGCommsCharDB.customMacros["test"])
        end)
    end)

    describe("ExecuteMacro", function()
        it("should execute a macro and send its message", function()
            Macros:AddMacro("test", "Test Message")
            local result = Macros:ExecuteMacro("test")
            assert.is_true(result)
            assert.is_equal(1, #sent_messages)
        end)

        it("should return false for non-existent macro", function()
            local result = Macros:ExecuteMacro("nonexistent")
            assert.is_false(result)
        end)

        it("should return false when no message sent", function()
            Macros:AddMacro("empty", "")
            local result = Macros:ExecuteMacro("empty")
            assert.is_false(result)
        end)

        it("should send via Communications module", function()
            Macros:AddMacro("test", "Macro Message")
            Macros:ExecuteMacro("test")
            assert.is_true(#sent_messages > 0)
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

        it("should return macros by name", function()
            Macros:AddMacro("test", "Test Message")
            local macros = Macros:GetMacros()
            assert.is_not_nil(macros["test"])
        end)
    end)

    describe("ListMacros", function()
        it("should return table of macro info", function()
            Macros:AddMacro("macro1", "Message 1")
            Macros:AddMacro("macro2", "Message 2")
            local list = Macros:ListMacros()
            assert.is_true(#list >= 2)
        end)

        it("should handle empty macro list", function()
            local list = Macros:ListMacros()
            assert.is_equal(0, #list)
        end)
    end)

    describe("Macro validation", function()
        it("should not add macro with empty name", function()
            Macros:AddMacro("", "Message")
            local macros = Macros:GetMacros()
            assert.is_nil(macros[""])
        end)

        it("should not execute macro with nil name", function()
            local result = Macros:ExecuteMacro(nil)
            assert.is_false(result)
        end)

        it("should allow macro names with spaces", function()
            Macros:AddMacro("my macro", "Message")
            local macros = Macros:GetMacros()
            assert.is_equal("Message", macros["my macro"])
        end)
    end)
end)
