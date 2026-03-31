-- Settings.lua - Settings panel UI and management

local Communications = require("Communications")
local UI = require("UI")

local Settings = {}
Settings.frame = nil
Settings.channelDropdown = nil
Settings.opacityValue = nil
Settings.lockCheckbox = nil
Settings.smartChannelCheckbox = nil

function Settings:CreateFrame()
    if self.frame then return end

    -- Create settings frame
    local frame = CreateFrame("Frame", "BGCommsSettingsFrame", UIParent)
    frame:SetSize(250, 280)

    -- Restore position from SavedVariables or use defaults
    local posX = BGCommsDB and BGCommsDB.settingsPanelX or -100
    local posY = BGCommsDB and BGCommsDB.settingsPanelY or 0
    frame:SetPoint("CENTER", UIParent, "CENTER", posX, posY)

    frame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.7)
    frame:SetBackdropBorderColor(1, 1, 1, 0.8)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(dragFrame)
        dragFrame:StopMovingOrSizing()
        -- Save settings panel position
        if BGCommsDB then
            BGCommsDB.settingsPanelX = dragFrame:GetLeft()
            BGCommsDB.settingsPanelY = dragFrame:GetTop()
        end
    end)
    frame:Hide()  -- Hidden by default

    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -10)
    title:SetText("BG Comms Settings")

    -- Close button
    local closeButton = CreateFrame("Button", "BGSettingsCloseButton", frame, "GameMenuButtonTemplate")
    closeButton:SetSize(25, 25)
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeButton:SetText("X")
    closeButton:SetScript("OnClick", function()
        self:Hide()
    end)

    -- Channel selection label
    local channelLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    channelLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -40)
    channelLabel:SetText("Channel:")

    -- Channel dropdown (simple text display for now)
    local channelDropdown = CreateFrame("Button", "BGChannelDropdown", frame, "GameMenuButtonTemplate")
    channelDropdown:SetSize(200, 25)
    channelDropdown:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -60)
    channelDropdown:SetText(Communications:GetChatChannel())
    channelDropdown:SetScript("OnClick", function()
        self:ShowChannelMenu()
    end)
    self.channelDropdown = channelDropdown

    -- Opacity label
    local opacityLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    opacityLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -100)
    opacityLabel:SetText("Opacity:")

    -- Opacity minus button
    local opacityMinus = CreateFrame("Button", "BGSettingsOpacityMinus", frame, "GameMenuButtonTemplate")
    opacityMinus:SetSize(30, 25)
    opacityMinus:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -120)
    opacityMinus:SetText("-")
    opacityMinus:SetScript("OnClick", function()
        UI:AdjustOpacity(-0.1)
        self:UpdateOpacityDisplay()
    end)

    -- Opacity value display
    local opacityValue = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    opacityValue:SetPoint("LEFT", opacityMinus, "RIGHT", 10, 0)
    opacityValue:SetText("0.5")
    self.opacityValue = opacityValue

    -- Opacity plus button
    local opacityPlus = CreateFrame("Button", "BGSettingsOpacityPlus", frame, "GameMenuButtonTemplate")
    opacityPlus:SetSize(30, 25)
    opacityPlus:SetPoint("LEFT", opacityValue, "RIGHT", 10, 0)
    opacityPlus:SetText("+")
    opacityPlus:SetScript("OnClick", function()
        UI:AdjustOpacity(0.1)
        self:UpdateOpacityDisplay()
    end)

    -- Lock toggle label
    local lockLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lockLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -160)
    lockLabel:SetText("Lock Window:")

    -- Lock toggle checkbox
    local lockCheckbox = CreateFrame("CheckButton", "BGSettingsLockCheckbox", frame, "ChatConfigCheckButtonTemplate")
    lockCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -180)
    lockCheckbox:SetScript("OnClick", function(self)
        UI:ToggleLock()
        self:SetChecked(BGCommsDB.isLocked)
    end)
    self.lockCheckbox = lockCheckbox

    -- Smart Channel label
    local smartLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    smartLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -210)
    smartLabel:SetText("Smart Channel:")

    -- Smart Channel checkbox
    local smartCheckbox = CreateFrame("CheckButton", "BGSettingsSmartCheckbox", frame, "ChatConfigCheckButtonTemplate")
    smartCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -230)
    smartCheckbox:SetScript("OnClick", function(self)
        BGCommsDB.useSmartChannelDetection = self:GetChecked()
    end)
    self.smartChannelCheckbox = smartCheckbox

    self.frame = frame
    self:UpdateAllSettings()
end

-- Update all settings display from SavedVariables
function Settings:UpdateAllSettings()
    if not self.frame then return end

    self:UpdateChannelDropdown()
    self:UpdateOpacityDisplay()
    self:UpdateLockDisplay()
    self:UpdateSmartChannelDisplay()
end

function Settings:UpdateChannelDropdown()
    if self.channelDropdown then
        self.channelDropdown:SetText(Communications:GetChatChannel())
    end
end

function Settings:UpdateOpacityDisplay()
    if self.opacityValue then
        local opacity = BGCommsDB and BGCommsDB.backgroundOpacity or 0.5
        self.opacityValue:SetText(string.format("%.1f", opacity))
    end
end

function Settings:UpdateLockDisplay()
    if self.lockCheckbox then
        self.lockCheckbox:SetChecked(BGCommsDB.isLocked)
    end
end

function Settings:UpdateSmartChannelDisplay()
    if self.smartChannelCheckbox then
        self.smartChannelCheckbox:SetChecked(BGCommsDB.useSmartChannelDetection)
    end
end

function Settings:ShowChannelMenu()
    -- Create a dropdown menu for channel selection
    local menu = {
        {
            text = "BGCOMMS",
            func = function()
                Communications:SetChatChannel("BGCOMMS")
                self:UpdateChannelDropdown()
            end
        },
        {
            text = "PARTY",
            func = function()
                Communications:SetChatChannel("PARTY")
                self:UpdateChannelDropdown()
            end
        },
        {
            text = "RAID",
            func = function()
                Communications:SetChatChannel("RAID")
                self:UpdateChannelDropdown()
            end
        },
        {
            text = "BATTLEGROUND",
            func = function()
                Communications:SetChatChannel("BATTLEGROUND")
                self:UpdateChannelDropdown()
            end
        },
        {
            text = "SAY",
            func = function()
                Communications:SetChatChannel("SAY")
                self:UpdateChannelDropdown()
            end
        },
    }

    EasyMenu(menu, CreateFrame("Frame", "BGChannelMenu", UIParent, "UIDropDownMenuTemplate"), "cursor", 0, 0, "TOPLEFT")
end

function Settings:ToggleFrame()
    if self.frame then
        if self.frame:IsShown() then
            self:Hide()
        else
            self:Show()
        end
    else
        self:CreateFrame()
        self:Show()
    end
end

function Settings:Show()
    if not self.frame then
        self:CreateFrame()
    end
    self:UpdateAllSettings()
    self.frame:Show()
end

function Settings:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

return Settings
