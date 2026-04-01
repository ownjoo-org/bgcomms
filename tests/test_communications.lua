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

        -- Mock logger with all methods
        _G.BGCommsLogger = {
            NOTSET = 0,
            DEBUG = 10,
            INFO = 20,
            WARNING = 30,
            ERROR = 40,
            CRITICAL = 50,
            currentLevel = 30,
            history = {},
            Debug = function(self, msg) table.insert(self.history, msg) end,
            Info = function(self, msg) table.insert(self.history, msg) end,
            Warning = function(self, msg) table.insert(self.history, msg) end,
            Error = function(self, msg) table.insert(self.history, msg) end,
            Critical = function(self, msg) table.insert(self.history, msg) end,
            SetLogLevel = function(self, level) self.currentLevel = level end,
            GetLogLevelName = function(self) return "WARNING" end,
            ParseLogLevel = function(self, str) return 30 end,
        }

        -- Mock BGCommsUI for priority
        _G.BGCommsUI = {
            currentPriority = "0"
        }

        -- Mock BGCommsLocations for location detection
        _G.BGCommsLocations = {
            GetPlayerLocation = function() return "Stables" end
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

        it("should include current location", function()
            Communications:SendClear()
            assert.is_true(string.find(sent_messages[1].message, "Stables") ~= nil)
        end)

        it("should have colon after CLEAR", function()
            Communications:SendClear()
            assert.is_true(string.find(sent_messages[1].message, "CLEAR:") ~= nil)
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

        it("should add square icons for priority 0", function()
            _G.BGCommsUI.currentPriority = "0"
            Communications:SendIncoming("West")
            assert.is_true(string.find(sent_messages[1].message, "{square}") ~= nil)
        end)

        it("should have colon between INC and location when location provided", function()
            Communications:SendIncoming("Stables")
            assert.is_true(string.find(sent_messages[1].message, "INC:") ~= nil)
        end)

        it("should use ? placeholder for priority 0", function()
            _G.BGCommsUI.currentPriority = "0"
            Communications:SendIncoming("Stables")
            assert.is_true(string.find(sent_messages[1].message, "?") ~= nil)
        end)

        it("should have fixed-width count formatting", function()
            _G.BGCommsUI.currentPriority = "1"
            Communications:SendIncoming("Stables")
            -- Check for fixed-width format (count is right-aligned with width 2)
            assert.is_true(string.find(sent_messages[1].message, " 1") ~= nil)
        end)

        it("should handle 5+ with fixed width", function()
            _G.BGCommsUI.currentPriority = "5+"
            Communications:SendIncoming("Stables")
            -- 5+ is already 2 chars wide, should appear as-is
            assert.is_true(string.find(sent_messages[1].message, "5+") ~= nil)
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
