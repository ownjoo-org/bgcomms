-- Communications.lua - Handles sending messages to chat

local Communications = {}

-- Chat channel configuration (modify as needed)
Communications.CHAT_CHANNEL = "PARTY"  -- Options: PARTY, RAID, BATTLEGROUND, SAY

function Communications:SendClear()
    self:SendMessage("CLEAR")
end

function Communications:SendIncoming(location)
    if not location or location == "" then
        self:SendMessage("INC (no location)")
    else
        self:SendMessage("INC " .. location)
    end
end

function Communications:SendMessage(message)
    if not message then return end

    local channel = self.CHAT_CHANNEL
    local fullMessage = string.format("[BGComms] %s", message)

    SendChatMessage(fullMessage, channel)
end

-- Set the chat channel for future messages
function Communications:SetChatChannel(channelName)
    self.CHAT_CHANNEL = channelName
    -- Persist to SavedVariables if they exist
    if BGCommsDB then
        BGCommsDB.chatChannel = channelName
    end
end

-- Get current chat channel
function Communications:GetChatChannel()
    return self.CHAT_CHANNEL
end

return Communications
