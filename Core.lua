-- Core.lua - Main addon initialization
-- Note: All modules (BGCommsLogger, BGCommsCommunications, BGCommsLocations, BGCommsUI, BGCommsMacros, Settings) are loaded
-- by WoW before this file runs due to the .toc file load order, so they're available globally

BGComms = {}

-- Log startup (BGCommsLogger is already loaded globally)
if BGCommsLogger then
    BGCommsLogger:Debug("BattlegroundComms Core.lua loaded")
end

function BGComms:Initialize()
    BGCommsLogger:Info("=== BattlegroundComms Initialize Started ===")

    -- Initialize SavedVariables
    BGCommsDB = BGCommsDB or {}
    BGCommsCharDB = BGCommsCharDB or {}
    BGCommsLogger:Debug("SavedVariables initialized")

    -- Initialize SavedVariables defaults
    BGCommsDB.chatChannel = BGCommsDB.chatChannel or "PARTY"
    -- Migrate old channel values
    if BGCommsDB.chatChannel == "INSTANCE" or BGCommsDB.chatChannel == "BATTLEGROUND" then
        BGCommsDB.chatChannel = "INSTANCE_CHAT"
    end
    BGCommsDB.windowX = BGCommsDB.windowX or 0     -- Centered horizontally
    BGCommsDB.windowY = BGCommsDB.windowY or -800  -- 800px above center
    BGCommsDB.isLocked = BGCommsDB.isLocked or false
    BGCommsDB.backgroundOpacity = BGCommsDB.backgroundOpacity or 0.5
    BGCommsDB.useSmartChannelDetection = BGCommsDB.useSmartChannelDetection ~= false
    BGCommsDB.settingsPanelX = BGCommsDB.settingsPanelX or -100
    BGCommsDB.settingsPanelY = BGCommsDB.settingsPanelY or 0
    BGCommsDB.minimapIconX = BGCommsDB.minimapIconX or 0
    BGCommsDB.minimapIconY = BGCommsDB.minimapIconY or 0
    BGCommsCharDB.customMacros = BGCommsCharDB.customMacros or {}
    BGCommsLogger:Debug("SavedVariables defaults set")

    -- Restore chat channel from SavedVariables
    BGCommsLogger:Debug("Restoring chat channel: " .. BGCommsDB.chatChannel)
    BGCommsCommunications:SetChatChannel(BGCommsDB.chatChannel)

    -- Register slash commands (minimal - no frame creation yet)
    SLASH_BGCOMMS1 = "/bgcomms"
    SLASH_BGCOMMS2 = "/bgc"
    SlashCmdList["BGCOMMS"] = function(msg)
        self:HandleSlashCommand(msg)
    end
    BGCommsLogger:Debug("Slash commands registered")

    -- Create minimap icon on startup
    BGCommsUI:CreateMinimapIcon()
    BGCommsLogger:Debug("Minimap icon created on startup")

    BGCommsLogger:Info("=== BattlegroundComms Initialize Complete ===")
    BGCommsLogger:Info("Addon loaded! Use /bgc to open the window.")
end

function BGComms:HandleSlashCommand(msg)
    -- Normalize input: lowercase for comparison
    msg = (msg or ""):lower()

    if msg == "" then
        BGCommsUI:ToggleFrame()
    elseif msg == "help" or msg == "?" then
        self:PrintHelp()
    elseif msg == "hide" then
        BGCommsUI:Hide()
    elseif msg == "show" then
        BGCommsUI:Show()
    elseif msg == "settings" or msg == "config" then
        BGCommsSettingsPanel:ToggleFrame()
    elseif msg == "clear" then
        BGCommsCommunications:SendClear()
    elseif msg == "debug" then
        BGCommsLogger:PrintHistory()
    elseif string.sub(msg, 1, 9) == "loglevel" then
        local levelStr = string.sub(msg, 11):upper():match("%S+")
        if levelStr then
            local level = BGCommsLogger:ParseLogLevel(levelStr)
            BGCommsLogger:SetLogLevel(level)
        else
            BGCommsLogger:Info("Current log level: " .. BGCommsLogger:GetLogLevelName())
            BGCommsLogger:Info("Usage: /bgc loglevel <DEBUG|INFO|WARNING|ERROR|CRITICAL>")
        end
    elseif string.sub(msg, 1, 3) == "inc" then
        local location = string.sub(msg, 5)  -- Everything after "inc "
        BGCommsCommunications:SendIncoming(location)
    elseif string.sub(msg, 1, 7) == "channel" then
        self:HandleChannelCommand(string.sub(msg, 9))  -- Everything after "channel "
    elseif string.sub(msg, 1, 5) == "macro" then
        self:HandleMacroCommand(string.sub(msg, 7))  -- Everything after "macro "
    elseif string.sub(msg, 1, 12) == "smartchannel" then
        self:HandleSmartChannelCommand(string.sub(msg, 14))  -- Everything after "smartchannel "
    else
        BGCommsLogger:Error("Unknown command: /bgc " .. msg)
        BGCommsLogger:Info("Type /bgc help for available commands")
    end
end

