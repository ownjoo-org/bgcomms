-- Settings.lua - Settings panel BGCommsUI and management
-- Note: BGCommsCommunications and BGCommsUI are loaded globally by WoW before this file
-- RENAMED: BGCommsSettingsPanel to avoid conflict with Blizzard's global Settings object

BGCommsSettingsPanel = {}
BGCommsSettingsPanel.frame = nil
BGCommsSettingsPanel.channelDropdown = nil
BGCommsSettingsPanel.opacityValue = nil
BGCommsSettingsPanel.lockCheckbox = nil
BGCommsSettingsPanel.smartChannelCheckbox = nil

function BGCommsSettingsPanel:CreateFrame()
    BGCommsLogger:Debug("CreateFrame (settings) called, frame exists: " .. tostring(self.frame ~= nil))
    if self.frame then return end

    BGCommsLogger:Debug("Creating settings frame object...")
    -- Create settings frame
    local frame = CreateFrame("Frame", "BGCommsSettingsFrame", UIParent)
    BGCommsLogger:Debug("Settings frame object created: " .. tostring(frame))
    frame:SetSize(250, 280)

    -- Restore position from SavedVariables or use defaults
    -- Bounds check: if position is clearly off-screen (legacy bad coordinates), reset to default
    local posX = -100
    local posY = 0
    if BGCommsDB and BGCommsDB.settingsPanelX then
        -- Only use saved position if it looks reasonable (offset, not absolute screen coordinate)
        if math.abs(BGCommsDB.settingsPanelX) < 500 then
            posX = BGCommsDB.settingsPanelX
        end
    end
    if BGCommsDB and BGCommsDB.settingsPanelY then
        if math.abs(BGCommsDB.settingsPanelY) < 500 then
            posY = BGCommsDB.settingsPanelY
        end
    end
    frame:SetPoint("CENTER", UIParent, "CENTER", posX, posY)

    -- Create background texture with 70% opacity
    local bgTexture = frame:CreateTexture(nil, "BACKGROUND")
    bgTexture:SetAllPoints(frame)
    bgTexture:SetColorTexture(0, 0, 0, 0.7)

    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(dragFrame)
        dragFrame:StopMovingOrSizing()
        -- Save settings panel position as center offset from UIParent center
        if BGCommsDB then
            local frameCenterX = dragFrame:GetLeft() + dragFrame:GetWidth() / 2
            local frameCenterY = dragFrame:GetTop() + dragFrame:GetHeight() / 2
            local uiCenterX = UIParent:GetLeft() + UIParent:GetWidth() / 2
            local uiCenterY = UIParent:GetTop() + UIParent:GetHeight() / 2
            BGCommsDB.settingsPanelX = frameCenterX - uiCenterX
            BGCommsDB.settingsPanelY = frameCenterY - uiCenterY
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

    -- Opacity label
    local opacityLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    opacityLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -40)
    opacityLabel:SetText("Opacity:")

    -- Declare opacity controls as local variables
    local opacitySlider, opacityValue, opacityInput

    -- Helper function to update opacity
    local function updateOpacity(value)
        value = math.floor(value)
        if value < 0 then value = 0 elseif value > 100 then value = 100 end
        local opacity = value / 100

        if BGCommsDB then
            BGCommsDB.backgroundOpacity = opacity
        end

        -- Update slider and input field
        opacitySlider:SetValue(value)
        opacityInput:SetText(tostring(value))
        opacityValue:SetText(value .. "%")

        -- Apply opacity to main frame background
        if BGCommsUI and BGCommsUI.backgroundTexture then
            if value == 0 then
                BGCommsUI.backgroundTexture:SetAlpha(0)
                if BGCommsUI.frame then
                    BGCommsUI.frame:EnableMouse(false)
                end
            else
                BGCommsUI.backgroundTexture:SetAlpha(opacity)
                if BGCommsUI.frame then
                    BGCommsUI.frame:EnableMouse(true)
                end
            end
        end
    end

    -- Minus button
    local minusButton = CreateFrame("Button", "BGSettingsOpacityMinus", frame, "GameMenuButtonTemplate")
    minusButton:SetSize(25, 22)
    minusButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -60)
    minusButton:SetText("-")
    minusButton:SetScript("OnClick", function()
        local currentValue = math.floor(opacitySlider:GetValue())
        updateOpacity(currentValue - 1)
    end)

    -- Opacity slider (0-100%)
    local opacitySlider = CreateFrame("Slider", "BGSettingsOpacitySlider", frame)
    opacitySlider:SetSize(100, 15)
    opacitySlider:SetPoint("LEFT", minusButton, "RIGHT", 3, 0)
    opacitySlider:SetMinMaxValues(0, 100)
    opacitySlider:SetValue(50)
    opacitySlider:SetValueStep(1)
    opacitySlider:SetOrientation("HORIZONTAL")

    -- Slider texture
    local sliderTex = opacitySlider:CreateTexture(nil, "BACKGROUND")
    sliderTex:SetAllPoints(opacitySlider)
    sliderTex:SetTexture("Interface/Buttons/UI-SliderBar-Background")

    -- Slider thumb
    local thumb = opacitySlider:GetThumbTexture()
    if thumb then
        thumb:SetTexture("Interface/Buttons/UI-SliderBar-Button-Horizontal")
        thumb:SetSize(16, 16)
    end

    -- Plus button
    local plusButton = CreateFrame("Button", "BGSettingsOpacityPlus", frame, "GameMenuButtonTemplate")
    plusButton:SetSize(25, 22)
    plusButton:SetPoint("LEFT", opacitySlider, "RIGHT", 3, 0)
    plusButton:SetText("+")
    plusButton:SetScript("OnClick", function()
        local currentValue = math.floor(opacitySlider:GetValue())
        updateOpacity(currentValue + 1)
    end)

    -- Opacity value display
    local opacityValue = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    opacityValue:SetPoint("LEFT", plusButton, "RIGHT", 10, 0)
    opacityValue:SetText("50%")
    opacityValue:SetWidth(50)

    -- Opacity input field
    local opacityInput = CreateFrame("EditBox", "BGSettingsOpacityInput", frame)
    opacityInput:SetAutoFocus(false)
    opacityInput:SetSize(50, 22)
    opacityInput:SetPoint("LEFT", opacityValue, "RIGHT", 10, 0)
    opacityInput:SetFont("Fonts/FRIZQT__.TTF", 12)
    opacityInput:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    opacityInput:SetBackdropColor(0, 0, 0, 0.5)
    opacityInput:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    opacityInput:SetText("50")
    opacityInput:SetScript("OnEnterPressed", function(self)
        local value = tonumber(self:GetText()) or 50
        updateOpacity(value)
        self:ClearFocus()
    end)
    opacityInput:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    self.opacitySlider = opacitySlider
    self.opacityValue = opacityValue
    self.opacityInput = opacityInput

    -- Slider value change handler
    opacitySlider:SetScript("OnValueChanged", function(self, value)
        updateOpacity(value)
    end)

    -- Lock toggle label
    local lockLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lockLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -160)
    lockLabel:SetText("Lock Window:")

    -- Lock toggle checkbox
    local lockCheckbox = CreateFrame("CheckButton", "BGSettingsLockCheckbox", frame, "ChatConfigCheckButtonTemplate")
    lockCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -180)
    lockCheckbox:SetScript("OnClick", function(self)
        BGCommsUI:ToggleLock()
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

    -- Hide Title label
    local hideTitleLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hideTitleLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -260)
    hideTitleLabel:SetText("Hide Title:")

    -- Hide Title checkbox
    local hideTitleCheckbox = CreateFrame("CheckButton", "BGSettingsHideTitleCheckbox", frame, "ChatConfigCheckButtonTemplate")
    hideTitleCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -280)
    hideTitleCheckbox:SetScript("OnClick", function(self)
        BGCommsDB.hideTitle = self:GetChecked()
        if BGCommsUI and BGCommsUI.title then
            if BGCommsDB.hideTitle then
                BGCommsUI.title:Hide()
            else
                BGCommsUI.title:Show()
            end
        end
    end)
    self.hideTitleCheckbox = hideTitleCheckbox

    self.frame = frame
    self:UpdateAllSettings()
