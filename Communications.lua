-- BGCommsCommunications.lua - Handles sending messages to chat

BGCommsCommunications = {}

-- Chat channel configuration (modify as needed)
BGCommsCommunications.CHAT_CHANNEL = "PARTY"  -- Options: PARTY, RAID, BATTLEGROUND, BGCOMMS, SAY
BGCommsCommunications.BGCOMMS_CHANNEL = "BGCOMMS"  -- Custom channel for inter-addon communication

-- Determine the best channel to use based on current situation
function BGCommsCommunications:GetSmartChannel()
    -- If smart detection is disabled, use configured channel
    if BGCommsDB and not BGCommsDB.useSmartChannelDetection then
        return self.CHAT_CHANNEL
    end

    -- Check if player is in battleground (using C_PvP namespace for WoW 12.0)
    local inBattleground = false
    if C_PvP and C_PvP.IsInBattleground then
        inBattleground = C_PvP.IsInBattleground()
    end

    if inBattleground then
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

    -- Solo - respect user's channel choice if set to SAY, otherwise default to PARTY
    if self.CHAT_CHANNEL == "SAY" then
        return "SAY"
    end
    return "PARTY"
end

function BGCommsCommunications:SendClear()
    -- Format: CLEAR message with triangle icons
    local message = "{triangle}{triangle} CLEAR"
    self:SendMessage(message)
end

function BGCommsCommunications:SendIncoming(location)
    -- Get count/priority
    local count = "0"

    if BGCommsUI and BGCommsUI.currentPriority then
        count = BGCommsUI.currentPriority
    end

    -- Format message with raid marker icons
    local prefix = ""
    if count == "1" or count == "2" then
        prefix = "{star}{star} "
    elseif count == "3" or count == "4" then
        prefix = "{circle}{circle} "
    elseif count == "5+" then
        prefix = "{cross}{cross} "
    end

    local message
    if count == "0" then
        -- No count or prefix for priority 0
        if not location or location == "" then
            message = "INC"
        else
            message = "INC " .. location
        end
    else
        if not location or location == "" then
            message = prefix .. "INC " .. count .. ":"
        else
            message = prefix .. "INC " .. count .. ": " .. location
        end
    end

    self:SendMessage(message)
end

function BGCommsCommunications:SendMessage(message)
    if not message then return end

    -- Use smart channel detection if enabled
    local channel = self:GetSmartChannel()
    local fullMessage = string.format("[BGComms] %s", message)

    SendChatMessage(fullMessage, channel)
end

-- Set the chat channel for future messages
function BGCommsCommunications:SetChatChannel(channelName)
    self.CHAT_CHANNEL = channelName
    -- Persist to SavedVariables if they exist
    if BGCommsDB then
        BGCommsDB.chatChannel = channelName
    end
end

-- Get current chat channel
function BGCommsCommunications:GetChatChannel()
    return self.CHAT_CHANNEL
end
