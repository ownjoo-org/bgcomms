-- Core.lua - Main addon initialization

local Communications = require("Communications")
local Locations = require("Locations")
local UI = require("UI")
local Macros = require("Macros")
local Settings = require("Settings")

local BGComms = {}

function BGComms:Initialize()
    -- Initialize SavedVariables
    BGCommsDB = BGCommsDB or {}
    BGCommsCharDB = BGCommsCharDB or {}

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

    -- Restore chat channel from SavedVariables
    Communications:SetChatChannel(BGCommsDB.chatChannel)

    -- Join the BGCOMMS channel for future inter-addon communication
    JoinChannelByName("BGCOMMS", "", 1, false)

    -- Create the UI and Settings panels
    UI:CreateFrame()
    UI:Show()
    Settings:CreateFrame()

    -- Register slash commands
    SLASH_BGCOMMS1 = "/bgcomms"
    SLASH_BGCOMMS2 = "/bgc"
    SlashCmdList["BGCOMMS"] = function(msg)
        self:HandleSlashCommand(msg)
    end

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
        print("|cFF00FF00[BGComms]|r Usage: /bgc [show|hide|settings|clear|inc <location>|channel <name>|macro ...|smartchannel on|off]")
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
        BGComms:Initialize()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

return BGComms
