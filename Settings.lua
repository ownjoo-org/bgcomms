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
    frame:SetSize(270, 220)

    -- Restore position from SavedVariables or use defaults
    -- Bounds check: if position is clearly off-screen (legacy bad coordinates), reset to default
    local posX = 0
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

    -- Declare opacity controls as local variables
    local opacitySlider, opacityValue, opacityInput

    -- Helper function to update opacity (expects 0-100 value)
    local function updateOpacity(value)
        value = math.floor(value)
        if value < 0 then value = 0 elseif value > 100 then value = 100 end
        local opacity = value / 100

        if BGCommsDB then
            BGCommsDB.backgroundOpacity = opacity
        end

        -- Update slider (0-1 range) and input field (0-100 range)
        opacitySlider:SetValue(opacity)
        opacityInput:SetText(tostring(value))
        opacityValue:SetText(value .. "%")

        -- Apply opacity to main frame background and settings frame background
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

        -- Also apply opacity to settings frame background
        if bgTexture then
            bgTexture:SetAlpha(opacity)
        end
    end

    -- LEFT SIDE CONTROLS
    -- Lock toggle label and checkbox on same line
    local lockLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lockLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -40)
    lockLabel:SetText("Lock Window:")

    local lockCheckbox = CreateFrame("CheckButton", "BGSettingsLockCheckbox", frame, "ChatConfigCheckButtonTemplate")
    lockCheckbox:SetPoint("LEFT", lockLabel, "RIGHT", 5, 0)
    lockCheckbox:SetScript("OnClick", function(self)
        BGCommsUI:ToggleLock()
        self:SetChecked(BGCommsDB.isLocked)
    end)
    self.lockCheckbox = lockCheckbox

    -- Smart Channel label and checkbox on same line
    local smartLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    smartLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -70)
    smartLabel:SetText("Smart Channel:")

    local smartCheckbox = CreateFrame("CheckButton", "BGSettingsSmartCheckbox", frame, "ChatConfigCheckButtonTemplate")
    smartCheckbox:SetPoint("LEFT", smartLabel, "RIGHT", 5, 0)
    smartCheckbox:SetScript("OnClick", function(self)
        BGCommsDB.useSmartChannelDetection = self:GetChecked()
    end)
    self.smartChannelCheckbox = smartCheckbox

    -- Position X label
    local posXLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    posXLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -170)
    posXLabel:SetText("X:")

    -- Position X input field
    local posXInput = CreateFrame("EditBox", "BGSettingsPosXInput", frame, "InputBoxTemplate")
    posXInput:SetAutoFocus(false)
    posXInput:SetSize(40, 22)
    posXInput:SetPoint("LEFT", posXLabel, "RIGHT", 8, 0)
    posXInput:SetText("0")
    posXInput:SetScript("OnEnterPressed", function(self)
        local valueX = tonumber(self:GetText()) or 0
        local valueY = tonumber(self.parent.posYInput:GetText()) or 0
        BGCommsDB.windowX = valueX
        BGCommsDB.windowY = valueY
        if BGCommsUI and BGCommsUI.frame then
            BGCommsUI.frame:ClearAllPoints()
            BGCommsUI.frame:SetPoint("CENTER", UIParent, "CENTER", valueX, valueY)
        end
        self:ClearFocus()
    end)
    posXInput:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    self.posXInput = posXInput

    -- Comma separator
    local posComma = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    posComma:SetPoint("LEFT", posXInput, "RIGHT", 5, 0)
    posComma:SetText(",")

    -- Position Y label
    local posYLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    posYLabel:SetPoint("LEFT", posComma, "RIGHT", 8, 0)
    posYLabel:SetText("Y:")

    -- Position Y input field
    local posYInput = CreateFrame("EditBox", "BGSettingsPosYInput", frame, "InputBoxTemplate")
    posYInput:SetAutoFocus(false)
    posYInput:SetSize(40, 22)
    posYInput:SetPoint("LEFT", posYLabel, "RIGHT", 8, 0)
    posYInput:SetText("0")
    posYInput:SetScript("OnEnterPressed", function(self)
        local valueX = tonumber(self.parent.posXInput:GetText()) or 0
        local valueY = tonumber(self:GetText()) or 0
        BGCommsDB.windowX = valueX
        BGCommsDB.windowY = valueY
        if BGCommsUI and BGCommsUI.frame then
            BGCommsUI.frame:ClearAllPoints()
            BGCommsUI.frame:SetPoint("CENTER", UIParent, "CENTER", valueX, valueY)
        end
        self:ClearFocus()
    end)
    posYInput:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    self.posYInput = posYInput

    -- OPACITY CONTROLS
    -- Opacity label
    local opacityLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    opacityLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -100)
    opacityLabel:SetText("Opacity:")

    -- Opacity value display (to the right of label)
    opacityValue = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    opacityValue:SetPoint("LEFT", opacityLabel, "RIGHT", 10, 0)
    opacityValue:SetText("50%")
    opacityValue:SetWidth(50)

    -- Opacity input field (to the right of percentage)
    opacityInput = CreateFrame("EditBox", "BGSettingsOpacityInput", frame, "InputBoxTemplate")
    opacityInput:SetAutoFocus(false)
    opacityInput:SetSize(50, 22)
    opacityInput:SetPoint("LEFT", opacityValue, "RIGHT", 10, 0)
    opacityInput:SetText("50")

    opacityInput:SetScript("OnEnterPressed", function(self)
        local value = tonumber(self:GetText()) or 50
        updateOpacity(value)
        self:ClearFocus()
    end)
    opacityInput:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    -- Minus button (below label)
    local minusButton = CreateFrame("Button", "BGSettingsOpacityMinus", frame, "GameMenuButtonTemplate")
    minusButton:SetSize(25, 22)
    minusButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -125)
    minusButton:SetText("-")
    minusButton:SetScript("OnClick", function()
        local currentValue = tonumber(opacityInput:GetText()) or 50
        updateOpacity(currentValue - 1)
    end)

    -- Horizontal opacity slider
    opacitySlider = CreateFrame("Slider", "BGSettingsOpacitySlider", frame, "OptionsSliderTemplate")
    opacitySlider:SetSize(100, 15)
    opacitySlider:SetPoint("LEFT", minusButton, "RIGHT", 3, 0)
    opacitySlider:SetMinMaxValues(0, 1)
    opacitySlider:SetValue(0.5)
    opacitySlider:SetValueStep(0.01)
    opacitySlider:SetOrientation("HORIZONTAL")

    -- Plus button
    local plusButton = CreateFrame("Button", "BGSettingsOpacityPlus", frame, "GameMenuButtonTemplate")
    plusButton:SetSize(25, 22)
    plusButton:SetPoint("LEFT", opacitySlider, "RIGHT", 3, 0)
    plusButton:SetText("+")
    plusButton:SetScript("OnClick", function()
        local currentValue = tonumber(opacityInput:GetText()) or 50
        updateOpacity(currentValue + 1)
    end)

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
        -- Slider is 0-1 range, convert to 0-100 for updateOpacity
        updateOpacity(value * 100)
    end)

    -- Set up parent references so each input can access the other
    posXInput.parent = self
    posYInput.parent = self

    self.frame = frame
    self.backgroundTexture = bgTexture  -- Store reference for opacity control
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
    BGCommsLogger:Debug("Updating position display...")
    self:UpdatePositionDisplay()
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
        self.opacitySlider:SetValue(opacity)  -- Slider expects 0-1 range
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

function BGCommsSettingsPanel:UpdatePositionDisplay()
    if self.posXInput then
        local posX = BGCommsDB and BGCommsDB.windowX or 0
        self.posXInput:SetText(tostring(math.floor(posX)))
    end
    if self.posYInput then
        local posY = BGCommsDB and BGCommsDB.windowY or 0
        self.posYInput:SetText(tostring(math.floor(posY)))
    end
end

function BGCommsSettingsPanel:ShowChannelMenu()
    -- Create a proper dropdown menu for channel selection
    local channels = {"SAY", "YELL", "PARTY", "RAID", "BATTLEGROUND", "GUILD"}

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
