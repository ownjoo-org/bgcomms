-- test_communications.lua - Tests for the Communications module

describe("Communications", function()
    local Communications
    local sent_messages = {}

    before_each(function()
        Communications = require("Communications")
        sent_messages = {}

        -- Mock SendChatMessage to capture calls
        _G.SendChatMessage = function(message, channel)
            table.insert(sent_messages, { message = message, channel = channel })
            return true
        end

        -- Mock logger
        _G.BGCommsLogger = {
            Debug = function() end,
            Error = function() end,
        }

        -- Mock BGCommsUI for priority
        _G.BGCommsUI = {
            currentPriority = "0"
        }
    end)

    describe("SendClear", function()
        it("should send a CLEAR message", function()
            Communications:SendClear()
            assert.is_equal(1, #sent_messages)
            assert.is_true(string.find(sent_messages[1].message, "CLEAR") ~= nil)
        end)

        it("should include triangle icons", function()
            Communications:SendClear()
            assert.is_true(string.find(sent_messages[1].message, "{triangle}") ~= nil)
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

        it("should send INC without location if nil", function()
            Communications:SendIncoming(nil)
            assert.is_equal(1, #sent_messages)
            assert.is_true(string.find(sent_messages[1].message, "INC") ~= nil)
        end)

        it("should add count when priority is set", function()
            _G.BGCommsUI.currentPriority = "2"
            Communications:SendIncoming("Stables")
            assert.is_true(string.find(sent_messages[1].message, "2") ~= nil)
        end)

        it("should add star icons for priority 1-2", function()
            _G.BGCommsUI.currentPriority = "1"
            Communications:SendIncoming("North")
            assert.is_true(string.find(sent_messages[1].message, "{star}") ~= nil)
        end)

        it("should add circle icons for priority 3-4", function()
            _G.BGCommsUI.currentPriority = "3"
            Communications:SendIncoming("South")
            assert.is_true(string.find(sent_messages[1].message, "{circle}") ~= nil)
        end)

        it("should add cross icons for priority 5+", function()
            _G.BGCommsUI.currentPriority = "5+"
            Communications:SendIncoming("East")
            assert.is_true(string.find(sent_messages[1].message, "{cross}") ~= nil)
        end)
    end)

    describe("GetSmartChannel", function()
        it("should respect useSmartChannelDetection flag", function()
            Communications:SetChatChannel("RAID")
            _G.BGCommsDB = { useSmartChannelDetection = false }
            local channel = Communications:GetSmartChannel()
            assert.is_equal("RAID", channel)
        end)

        it("should default to configured channel when smart detection off", function()
            Communications:SetChatChannel("YELL")
            _G.BGCommsDB = { useSmartChannelDetection = false }
            local channel = Communications:GetSmartChannel()
            assert.is_equal("YELL", channel)
        end)

        it("should return party channel as default", function()
            Communications:SetChatChannel("PARTY")
            _G.BGCommsDB = { useSmartChannelDetection = true }
            _G.IsInRaid = function() return false end
            _G.IsInGroup = function() return false end
            local channel = Communications:GetSmartChannel()
            assert.is_equal("PARTY", channel)
        end)
    end)

    describe("SetChatChannel", function()
        it("should change the chat channel", function()
            Communications:SetChatChannel("RAID")
            assert.is_equal("RAID", Communications:GetChatChannel())
        end)

        it("should persist to SavedVariables", function()
            _G.BGCommsDB = {}
            Communications:SetChatChannel("INSTANCE_CHAT")
            assert.is_equal("INSTANCE_CHAT", _G.BGCommsDB.chatChannel)
        end)
    end)

    describe("GetChatChannel", function()
        it("should return the current chat channel", function()
            Communications:SetChatChannel("GUILD")
            assert.is_equal("GUILD", Communications:GetChatChannel())
        end)
    end)

    describe("SendMessage", function()
        it("should send a message via SendChatMessage", function()
            Communications:SendMessage("Test message")
            assert.is_equal(1, #sent_messages)
            assert.is_equal("Test message", sent_messages[1].message)
        end)

        it("should not send if message is nil", function()
            Communications:SendMessage(nil)
            assert.is_equal(0, #sent_messages)
        end)

        it("should use smart channel detection", function()
            Communications:SetChatChannel("PARTY")
            _G.BGCommsDB = { useSmartChannelDetection = true }
            _G.IsInRaid = function() return false end
            _G.IsInGroup = function() return false end
            Communications:SendMessage("Test")
            assert.is_equal("PARTY", sent_messages[1].channel)
        end)

        it("should handle different channel types", function()
            local channels = { "SAY", "YELL", "PARTY", "RAID", "INSTANCE_CHAT", "GUILD" }
            for _, channel in ipairs(channels) do
                sent_messages = {}
                Communications:SetChatChannel(channel)
                Communications:SendMessage("Test")
                assert.is_equal(channel, sent_messages[1].channel)
            end
        end)
    end)
end)
