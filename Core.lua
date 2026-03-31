-- Core.lua - Main addon initialization
-- Note: All modules (Logger, Communications, Locations, UI, Macros, Settings) are loaded
-- by WoW before this file runs due to the .toc file load order, so they're available globally

local BGComms = {}

-- Log startup (Logger is already loaded globally)
if Logger then
    Logger:Debug("BattlegroundComms Core.lua loaded")
end

function BGComms:Initialize()
    Logger:Info("=== BattlegroundComms Initialize Started ===")

    -- Initialize SavedVariables
    BGCommsDB = BGCommsDB or {}
    BGCommsCharDB = BGCommsCharDB or {}
    Logger:Debug("SavedVariables initialized")

    -- Initialize SavedVariables defaults
    BGCommsDB.chatChannel = BGCommsDB.chatChannel or "PARTY"
    BGCommsDB.windowX = BGCommsDB.windowX or -300
    BGCommsDB.windowY = BGCommsDB.windowY or 200
    BGCommsDB.isLocked = BGCommsDB.isLocked or false
    BGCommsDB.backgroundOpacity = BGCommsDB.backgroundOpacity or 0.5
    BGCommsDB.useSmartChannelDetection = BGCommsDB.useSmartChannelDetection ~= false  -- Default true
    BGCommsDB.settingsPanelX = BGCommsDB.settingsPanelX or -100
    BGCommsDB.settingsPanelY = BGCommsDB.settingsPanelY or 0
    BGCommsDB.minimapIconX = BGCommsDB.minimapIconX or 0
    BGCommsDB.minimapIconY = BGCommsDB.minimapIconY or 0
    BGCommsCharDB.customMacros = BGCommsCharDB.customMacros or {}
    Logger:Debug("SavedVariables defaults set")

    -- Restore chat channel from SavedVariables
    Logger:Debug("Restoring chat channel: " .. BGCommsDB.chatChannel)
    Communications:SetChatChannel(BGCommsDB.chatChannel)

    -- Join the BGCOMMS channel for future inter-addon communication
    Logger:Debug("Joining BGCOMMS channel...")
    JoinChannelByName("BGCOMMS", "", 1, false)
    Logger:Debug("BGCOMMS channel join initiated")

    -- Create the UI and Settings panels
    Logger:Debug("Creating UI frame...")
    UI:CreateFrame()
    UI:Show()
    Logger:Debug("UI frame created and shown")

    Logger:Debug("Creating Settings frame...")
    Settings:CreateFrame()
    Logger:Debug("Settings frame created")

    -- Register slash commands
    SLASH_BGCOMMS1 = "/bgcomms"
    SLASH_BGCOMMS2 = "/bgc"
    SlashCmdList["BGCOMMS"] = function(msg)
        self:HandleSlashCommand(msg)
    end
    Logger:Debug("Slash commands registered")

    Logger:Info("=== BattlegroundComms Initialize Complete ===")
    Logger:Info("Addon loaded! Use /bgc to toggle the window.")
    print("|cFF00FF00[BGComms]|r Addon loaded! Use /bgc to toggle the window.")
end

function BGComms:HandleSlashCommand(msg)
    if msg == "" then
        UI:ToggleFrame()
    elseif msg == "hide" then
        UI:Hide()
    elseif msg == "show" then
        UI:Show()
    elseif msg == "settings" then
        Settings:ToggleFrame()
    elseif msg == "clear" then
        Communications:SendClear()
    elseif msg == "debug" then
        Logger:PrintHistory()
    elseif string.sub(msg, 1, 3) == "inc" then
        local location = string.sub(msg, 5)  -- Everything after "inc "
        Communications:SendIncoming(location)
    elseif string.sub(msg, 1, 7) == "channel" then
        self:HandleChannelCommand(string.sub(msg, 9))  -- Everything after "channel "
    elseif string.sub(msg, 1, 5) == "macro" then
        self:HandleMacroCommand(string.sub(msg, 7))  -- Everything after "macro "
    elseif string.sub(msg, 1, 12) == "smartchannel" then
        self:HandleSmartChannelCommand(string.sub(msg, 14))  -- Everything after "smartchannel "
    else
        print("|cFF00FF00[BGComms]|r Unknown command: " .. msg)
        print("|cFF00FF00[BGComms]|r Usage: /bgc [show|hide|settings|clear|inc <location>|channel <name>|macro ...|smartchannel on|off|debug]")
    end
