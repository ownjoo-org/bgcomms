-- BGCommsUI.lua - Create the button frame and BGCommsUI elements
-- Note: BGCommsCommunications, BGCommsLocations, BGCommsMacros, Settings are loaded globally by WoW before this file

BGCommsUI = {}
BGCommsUI.frame = nil
BGCommsUI.backgroundTexture = nil
BGCommsUI.macroButtons = {}
BGCommsUI.lockButton = nil
BGCommsUI.opacityMinusButton = nil
BGCommsUI.opacityPlusButton = nil
BGCommsUI.gearButton = nil
BGCommsUI.minimapIcon = nil
BGCommsUI.priorityButtons = {}
BGCommsUI.currentPriority = "1"  -- Current priority: "1", "2", "3", "4", "5+"

-- Toggle frame lock
function BGCommsUI:ToggleLock()
    if not BGCommsDB then return end

    BGCommsDB.isLocked = not BGCommsDB.isLocked
    self:ApplyLockState()
end

-- Apply lock state to frame
function BGCommsUI:ApplyLockState()
    if not self.frame or not BGCommsDB then return end

    local isLocked = BGCommsDB.isLocked

    if isLocked then
        self.frame:SetMovable(false)
        if self.lockButton then
            self.lockButton:SetText("🔒")
        end
    else
        self.frame:SetMovable(true)
        if self.lockButton then
            self.lockButton:SetText("🔓")
        end
    end
end

-- Adjust background opacity
function BGCommsUI:AdjustOpacity(delta)
    if not BGCommsDB then return end

    local currentOpacity = BGCommsDB.backgroundOpacity or 0.5
    local newOpacity = currentOpacity + delta

    -- Clamp to 0.1 - 1.0 range
    if newOpacity < 0.1 then
        newOpacity = 0.1
    elseif newOpacity > 1.0 then
        newOpacity = 1.0
    end

    BGCommsDB.backgroundOpacity = newOpacity
    self:ApplyOpacity()
end

-- Apply opacity to frame background
function BGCommsUI:ApplyOpacity()
    if not self.backgroundTexture then return end
    local opacity = BGCommsDB and BGCommsDB.backgroundOpacity or 0.5
    self.backgroundTexture:SetAlpha(opacity)
end

