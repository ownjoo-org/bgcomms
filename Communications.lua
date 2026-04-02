-- BGCommsCommunications.lua - Handles sending messages to chat

BGCommsCommunications = {}

-- Chat channel configuration (modify as needed)
-- Valid channels: SAY, YELL, PARTY, RAID, INSTANCE (battleground), GUILD
BGCommsCommunications.CHAT_CHANNEL = "PARTY"

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
        return "BGCOMMS"  -- Custom inter-addon battleground chat channel
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
    -- Get current location
    local location = BGCommsLocations:GetPlayerLocation()

    -- Format: CLEAR message with triangle icons and location
    local message = "{triangle}{triangle} CLEAR: " .. location
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
    elseif count == "0" then
        prefix = "{square}{square} "
    end

    -- Format count with consistent width (left-aligned, width 2)
    -- Use ? as placeholder for priority 0
    local displayCount = count
    if count == "0" then
        displayCount = "?"
    end
    -- Pad to 2 characters: "1 ", "?", "5+" all become 2 chars wide
    local paddedCount = string.format("%-2s", displayCount)

    local message
    if count == "0" then
        -- Priority 0 with square icons
        if not location or location == "" then
            message = prefix .. "INC"
        else
            message = prefix .. "INC " .. paddedCount .. ": " .. location
        end
    else
        if not location or location == "" then
            message = prefix .. "INC " .. paddedCount .. ":"
        else
            message = prefix .. "INC " .. paddedCount .. ": " .. location
        end
    end

    self:SendMessage(message)
end

function BGCommsCommunications:SendFlagStatus(status, location)
    -- Format flag status messages with diamond icons
    local statusText = ""
    if status == "SECURE" then
        statusText = "FLAG SECURE"
    elseif status == "TAKEN" then
        statusText = "FLAG TAKEN"
    elseif status == "DROPPED" then
        statusText = "FLAG DROPPED"
    else
        statusText = "FLAG " .. tostring(status)
    end

    local message
    if location and location ~= "" then
        message = "{diamond}{diamond} " .. statusText .. " : " .. location
    else
        message = "{diamond}{diamond} " .. statusText
    end

    self:SendMessage(message)
end

function BGCommsCommunications:SendBaseStatus(status)
    -- Format base defense messages with triangle icons
    local statusText = ""
    if status == "DEFENDED" then
        statusText = "BASE DEFENDED"
    elseif status == "CLEAR" then
        statusText = "BASE CLEAR"
    elseif status == "UNDER_ATTACK" then
        statusText = "BASE UNDER ATTACK"
    else
        statusText = "BASE " .. tostring(status)
    end

    local message = "{triangle}{triangle} " .. statusText

    self:SendMessage(message)
end

function BGCommsCommunications:SendFlagCarrier(location)
    -- Format flag carrier location message with cross icons
    local message
    if location and location ~= "" then
        message = "{cross}{cross} CARRIER AT : " .. location
    else
        message = "{cross}{cross} CARRIER"
    end

    self:SendMessage(message)
end

function BGCommsCommunications:SendFCRunning(team, direction)
    -- Format FC running direction message
    -- team: "THEIR" or "OUR"
    -- direction: "WEST", "MID", "EAST"
    local directionText = ""
    if direction == "WEST" then
        directionText = "WEST"
    elseif direction == "MID" then
        directionText = "MID"
    elseif direction == "EAST" then
        directionText = "EAST"
    else
        directionText = tostring(direction)
    end

    local teamText = team:upper()
    local message = "{cross}{cross} " .. teamText .. " FC RUNNING " .. directionText

    self:SendMessage(message)
end

function BGCommsCommunications:SendINCFlagRoom()
    -- Format INC flag room message
    local message = "{diamond}{diamond} INC FLAG ROOM"
    self:SendMessage(message)
end

function BGCommsCommunications:SendFCNeedsHelp()
    -- Format FC needs help message
    local message = "{cross}{cross} FC NEEDS HELP"
    self:SendMessage(message)
end

function BGCommsCommunications:SendMessage(message)
    if not message then return end

    local channel = self:GetSmartChannel()

    BGCommsLogger:Debug("SendMessage: message='" .. message .. "', channel='" .. channel .. "'")

    -- Try SendChatMessage with string parameters (old API)
    -- Parameters: text, chatType, language, channel
    local success, result = pcall(function()
        return SendChatMessage(message, channel, nil, nil)
    end)

    if success then
        BGCommsLogger:Debug("Sent via " .. channel .. ": " .. message)
    else
        BGCommsLogger:Error("SendChatMessage failed: " .. tostring(result))
    end
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