end

-- Update all settings display from SavedVariables
function BGCommsSettingsPanel:UpdateAllSettings()
    BGCommsLogger:Debug("UpdateAllSettings called")
    if not self.frame then
        BGCommsLogger:Debug("UpdateAllSettings: frame is nil!")
        return
    end

    BGCommsLogger:Debug("Updating channel dropdown...")
    self:UpdateChannelDropdown()
    BGCommsLogger:Debug("Updating opacity display...")
    self:UpdateOpacityDisplay()
    BGCommsLogger:Debug("Updating lock display...")
    self:UpdateLockDisplay()
    BGCommsLogger:Debug("Updating smart channel display...")
    self:UpdateSmartChannelDisplay()
    BGCommsLogger:Debug("Updating hide title display...")
    self:UpdateHideTitleDisplay()
    BGCommsLogger:Debug("UpdateAllSettings complete")
end

function BGCommsSettingsPanel:UpdateChannelDropdown()
    if self.channelDropdown then
        self.channelDropdown:SetText(BGCommsCommunications:GetChatChannel())
    end
end

function BGCommsSettingsPanel:UpdateOpacityDisplay()
    if self.opacitySlider then
        local opacity = BGCommsDB and BGCommsDB.backgroundOpacity or 0.5
        self.opacitySlider:SetValue(opacity * 100)
    end
    if self.opacityValue then
        local opacity = BGCommsDB and BGCommsDB.backgroundOpacity or 0.5
        self.opacityValue:SetText(math.floor(opacity * 100) .. "%")
    end
    if self.opacityInput then
        local opacity = BGCommsDB and BGCommsDB.backgroundOpacity or 0.5
        self.opacityInput:SetText(tostring(math.floor(opacity * 100)))
    end