-- Create minimap icon following LibDBIcon-1.0 pattern (same as SkillCapped, DBM, PvPTabTarget)
function BGCommsUI:CreateMinimapIcon()
    if self.minimapIcon then return end

    local button = CreateFrame("Button", "BGCommsMinimapIcon", Minimap)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:SetSize(31, 31)
    button:RegisterForClicks("AnyUp")
    button:RegisterForDrag("LeftButton")

    -- Highlight texture for visual feedback
    button:SetHighlightTexture(136477)

    -- Circular border overlay (outside the minimap)
    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(50, 50)
    overlay:SetTexture(136430)
    overlay:SetPoint("TOPLEFT", button, "TOPLEFT")

    -- Background circle
    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetSize(24, 24)
    background:SetTexture(136467)
    background:SetPoint("CENTER", button, "CENTER")

    -- Icon texture
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(18, 18)
    icon:SetTexture("Interface/Icons/Ability_Warrior_BattleShout")
    icon:SetPoint("CENTER", button, "CENTER")
    button.icon = icon

    -- Update position based on angle (with quadrant-aware radius like LibDBIcon)
    local function updatePosition(anglePos)
        local angle = math.rad(anglePos or 225)
        local x, y = math.cos(angle), math.sin(angle)
        local minimapRadius = (Minimap:GetWidth() / 2) + 5
        button:SetPoint("CENTER", Minimap, "CENTER", x * minimapRadius, y * minimapRadius)
    end

    -- Restore saved position or use default
    if BGCommsDB and BGCommsDB.minimapPos then
        updatePosition(BGCommsDB.minimapPos)
    else
        updatePosition(225)
    end

    -- Handle dragging with real-time position updates (LibDBIcon style)
    button:SetScript("OnDragStart", function(self)
        self:LockHighlight()
        self:SetScript("OnUpdate", function(frame, elapsed)
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            px, py = px / scale, py / scale

            -- Calculate angle from minimap center to cursor
            local pos = math.deg(math.atan2(py - my, px - mx)) % 360

            -- Save position and update button
            if BGCommsDB then
                BGCommsDB.minimapPos = pos
            end
            updatePosition(pos)
        end)
    end)

    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        self:UnlockHighlight()
    end)

    -- Click handler: left click toggles main frame, right click opens settings
    button:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            BGCommsUI:ToggleFrame()
        elseif button == "RightButton" then
            BGCommsSettingsPanel:ToggleFrame()
        end
    end)

    -- Tooltip
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("BG Comms", 1, 1, 1)
        GameTooltip:AddLine("Left-click to toggle main window", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Right-click to open settings", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Drag to reposition", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    self.minimapIcon = button
end

-- Create macro buttons dynamically
function BGCommsUI:CreateMacroButtons(parentFrame, startY)
    -- Clear existing macro buttons
    for _, button in ipairs(self.macroButtons) do
        button:Hide()
    end
    self.macroButtons = {}

    local macros = BGCommsMacros:GetMacros()
    local buttonIndex = 1

    for macroName, _ in pairs(macros) do
        local macroButton = CreateFrame("Button", "BGMacroButton" .. buttonIndex, parentFrame, "GameMenuButtonTemplate")
        macroButton:SetSize(80, 25)

        -- Position buttons in two columns
        local column = (buttonIndex - 1) % 2
        local row = math.floor((buttonIndex - 1) / 2)

        if column == 0 then
            macroButton:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 10, startY - (row * 30))
        else
            macroButton:SetPoint("LEFT", parentFrame, "TOPLEFT", 100, startY - (row * 30))
        end

        macroButton:SetText(macroName:sub(1, 8))  -- Limit text to 8 chars
        macroButton:SetScript("OnClick", function()
            BGCommsMacros:ExecuteMacro(macroName)
        end)

        table.insert(self.macroButtons, macroButton)
        buttonIndex = buttonIndex + 1
    end

    -- Adjust frame height if needed
    local totalRows = math.ceil(#self.macroButtons / 2)
    if totalRows > 0 then
        parentFrame:SetHeight(100 + (totalRows * 30))
    end
end

function BGCommsUI:CreateFrame()
    if self.frame then return end

    BGCommsLogger:Debug("CreateFrame: Starting main frame creation")

    -- Create main frame - larger to fit all buttons with tight spacing
    local frame = CreateFrame("Frame", "BGCommsFrame", UIParent)
    BGCommsLogger:Debug("CreateFrame: Frame object created")
    -- Default height with title; will be reduced if title is hidden
    local frameHeight = 145
    frame:SetSize(280, frameHeight)
    BGCommsLogger:Debug("CreateFrame: Frame size set to 280x" .. tostring(frameHeight))

    -- Restore position from SavedVariables or use center
    -- Bounds check: if position looks invalid (legacy bad coordinates), reset to default
    local posX = 0
    local posY = 0
    if BGCommsDB and BGCommsDB.windowX then
        if math.abs(BGCommsDB.windowX) < 500 then
            posX = BGCommsDB.windowX
        end
    end
    if BGCommsDB and BGCommsDB.windowY then
        if math.abs(BGCommsDB.windowY) < 500 then
            posY = BGCommsDB.windowY
        end
    end
    BGCommsLogger:Debug("Main frame position: posX=" .. tostring(posX) .. ", posY=" .. tostring(posY))
    frame:SetPoint("CENTER", UIParent, "CENTER", posX, posY)
    BGCommsLogger:Debug("Main frame after SetPoint: left=" .. tostring(frame:GetLeft()) .. ", top=" .. tostring(frame:GetTop()))

    -- Create background texture for opacity control
    BGCommsLogger:Debug("CreateFrame: Creating background texture")
    local bgTexture = frame:CreateTexture(nil, "BACKGROUND")
    bgTexture:SetAllPoints(frame)
    bgTexture:SetColorTexture(0, 0, 0, 0.5)
    self.backgroundTexture = bgTexture
    BGCommsLogger:Debug("CreateFrame: Background texture created")

    BGCommsLogger:Debug("CreateFrame: Setting up dragging")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetScript("OnMouseDown", function(dragFrame, button)
        -- Only allow dragging if frame is not locked
        if button == "LeftButton" and (not BGCommsDB or not BGCommsDB.isLocked) then
            dragFrame:StartMoving()
        end
    end)
    frame:SetScript("OnMouseUp", function(dragFrame)
        dragFrame:StopMovingOrSizing()
        -- Save window position to SavedVariables as center offset from UIParent center
        if BGCommsDB then
            local frameCenterX = dragFrame:GetLeft() + dragFrame:GetWidth() / 2
            local frameCenterY = dragFrame:GetTop() + dragFrame:GetHeight() / 2
            local uiCenterX = UIParent:GetLeft() + UIParent:GetWidth() / 2
            local uiCenterY = UIParent:GetTop() + UIParent:GetHeight() / 2
            BGCommsDB.windowX = frameCenterX - uiCenterX
            BGCommsDB.windowY = frameCenterY - uiCenterY
        end
    end)
    BGCommsLogger:Debug("CreateFrame: Dragging setup complete")

    -- Title (optional - can be hidden via settings)
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", frame, "TOP", 0, -5)
    title:SetText("BG Comms")
    self.title = title
    self.frame = frame

    -- Create priority buttons (0=none, 1, 2, 3, 4, 5+) - moved up since we removed gear/lock buttons
    BGCommsLogger:Debug("CreateFrame: Creating priority buttons")
    local priorityLabels = {"0", "1", "2", "3", "4", "5+"}
    for i, label in ipairs(priorityLabels) do
        local priorityButton = CreateFrame("Button", "BGPriorityButton" .. i, frame, "GameMenuButtonTemplate")
        priorityButton:SetSize(25, 22)

        -- Position buttons in a row near the top
        if i == 1 then
            priorityButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -20)
        else
            priorityButton:SetPoint("LEFT", self.priorityButtons[i-1], "RIGHT", 1, 0)
        end

        priorityButton:SetText(label)
        priorityButton.priority = label

        priorityButton:SetScript("OnClick", function(self)
            BGCommsUI.currentPriority = self.priority
            -- Update visual state: highlight selected button
            for _, btn in ipairs(BGCommsUI.priorityButtons) do
                if btn.priority == BGCommsUI.currentPriority then
                    btn:SetAlpha(1.0)
                else
                    btn:SetAlpha(0.6)
                end
            end
        end)

        table.insert(self.priorityButtons, priorityButton)
    end

    -- Set initial priority button state (default to "0")
    self.priorityButtons[1]:SetAlpha(1.0)
    for i = 2, #self.priorityButtons do
        self.priorityButtons[i]:SetAlpha(0.6)
    end
    self.currentPriority = "0"
    BGCommsLogger:Debug("CreateFrame: Priority buttons created")

    -- Channel dropdown button
    local channelDropdown = CreateFrame("Button", "BGCommsChannelDropdown", frame, "GameMenuButtonTemplate")
    channelDropdown:SetSize(90, 22)
    channelDropdown:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -45)
    channelDropdown:SetText(BGCommsCommunications:GetChatChannel())

    channelDropdown:SetScript("OnClick", function(self)
        BGCommsUI:ShowChannelDropdown(self)
    end)

    self.channelDropdown = channelDropdown
    BGCommsLogger:Debug("CreateFrame: Channel dropdown created")

    -- CLEAR button (to the right of channel dropdown)
    local clearButton = CreateFrame("Button", "BGClearButton", frame, "GameMenuButtonTemplate")
    clearButton:SetSize(60, 22)
    clearButton:SetPoint("LEFT", channelDropdown, "RIGHT", 3, 0)
    clearButton:SetText("CLEAR")
    clearButton:SetScript("OnClick", function()
        BGCommsCommunications:SendClear()
    end)

    -- INC button
    local incButton = CreateFrame("Button", "BGIncButton", frame, "GameMenuButtonTemplate")
    incButton:SetSize(60, 22)
    incButton:SetPoint("LEFT", clearButton, "RIGHT", 3, 0)
    incButton:SetText("INC")
    incButton:SetScript("OnClick", function()
        local location = BGCommsLocations:GetPlayerLocation()
        BGCommsCommunications:SendIncoming(location)
    end)

    self.clearButton = clearButton
    self.incButton = incButton

    -- Create macro buttons (starting below CLEAR/INC buttons)
    BGCommsLogger:Debug("CreateFrame: Creating macro buttons")
    self:CreateMacroButtons(frame, -70)
    BGCommsLogger:Debug("CreateFrame: Macro buttons created")

    -- Create minimap icon
    BGCommsLogger:Debug("CreateFrame: Creating minimap icon")
    self:CreateMinimapIcon()
    BGCommsLogger:Debug("CreateFrame: Minimap icon created")

    -- Apply saved lock state
    BGCommsLogger:Debug("CreateFrame: Applying lock state")
    self:ApplyLockState()
    BGCommsLogger:Debug("CreateFrame: Lock state applied")

    -- Apply saved opacity
    BGCommsLogger:Debug("CreateFrame: Applying opacity")
    self:ApplyOpacity()
    BGCommsLogger:Debug("CreateFrame: Opacity applied")

    BGCommsLogger:Debug("CreateFrame: COMPLETE - main frame fully initialized")