end

function BGComms:HandleChannelCommand(msg)
    local channel = msg:upper():match("%S+")

    if not channel or channel == "" then
        print("|cFF00FF00[BGComms]|r Current channel: " .. Communications:GetChatChannel())
        print("|cFF00FF00[BGComms]|r Usage: /bgc channel <PARTY|RAID|BATTLEGROUND|BGCOMMS|SAY>")
        return
    end

    -- Validate channel
    if channel ~= "PARTY" and channel ~= "RAID" and channel ~= "BATTLEGROUND" and channel ~= "BGCOMMS" and channel ~= "SAY" then
        print("|cFF00FF00[BGComms]|r Invalid channel: " .. channel)
        print("|cFF00FF00[BGComms]|r Valid channels: PARTY, RAID, BATTLEGROUND, BGCOMMS, SAY")
        return
    end

    Communications:SetChatChannel(channel)
    Settings:UpdateChannelDropdown()
    print("|cFF00FF00[BGComms]|r Channel changed to: " .. channel)
end

function BGComms:HandleSmartChannelCommand(msg)
    local command = msg:lower():match("%S+")

    if command == "on" then
        BGCommsDB.useSmartChannelDetection = true
        print("|cFF00FF00[BGComms]|r Smart channel detection: ON")
    elseif command == "off" then
        BGCommsDB.useSmartChannelDetection = false
        print("|cFF00FF00[BGComms]|r Smart channel detection: OFF")
    else
        local status = BGCommsDB.useSmartChannelDetection and "ON" or "OFF"
        print("|cFF00FF00[BGComms]|r Smart channel detection: " .. status)
        print("|cFF00FF00[BGComms]|r Usage: /bgc smartchannel <on|off>")
    end
end

function BGComms:HandleMacroCommand(msg)
    local command = string.sub(msg, 1, 3)

    if command == "add" then
        -- /bgc macro add <name> <message>
        local remainder = string.sub(msg, 5)
        local spaceIndex = string.find(remainder, " ")
        if not spaceIndex then
            print("|cFF00FF00[BGComms]|r Usage: /bgc macro add <name> <message>")
            return
        end
        local macroName = string.sub(remainder, 1, spaceIndex - 1)
        local macroMessage = string.sub(remainder, spaceIndex + 1)
        Macros:AddMacro(macroName, macroMessage)
        UI:RefreshUI()
        print("|cFF00FF00[BGComms]|r Macro '" .. macroName .. "' added.")
    elseif command == "rem" then
        -- /bgc macro remove <name>
        local macroName = string.sub(msg, 9)  -- Everything after "remove "
        if macroName == "" then
            print("|cFF00FF00[BGComms]|r Usage: /bgc macro remove <name>")
            return
        end
        if Macros:RemoveMacro(macroName) then
            UI:RefreshUI()
            print("|cFF00FF00[BGComms]|r Macro '" .. macroName .. "' removed.")
        else
            print("|cFF00FF00[BGComms]|r Macro '" .. macroName .. "' not found.")
        end
    elseif command == "lis" then
        -- /bgc macro list
        Macros:ListMacros()
    else
        print("|cFF00FF00[BGComms]|r Unknown macro command: " .. command)
        print("|cFF00FF00[BGComms]|r Usage: /bgc macro [add <name> <message>|remove <name>|list]")
    end
end

-- Initialize when addon loads
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "BattlegroundComms" then
        Logger:Info("ADDON_LOADED event triggered for BattlegroundComms")
        local success, errorMsg = pcall(function()
            BGComms:Initialize()
        end)

        if not success then
            Logger:Error("Failed to initialize addon: " .. tostring(errorMsg))
        else
            Logger:Info("Addon initialization successful!")
        end

        self:UnregisterEvent("ADDON_LOADED")
    end
end)

return BGComms