end

function BGCommsSettingsPanel:UpdateLockDisplay()
    if self.lockCheckbox then
        self.lockCheckbox:SetChecked(BGCommsDB.isLocked)
    end
end

function BGCommsSettingsPanel:UpdateSmartChannelDisplay()
    if self.smartChannelCheckbox then
        self.smartChannelCheckbox:SetChecked(BGCommsDB.useSmartChannelDetection)
    end
end

function BGCommsSettingsPanel:UpdateHideTitleDisplay()
    if self.hideTitleCheckbox then
        self.hideTitleCheckbox:SetChecked(BGCommsDB.hideTitle or false)
    end
end

function BGCommsSettingsPanel:ShowChannelMenu()
    -- Create a proper dropdown menu for channel selection
    local channels = {"BGCOMMS", "PARTY", "RAID", "BATTLEGROUND", "SAY"}

    -- Hide old dropdown if it exists
    if BGChannelDropdownMenu then
        BGChannelDropdownMenu:Hide()
    end

    -- Create dropdown frame with proper strata/level to appear on top
    local dropdownFrame = CreateFrame("Frame", "BGChannelDropdownMenu", UIParent)
    dropdownFrame:SetFrameStrata("DIALOG")
    dropdownFrame:SetFrameLevel(100)
    dropdownFrame:SetSize(140, 5 + (#channels * 28))
    dropdownFrame:SetPoint("TOP", self.channelDropdown, "BOTTOM", 0, -5)

    -- Background with 70% opacity
    local bgTexture = dropdownFrame:CreateTexture(nil, "BACKGROUND")
    bgTexture:SetAllPoints(dropdownFrame)
    bgTexture:SetColorTexture(0.1, 0.1, 0.1, 0.7)

    -- Border texture for visual definition
    local borderTexture = dropdownFrame:CreateTexture(nil, "BORDER")
    borderTexture:SetAllPoints(dropdownFrame)
    borderTexture:SetColorTexture(0.5, 0.5, 0.5, 0.8)
    borderTexture:SetPoint("TOPLEFT", dropdownFrame, "TOPLEFT", 0, 0)
    borderTexture:SetSize(140, 1)  -- Top border

    -- Create buttons for each channel
    for i, channel in ipairs(channels) do
        local btn = CreateFrame("Button", "BGChannelOption" .. i, dropdownFrame)
        btn:SetFrameLevel(101)  -- Above background
        btn:SetSize(130, 24)
        btn:SetPoint("TOPLEFT", dropdownFrame, "TOPLEFT", 5, -(2 + (i-1) * 28))

        -- Button background texture (highlight on hover)
        local btnBg = btn:CreateTexture(nil, "BACKGROUND")
        btnBg:SetAllPoints(btn)
        btnBg:SetColorTexture(0, 0, 0, 0)  -- Transparent by default
        btn.bgTexture = btnBg

        -- Button text
        local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetAllPoints(btn)
        text:SetText(channel)
        text:SetJustifyH("LEFT")
        text:SetJustifyV("MIDDLE")

        -- Click handler
        btn:SetScript("OnClick", function()
            BGCommsCommunications:SetChatChannel(channel)
            self:UpdateChannelDropdown()
            dropdownFrame:Hide()
        end)

        -- Hover effects
        btn:SetScript("OnEnter", function(self)
            self.bgTexture:SetColorTexture(0.2, 0.5, 1, 0.6)  -- Blue highlight
        end)

        btn:SetScript("OnLeave", function(self)
            self.bgTexture:SetColorTexture(0, 0, 0, 0)  -- Clear
        end)
    end

    dropdownFrame:Show()
end

function BGCommsSettingsPanel:ToggleFrame()
    BGCommsLogger:Debug("Settings ToggleFrame called, frame exists: " .. tostring(self.frame ~= nil))
    if self.frame then
        if self.frame:IsShown() then
            BGCommsLogger:Debug("Hiding settings")
            self:Hide()
        else
            BGCommsLogger:Debug("Showing settings")
            self:Show()
        end
    else
        BGCommsLogger:Debug("Creating settings frame...")
        local success, err = pcall(function()
            self:CreateFrame()
        end)
        BGCommsLogger:Debug("pcall returned, success: " .. tostring(success))
        if success then
            BGCommsLogger:Debug("Settings frame created, showing...")
            BGCommsLogger:Debug("self.frame = " .. tostring(self.frame))
            self:Show()
            BGCommsLogger:Debug("After Show(), frame visible: " .. tostring(self.frame:IsVisible()))
        else
            BGCommsLogger:Error("ERROR creating settings frame: " .. tostring(err))
        end
    end
end

function BGCommsSettingsPanel:Show()
    if not self.frame then
        self:CreateFrame()
    end
    self:UpdateAllSettings()
    self.frame:Show()
end

function BGCommsSettingsPanel:Hide()
    if self.frame then
        self.frame:Hide()
    end
end