end

function BGCommsUI:ToggleFrame()
    BGCommsLogger:Debug("BGCommsUI ToggleFrame called, frame exists: " .. tostring(self.frame ~= nil))
    if self.frame then
        if self.frame:IsShown() then
            BGCommsLogger:Debug("Hiding main frame")
            self.frame:Hide()
        else
            BGCommsLogger:Debug("Showing main frame")
            -- Apply hideTitle setting and adjust frame size
            if BGCommsDB and BGCommsDB.hideTitle and self.title then
                self.title:Hide()
                self.frame:SetHeight(125)  -- Reduced by ~20 pixels for hidden title
            elseif self.title then
                self.title:Show()
                self.frame:SetHeight(145)  -- Normal height with title
            end
            self.frame:Show()
        end
    else
        BGCommsLogger:Debug("Creating main frame...")
        local success, err = pcall(function()
            self:CreateFrame()
        end)
        BGCommsLogger:Debug("CreateFrame pcall returned, success: " .. tostring(success))
        if success then
            BGCommsLogger:Debug("Main frame created, self.frame = " .. tostring(self.frame))
            if self.frame then
                -- Apply hideTitle setting and adjust frame size
                if BGCommsDB and BGCommsDB.hideTitle and self.title then
                    self.title:Hide()
                    self.frame:SetHeight(125)  -- Reduced by ~20 pixels for hidden title
                end
                BGCommsLogger:Debug("Showing main frame...")
                self.frame:Show()
                BGCommsLogger:Debug("Main frame visible: " .. tostring(self.frame:IsVisible()))
            else
                BGCommsLogger:Error("ERROR: self.frame is nil after CreateFrame!")
            end
        else
            BGCommsLogger:Error("ERROR creating main frame: " .. tostring(err))
            print("|cFFFF0000[BGComms]|r ERROR creating main frame: " .. tostring(err))
        end
    end
