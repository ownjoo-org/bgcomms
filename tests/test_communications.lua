-- test_communications.lua - Tests for the Communications module

describe("Communications", function()
    local Communications
    local sent_messages = {}

    before_each(function()
        Communications = require("Communications")
        sent_messages = {}

        -- Mock SendChatMessage
        _G.SendChatMessage = function(message, channel)
            table.insert(sent_messages, { message = message, channel = channel })
        end
    end)

    describe("SendClear", function()
        it("should send a CLEAR message", function()
            Communications:SendClear()
            assert.is_equal(1, #sent_messages)
            assert.is_true(string.find(sent_messages[1].message, "CLEAR") ~= nil)
        end)
    end)

    describe("SendIncoming", function()
        it("should send INC with location", function()
            Communications:SendIncoming("Stables")
            assert.is_equal(1, #sent_messages)
            assert.is_true(string.find(sent_messages[1].message, "INC") ~= nil)
            assert.is_true(string.find(sent_messages[1].message, "Stables") ~= nil)
        end)

        it("should send INC without location if empty", function()
            Communications:SendIncoming("")
            assert.is_equal(1, #sent_messages)
            assert.is_true(string.find(sent_messages[1].message, "INC") ~= nil)
        end)
    end)

    describe("SetChatChannel", function()
        it("should change the chat channel", function()
            Communications:SetChatChannel("RAID")
            assert.is_equal("RAID", Communications:GetChatChannel())
        end)
    end)

    describe("SendMessage", function()
        it("should include prefix", function()
            Communications:SendMessage("Test")
            assert.is_true(string.find(sent_messages[1].message, "[BGComms]") ~= nil)
        end)

        it("should not send if message is nil", function()
            Communications:SendMessage(nil)
            assert.is_equal(0, #sent_messages)
        end)
    end)
end)
