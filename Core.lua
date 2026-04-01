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
    print("|cFF00FF00Addon loaded! Use /bgc to open the window.")
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
    elseif string.sub(msg, 1, 10) == "debug_mode" then
        local mode = string.sub(msg, 12):lower()
        if mode == "on" then
            BGCommsLogger:SetDebugMode(true)
        elseif mode == "off" then
            BGCommsLogger:SetDebugMode(false)
        else
            print("|cFF00FF00Usage: /bgc debug_mode <on|off>")
        end
    elseif msg == "exportlog" then
        BGCommsLogger:ExportDebugLog()
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
        print("|cFF00FF00Unknown command: /" .. msg)
        print("|cFF00FF00Type /bgc help for available commands")
    end
end

function BGComms:PrintHelp()
    print("|cFF00FF00Available Commands:")
    print("|cFFFFFF00/bgc|r - Toggle main window")
    print("|cFFFFFF00/bgc show|r - Show main window")
    print("|cFFFFFF00/bgc hide|r - Hide main window")
    print("|cFFFFFF00/bgc settings|r - Open settings panel")
    print("|cFFFFFF00/bgc channel <name>|r - Set chat channel (SAY/YELL/PARTY/RAID/BATTLEGROUND/GUILD)")
    print("|cFFFFFF00/bgc inc <location>|r - Send incoming message")
    print("|cFFFFFF00/bgc clear|r - Send clear message")
    print("|cFFFFFF00/bgc smartchannel on|off|r - Toggle smart channel detection")
    print("|cFFFFFF00/bgc macro add <name> <msg>|r - Create macro")
    print("|cFFFFFF00/bgc macro remove <name>|r - Delete macro")
    print("|cFFFFFF00/bgc macro list|r - List macros")
    print("|cFFFFFF00/bgc debug|r - Show debug log")
    print("|cFFFFFF00/bgc debug_mode on|off|r - Enable/disable debug logging to disk")
    print("|cFFFFFF00/bgc exportlog|r - Export debug log from disk")
end

function BGComms:HandleChannelCommand(msg)
    local channel = msg:upper():match("%S+")

    if not channel or channel == "" then
        print("|cFF00FF00Current channel: " .. BGCommsCommunications:GetChatChannel())
        print("|cFF00FF00Usage: /bgc channel <SAY|YELL|PARTY|RAID|BATTLEGROUND|GUILD>")
        return
    end

    -- Validate channel
    if channel ~= "SAY" and channel ~= "YELL" and channel ~= "PARTY" and channel ~= "RAID" and channel ~= "BATTLEGROUND" and channel ~= "GUILD" then
        print("|cFF00FF00Invalid channel: " .. channel)
        print("|cFF00FF00Valid channels: SAY, YELL, PARTY, RAID, BATTLEGROUND, GUILD")
        return
    end

    BGCommsCommunications:SetChatChannel(channel)
    BGCommsSettingsPanel:UpdateChannelDropdown()
    print("|cFF00FF00Channel changed to: " .. channel)
end

function BGComms:HandleSmartChannelCommand(msg)
    local command = msg:lower():match("%S+")

    if command == "on" then
        BGCommsDB.useSmartChannelDetection = true
        print("|cFF00FF00Smart channel detection: ON")
    elseif command == "off" then
        BGCommsDB.useSmartChannelDetection = false
        print("|cFF00FF00Smart channel detection: OFF")
    else
        local status = BGCommsDB.useSmartChannelDetection and "ON" or "OFF"
        print("|cFF00FF00Smart channel detection: " .. status)
        print("|cFF00FF00Usage: /bgc smartchannel <on|off>")
    end
end

function BGComms:HandleMacroCommand(msg)
    local command = string.sub(msg, 1, 3)

    if command == "add" then
        -- /bgc macro add <name> <message>
        local remainder = string.sub(msg, 5)
        local spaceIndex = string.find(remainder, " ")
        if not spaceIndex then
            print("|cFF00FF00Usage: /bgc macro add <name> <message>")
            return
        end
        local macroName = string.sub(remainder, 1, spaceIndex - 1)
        local macroMessage = string.sub(remainder, spaceIndex + 1)
        BGCommsMacros:AddMacro(macroName, macroMessage)
        BGCommsUI:RefreshUI()
        print("|cFF00FF00Macro '" .. macroName .. "' added.")
    elseif command == "rem" then
        -- /bgc macro remove <name>
        local macroName = string.sub(msg, 9)  -- Everything after "remove "
        if macroName == "" then
            print("|cFF00FF00Usage: /bgc macro remove <name>")
            return
        end
        if BGCommsMacros:RemoveMacro(macroName) then
            BGCommsUI:RefreshUI()
            print("|cFF00FF00Macro '" .. macroName .. "' removed.")
        else
            print("|cFF00FF00Macro '" .. macroName .. "' not found.")
        end
    elseif command == "lis" then
        -- /bgc macro list
        BGCommsMacros:ListMacros()
    else
        print("|cFF00FF00Unknown macro command: " .. command)
        print("|cFF00FF00Usage: /bgc macro [add <name> <message>|remove <name>|list]")
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