end

function BGCommsUI:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

function BGCommsUI:Show()
    if not self.frame then
        self:CreateFrame()
    end
    self.frame:Show()
end

-- Refresh the BGCommsUI (e.g., when macros are added/removed)
function BGCommsUI:RefreshUI()
    if self.frame then
        self:CreateMacroButtons(self.frame, -30)
    end
end

-- Show channel dropdown menu
function BGCommsUI:ShowChannelDropdown(button)
    local channels = {"BGCOMMS", "PARTY", "RAID", "BATTLEGROUND", "SAY"}

    -- Hide old dropdown if it exists
    if BGCommsChannelDropdownMenu then
        BGCommsChannelDropdownMenu:Hide()
    end

    -- Create dropdown frame with proper strata/level to appear on top
    local dropdownFrame = CreateFrame("Frame", "BGCommsChannelDropdownMenu", UIParent)
    dropdownFrame:SetFrameStrata("DIALOG")
    dropdownFrame:SetFrameLevel(100)
    dropdownFrame:SetSize(140, 5 + (#channels * 28))
    dropdownFrame:SetPoint("TOP", button, "BOTTOM", 0, -5)

    -- Background with 70% opacity
    local bgTexture = dropdownFrame:CreateTexture(nil, "BACKGROUND")
    bgTexture:SetAllPoints(dropdownFrame)
    bgTexture:SetColorTexture(0.1, 0.1, 0.1, 0.7)

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
            button:SetText(channel)
            if BGCommsSettingsPanel and BGCommsSettingsPanel.channelDropdown then
                BGCommsSettingsPanel.channelDropdown:SetText(channel)
            end
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
