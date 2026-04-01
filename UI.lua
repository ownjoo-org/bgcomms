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
    button:SetScript("OnClick", function(self, clickButton)
        if clickButton == "LeftButton" then
            BGCommsUI:ToggleFrame()
        elseif clickButton == "RightButton" then
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

    -- Create main frame - sized to fit content with minimal margins
    local frame = CreateFrame("Frame", "BGCommsFrame", UIParent)
    BGCommsLogger:Debug("CreateFrame: Frame object created")
    -- Frame width: 256px content + 24px margins = 280px
    -- Height: minimal to fit controls with minimal bottom margin
    local frameHeight = 75
    frame:SetSize(280, frameHeight)
    BGCommsLogger:Debug("CreateFrame: Frame size set to 280x" .. tostring(frameHeight))

    -- Restore position from SavedVariables
    local posX = BGCommsDB and BGCommsDB.windowX or 0
    local posY = BGCommsDB and BGCommsDB.windowY or -800
    BGCommsLogger:Debug("Main frame position: posX=" .. tostring(posX) .. ", posY=" .. tostring(posY))
    frame:SetPoint("CENTER", UIParent, "CENTER", posX, posY)
    BGCommsLogger:Debug("Main frame after SetPoint: left=" .. tostring(frame:GetLeft()) .. ", top=" .. tostring(frame:GetTop()))

    -- Create background texture for opacity control
    BGCommsLogger:Debug("CreateFrame: Creating background texture")
    local bgTexture = frame:CreateTexture(nil, "BACKGROUND")
    bgTexture:SetAllPoints(frame)
    bgTexture:SetColorTexture(0, 0, 0, 1)  -- Use alpha 1 and control via SetAlpha
    self.backgroundTexture = bgTexture
    BGCommsLogger:Debug("CreateFrame: Background texture created")

    BGCommsLogger:Debug("CreateFrame: Setting up movable and dragging")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnMouseDown", function(dragFrame, button)
        if button == "LeftButton" and (not BGCommsDB or not BGCommsDB.isLocked) then
            dragFrame:StartMoving()
        end
    end)
    frame:SetScript("OnMouseUp", function(dragFrame)
        dragFrame:StopMovingOrSizing()
        -- Save frame position (rounded to integers to avoid float precision issues)
        if BGCommsDB then
            local frameCenterX = dragFrame:GetLeft() + dragFrame:GetWidth() / 2
            local frameCenterY = dragFrame:GetTop() + dragFrame:GetHeight() / 2
            local uiCenterX = UIParent:GetLeft() + UIParent:GetWidth() / 2
            local uiCenterY = UIParent:GetTop() + UIParent:GetHeight() / 2
            -- Apply SetPoint coordinate system offset (where 0,0 equals visual center)
            BGCommsDB.windowX = math.floor(frameCenterX - uiCenterX + 0.5)
            BGCommsDB.windowY = math.floor(frameCenterY - uiCenterY + 872 + 0.5)  -- Add 872 to align with SetPoint coords
            -- Update position display in settings panel if it's open
            if BGCommsSettingsPanel then
                BGCommsSettingsPanel:UpdatePositionDisplay()
            end
        end
    end)
    BGCommsLogger:Debug("CreateFrame: Dragging setup complete")

    self.frame = frame

    -- Create priority buttons (0=none, 1, 2, 3, 4, 5+) with spacing to match row below
    BGCommsLogger:Debug("CreateFrame: Creating priority buttons")
    local priorityLabels = {"0", "1", "2", "3", "4", "5+"}
    local priorityColors = {
        {"0", 0, 0.5, 1, 1},        -- Blue: R, G, B, A
        {"1", 0.7, 0.7, 0, 1},      -- Darker Yellow
        {"2", 0.7, 0.7, 0, 1},      -- Darker Yellow
        {"3", 0.7, 0.35, 0, 1},     -- Darker Orange
        {"4", 0.7, 0.35, 0, 1},     -- Darker Orange
        {"5+", 0.7, 0, 0, 1}        -- Darker Red
    }
    local priorityTextColors = {
        {"0", 1, 1, 1},             -- Blue text: white
        {"1", 0, 0, 0},             -- Yellow text: black
        {"2", 0, 0, 0},             -- Yellow text: black
        {"3", 0, 0, 0},             -- Orange text: black
        {"4", 0, 0, 0},             -- Orange text: black
        {"5+", 1, 1, 1}             -- Red text: white
    }
    local totalButtonWidth = 25 * 6  -- 6 buttons x 25px = 150px
    local totalGapWidth = 256 - totalButtonWidth  -- Match width of channel+CLEAR+INC row (256px total)
    local gapSize = totalGapWidth / 5  -- 5 gaps between 6 buttons
    local contentMargin = (280 - 256) / 2  -- Center: 12px on each side
    local priorityStartX = contentMargin

    for i, label in ipairs(priorityLabels) do
        local priorityButton = CreateFrame("Button", "BGPriorityButton" .. i, frame)
        priorityButton:SetSize(25, 22)

        -- Position buttons in a row with calculated spacing
        if i == 1 then
            priorityButton:SetPoint("TOPLEFT", frame, "TOPLEFT", priorityStartX, -12)
        else
            priorityButton:SetPoint("LEFT", self.priorityButtons[i-1], "RIGHT", gapSize, 0)
        end

        -- Create colored background
        local priorityBg = priorityButton:CreateTexture(nil, "BACKGROUND")
        priorityBg:SetAllPoints(priorityButton)
        local r, g, b, a = priorityColors[i][2], priorityColors[i][3], priorityColors[i][4], priorityColors[i][5]
        priorityBg:SetColorTexture(r, g, b, a)

        -- Create text with appropriate color
        local priorityText = priorityButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        priorityText:SetAllPoints(priorityButton)
        priorityText:SetText(label)
        priorityText:SetJustifyH("CENTER")
        priorityText:SetJustifyV("MIDDLE")
        local tr, tg, tb = priorityTextColors[i][2], priorityTextColors[i][3], priorityTextColors[i][4]
        priorityText:SetTextColor(tr, tg, tb)

        -- Store original colors and text for selection swapping
        priorityButton.priority = label
        priorityButton.originalBg = {r, g, b}
        priorityButton.originalText = {tr, tg, tb}
        priorityButton.bgTexture = priorityBg
        priorityButton.textString = priorityText
        priorityButton:EnableMouse(true)

        priorityButton:SetScript("OnClick", function(self)
            BGCommsUI.currentPriority = self.priority
            -- Swap colors: selected button gets white bg with black text, others return to original
            for _, btn in ipairs(BGCommsUI.priorityButtons) do
                if btn.priority == BGCommsUI.currentPriority then
                    -- Selected: white background with black text
                    btn.bgTexture:SetColorTexture(1, 1, 1, 1)  -- White
                    btn.textString:SetTextColor(0, 0, 0)  -- Black
                else
                    -- Deselected: restore original colors
                    btn.bgTexture:SetColorTexture(btn.originalBg[1], btn.originalBg[2], btn.originalBg[3], 1)
                    btn.textString:SetTextColor(btn.originalText[1], btn.originalText[2], btn.originalText[3])
                end
            end
        end)

        table.insert(self.priorityButtons, priorityButton)
    end

    -- Set initial priority button state (default to "0") - apply white bg with black text
    for i = 1, #self.priorityButtons do
        self.priorityButtons[i]:SetAlpha(1.0)
    end
    self.currentPriority = "0"
    -- Apply white background with black text to button 0
    self.priorityButtons[1].bgTexture:SetColorTexture(1, 1, 1, 1)  -- White
    self.priorityButtons[1].textString:SetTextColor(0, 0, 0)  -- Black
    BGCommsLogger:Debug("CreateFrame: Priority buttons created")

    -- Channel dropdown button (wider to fit BATTLEGROUND) - centered
    local channelDropdown = CreateFrame("Button", "BGCommsChannelDropdown", frame)
    channelDropdown:SetSize(130, 22)
    channelDropdown:SetPoint("TOPLEFT", frame, "TOPLEFT", contentMargin, -40)

    -- Create black background
    local channelBg = channelDropdown:CreateTexture(nil, "BACKGROUND")
    channelBg:SetAllPoints(channelDropdown)
    channelBg:SetColorTexture(0, 0, 0, 1)  -- Black background

    -- Create gray border outline (1px edges)
    local channelBorderTop = channelDropdown:CreateTexture(nil, "BORDER")
    channelBorderTop:SetSize(130, 1)
    channelBorderTop:SetPoint("TOPLEFT", channelDropdown, "TOPLEFT", 0, 0)
    channelBorderTop:SetColorTexture(0.5, 0.5, 0.5, 1)

    local channelBorderBottom = channelDropdown:CreateTexture(nil, "BORDER")
    channelBorderBottom:SetSize(130, 1)
    channelBorderBottom:SetPoint("BOTTOMLEFT", channelDropdown, "BOTTOMLEFT", 0, 0)
    channelBorderBottom:SetColorTexture(0.5, 0.5, 0.5, 1)

    local channelBorderLeft = channelDropdown:CreateTexture(nil, "BORDER")
    channelBorderLeft:SetSize(1, 22)
    channelBorderLeft:SetPoint("TOPLEFT", channelDropdown, "TOPLEFT", 0, 0)
    channelBorderLeft:SetColorTexture(0.5, 0.5, 0.5, 1)

    local channelBorderRight = channelDropdown:CreateTexture(nil, "BORDER")
    channelBorderRight:SetSize(1, 22)
    channelBorderRight:SetPoint("TOPRIGHT", channelDropdown, "TOPRIGHT", 0, 0)
    channelBorderRight:SetColorTexture(0.5, 0.5, 0.5, 1)

    -- Create text with yellow color
    local channelText = channelDropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    channelText:SetAllPoints(channelDropdown)
    channelText:SetText(BGCommsCommunications:GetChatChannel())
    channelText:SetTextColor(1, 1, 0)  -- Yellow
    channelText:SetJustifyH("CENTER")
    channelText:SetJustifyV("MIDDLE")

    -- Store reference to text for updates
    channelDropdown.channelText = channelText

    channelDropdown.isDropdownOpen = false
    channelDropdown:EnableMouse(true)

    channelDropdown:SetScript("OnClick", function(self)
        -- Toggle dropdown
        if self.isDropdownOpen then
            if BGCommsChannelDropdownMenu then
                BGCommsChannelDropdownMenu:Hide()
            end
            self.isDropdownOpen = false
        else
            BGCommsUI:ShowChannelDropdown(self)
            self.isDropdownOpen = true
        end
    end)

    self.channelDropdown = channelDropdown
    BGCommsLogger:Debug("CreateFrame: Channel dropdown created")

    -- CLEAR button (to the right of channel dropdown) - solid green, no border
    local clearButton = CreateFrame("Button", "BGClearButton", frame)
    clearButton:SetSize(60, 22)
    clearButton:SetPoint("LEFT", channelDropdown, "RIGHT", 3, 0)

    -- Create solid green background (no template border)
    local clearBg = clearButton:CreateTexture(nil, "BACKGROUND")
    clearBg:SetAllPoints(clearButton)
    clearBg:SetColorTexture(0, 0.6, 0, 1)  -- Solid green

    -- Add text to button
    local clearText = clearButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    clearText:SetAllPoints(clearButton)
    clearText:SetText("CLEAR")
    clearText:SetJustifyH("CENTER")
    clearText:SetJustifyV("MIDDLE")

    clearButton:EnableMouse(true)
    clearButton:SetScript("OnClick", function()
        BGCommsCommunications:SendClear()
    end)

    -- INC button (red background, yellow text, no border)
    local incButton = CreateFrame("Button", "BGIncButton", frame)
    incButton:SetSize(60, 22)
    incButton:SetPoint("LEFT", clearButton, "RIGHT", 3, 0)

    -- Create red background
    local incBg = incButton:CreateTexture(nil, "BACKGROUND")
    incBg:SetAllPoints(incButton)
    incBg:SetColorTexture(1, 0, 0, 1)  -- Red background

    -- Add text to button
    local incText = incButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    incText:SetAllPoints(incButton)
    incText:SetText("INC")
    incText:SetTextColor(1, 1, 0)  -- Yellow text
    incText:SetJustifyH("CENTER")
    incText:SetJustifyV("MIDDLE")

    incButton:EnableMouse(true)
    incButton:SetScript("OnClick", function()
        local location = BGCommsLocations:GetPlayerLocation()
        BGCommsCommunications:SendIncoming(location)
    end)

    self.clearButton = clearButton
    self.incButton = incButton

    -- Create macro buttons (starting below CLEAR/INC buttons)
    BGCommsLogger:Debug("CreateFrame: Creating macro buttons")
    self:CreateMacroButtons(frame, -65)
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
                BGCommsLogger:Debug("Showing main frame...")
                self.frame:Show()
                BGCommsLogger:Debug("Main frame visible: " .. tostring(self.frame:IsVisible()))
            else
                BGCommsLogger:Error("ERROR: self.frame is nil after CreateFrame!")
            end
        else
            BGCommsLogger:Error("ERROR creating main frame: " .. tostring(err))
            print("|cFFFF0000ERROR creating main frame:|r " .. tostring(err))
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
    local channels = {"SAY", "YELL", "PARTY", "RAID", "INSTANCE_CHAT", "GUILD"}

    -- Destroy old dropdown if it exists
    if BGCommsChannelDropdownMenu then
        BGCommsChannelDropdownMenu:Hide()
        -- Don't destroy, just hide - we'll reuse the name
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

    -- Add click-away handler: close dropdown if clicking outside
    local closeDropdown = function()
        if button.isDropdownOpen then
            button.isDropdownOpen = false
            dropdownFrame:Hide()
        end
    end

    dropdownFrame:SetScript("OnMouseUp", function(self, mouseButton)
        if mouseButton == "RightButton" then
            closeDropdown()
        end
    end)

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
            -- Update the main button's channel text using stored reference
            if button.channelText then
                button.channelText:SetText(channel)
                button.channelText:SetTextColor(1, 1, 0)  -- Yellow
            end
            -- Update settings panel dropdown if it exists
            if BGCommsSettingsPanel and BGCommsSettingsPanel.channelDropdown then
                BGCommsSettingsPanel:UpdateChannelDropdown()
            end
            button.isDropdownOpen = false
            dropdownFrame:Hide()
        end)

        -- Hover effects
        btn:SetScript("OnEnter", function(self)
            self.bgTexture:SetColorTexture(0.2, 0.5, 1, 0.6)  -- Blue highlight
        end)

        btn:SetScript("OnLeave", function(self)
            self.bgTexture:SetColorTexture(0, 0, 0, 0)  -- Clear
        end)

        -- Add separator line after each button except the last
        if i < #channels then
            local separator = dropdownFrame:CreateTexture(nil, "ARTWORK")
            separator:SetSize(130, 1)
            separator:SetPoint("TOPLEFT", dropdownFrame, "TOPLEFT", 5, -(2 + i * 28 - 2))
            separator:SetColorTexture(0.5, 0.5, 0.5, 0.5)
        end
    end

    dropdownFrame:Show()
end