function BGComms:PrintHelp()
    BGCommsLogger:Info("Available Commands:")
    BGCommsLogger:Info("/bgc - Toggle main window")
    BGCommsLogger:Info("/bgc show - Show main window")
    BGCommsLogger:Info("/bgc hide - Hide main window")
    BGCommsLogger:Info("/bgc settings - Open settings panel")
    BGCommsLogger:Info("/bgc channel <name> - Set chat channel (SAY/YELL/PARTY/RAID/INSTANCE_CHAT/GUILD)")
    BGCommsLogger:Info("/bgc inc <location> - Send incoming message")
    BGCommsLogger:Info("/bgc clear - Send clear message")
    BGCommsLogger:Info("/bgc smartchannel on|off - Toggle smart channel detection")
    BGCommsLogger:Info("/bgc macro add <name> <msg> - Create macro")
    BGCommsLogger:Info("/bgc macro remove <name> - Delete macro")
    BGCommsLogger:Info("/bgc macro list - List macros")
    BGCommsLogger:Info("/bgc debug - Show debug log")
    BGCommsLogger:Info("/bgc loglevel <DEBUG|INFO|WARNING|ERROR|CRITICAL> - Set log level")
end

function BGComms:HandleChannelCommand(msg)
    local channel = msg:upper():match("%S+")

    if not channel or channel == "" then
        BGCommsLogger:Info("Current channel: " .. BGCommsCommunications:GetChatChannel())
        BGCommsLogger:Info("Usage: /bgc channel <SAY|YELL|PARTY|RAID|INSTANCE_CHAT|GUILD>")
        return
    end

    -- Validate channel
    if channel ~= "SAY" and channel ~= "YELL" and channel ~= "PARTY" and channel ~= "RAID" and channel ~= "INSTANCE_CHAT" and channel ~= "GUILD" then
        BGCommsLogger:Error("Invalid channel: " .. channel)
        BGCommsLogger:Info("Valid channels: SAY, YELL, PARTY, RAID, INSTANCE_CHAT, GUILD")
        return
    end

    BGCommsCommunications:SetChatChannel(channel)
    BGCommsSettingsPanel:UpdateChannelDropdown()
    BGCommsLogger:Info("Channel changed to: " .. channel)
end

function BGComms:HandleSmartChannelCommand(msg)
    local command = msg:lower():match("%S+")

    if command == "on" then
        BGCommsDB.useSmartChannelDetection = true
        BGCommsLogger:Info("Smart channel detection: ON")
    elseif command == "off" then
        BGCommsDB.useSmartChannelDetection = false
        BGCommsLogger:Info("Smart channel detection: OFF")
    else
        local status = BGCommsDB.useSmartChannelDetection and "ON" or "OFF"
        BGCommsLogger:Info("Smart channel detection: " .. status)
        BGCommsLogger:Info("Usage: /bgc smartchannel <on|off>")
    end
end

function BGComms:HandleMacroCommand(msg)
    local command = string.sub(msg, 1, 3)

    if command == "add" then
        -- /bgc macro add <name> <message>
        local remainder = string.sub(msg, 5)
        local spaceIndex = string.find(remainder, " ")
        if not spaceIndex then
            BGCommsLogger:Info("Usage: /bgc macro add <name> <message>")
            return
        end
        local macroName = string.sub(remainder, 1, spaceIndex - 1)
        local macroMessage = string.sub(remainder, spaceIndex + 1)
        BGCommsMacros:AddMacro(macroName, macroMessage)
        BGCommsUI:RefreshUI()
        BGCommsLogger:Info("Macro '" .. macroName .. "' added.")
    elseif command == "rem" then
        -- /bgc macro remove <name>
        local macroName = string.sub(msg, 9)  -- Everything after "remove "
        if macroName == "" then
            BGCommsLogger:Info("Usage: /bgc macro remove <name>")
            return
        end
        if BGCommsMacros:RemoveMacro(macroName) then
            BGCommsUI:RefreshUI()
            BGCommsLogger:Info("Macro '" .. macroName .. "' removed.")
        else
            BGCommsLogger:Warning("Macro '" .. macroName .. "' not found.")
        end
    elseif command == "lis" then
        -- /bgc macro list
        BGCommsMacros:ListMacros()
    else
        BGCommsLogger:Error("Unknown macro command: " .. command)
        BGCommsLogger:Info("Usage: /bgc macro [add <name> <message>|remove <name>|list]")
    end
end

-- Initialize when addon loads
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == "BattlegroundComms" then
        BGCommsLogger:Info("ADDON_LOADED event triggered for BattlegroundComms")
        -- Don't initialize here - wait for PLAYER_LOGIN
    elseif event == "PLAYER_LOGIN" then
        BGCommsLogger:Info("PLAYER_LOGIN event triggered")
        local success, errorMsg = pcall(function()
            BGComms:Initialize()
        end)

        if not success then
            BGCommsLogger:Error("Failed to initialize addon: " .. tostring(errorMsg))
        else
            BGCommsLogger:Info("Addon initialization successful!")
        end

        self:UnregisterEvent("ADDON_LOADED")
        self:UnregisterEvent("PLAYER_LOGIN")
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        -- Check if player entered a battleground and show main frame
        local inBattleground = false
        if C_PvP and C_PvP.IsInBattleground then
            inBattleground = C_PvP.IsInBattleground()
        end

        if inBattleground then
            BGCommsLogger:Info("Battleground detected - showing main frame")
            BGCommsUI:Show()
        end
    end
end)
