-- Communications.lua - Handles sending messages to chat

Communications = {}

-- Chat channel configuration (modify as needed)
Communications.CHAT_CHANNEL = "PARTY"  -- Options: PARTY, RAID, BATTLEGROUND, BGCOMMS, SAY
Communications.BGCOMMS_CHANNEL = "BGCOMMS"  -- Custom channel for inter-addon communication

-- Determine the best channel to use based on current situation
function Communications:GetSmartChannel()
    -- If smart detection is disabled, use configured channel
    if BGCommsDB and not BGCommsDB.useSmartChannelDetection then
        return self.CHAT_CHANNEL
    end

    -- Check if player is in battleground
    if IsInBattleground() then
        return self.BGCOMMS_CHANNEL
    end

    -- Check for raid group
    if IsInRaid() then
        return "RAID"
    end

    -- Check for party group
    if IsInGroup() then
        return "PARTY"
    end

    -- Solo - use party as default
    return "PARTY"
end

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

    -- Use smart channel detection if enabled
    local channel = self:GetSmartChannel()
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
