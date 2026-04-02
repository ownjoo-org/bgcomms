-- CTF.lua - Capture the Flag communication frame
-- Note: BGCommsCommunications and BGCommsLocations are loaded globally by WoW before this file

BGCommsCTF = {}
BGCommsCTF.frame = nil
BGCommsCTF.ctfButtons = {}

function BGCommsCTF:CreateFrame()
    if self.frame then return end

    BGCommsLogger:Debug("CTF CreateFrame: Starting CTF frame creation")

    -- Create CTF frame
    local frame = CreateFrame("Frame", "BGCommsCTFFrame", UIParent)
    frame:SetSize(280, 180)
    BGCommsLogger:Debug("CTF CreateFrame: Frame object created, size set to 310x125")

    -- Restore position from SavedVariables or use defaults
    -- Use same windowX/windowY as main frame for shared positioning
    local posX = BGCommsDB and BGCommsDB.windowX or 0
    local posY = BGCommsDB and BGCommsDB.windowY or -800
    frame:SetPoint("CENTER", UIParent, "CENTER", posX, posY)

    -- Create background texture
    local bgTexture = frame:CreateTexture(nil, "BACKGROUND")
    bgTexture:SetAllPoints(frame)
    bgTexture:SetColorTexture(0, 0, 0, 0.7)

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
        -- Save CTF frame position (same as main frame) as center offset from UIParent center
        if BGCommsDB then
            local frameCenterX = dragFrame:GetLeft() + dragFrame:GetWidth() / 2
            local frameCenterY = dragFrame:GetTop() + dragFrame:GetHeight() / 2
            local uiCenterX = UIParent:GetLeft() + UIParent:GetWidth() / 2
            local uiCenterY = UIParent:GetTop() + UIParent:GetHeight() / 2
            BGCommsDB.windowX = math.floor(frameCenterX - uiCenterX + 0.5)
            BGCommsDB.windowY = math.floor(frameCenterY - uiCenterY + 872 + 0.5)
        end
    end)
    frame:Hide()

    -- Channel dropdown (centered, like main frame)
    local channelDropdown = CreateFrame("Button", "BGCTFChannelDropdown", frame)
    channelDropdown:SetSize(130, 22)
    channelDropdown:SetPoint("TOP", frame, "TOP", 0, -10)

    -- Create black background
    local channelBg = channelDropdown:CreateTexture(nil, "BACKGROUND")
    channelBg:SetAllPoints(channelDropdown)
    channelBg:SetColorTexture(0, 0, 0, 1)  -- Black background

    -- Create text
    local channelText = channelDropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    channelText:SetAllPoints(channelDropdown)
    channelText:SetText(BGCommsCommunications:GetChatChannel())
    channelText:SetTextColor(1, 1, 0)  -- Yellow
    channelText:SetJustifyH("CENTER")
    channelText:SetJustifyV("MIDDLE")

    channelDropdown.channelText = channelText
    channelDropdown.isDropdownOpen = false
    channelDropdown:EnableMouse(true)
    channelDropdown:SetScript("OnClick", function(self)
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

    -- OFFENSE SECTION (centered with padding)
    local offenseLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    offenseLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -45)
    offenseLabel:SetText("OFFENSE: Their FC")

    local offenseButtons = {
        {label = "West", direction = "WEST", x = 10},
        {label = "Mid", direction = "MID", x = 95},
        {label = "East", direction = "EAST", x = 175}
    }

    for i, btnConfig in ipairs(offenseButtons) do
        local btn = CreateFrame("Button", "BGCTFOffense" .. i, frame)
        btn:SetSize(70, 22)
        btn:SetPoint("TOPLEFT", frame, "TOPLEFT", btnConfig.x, -62)

        -- Red background for offense buttons
        local btnBg = btn:CreateTexture(nil, "BACKGROUND")
        btnBg:SetAllPoints(btn)
        btnBg:SetColorTexture(0.8, 0.2, 0.2, 1)

        local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btnText:SetAllPoints(btn)
        btnText:SetText(btnConfig.label)
        btnText:SetJustifyH("CENTER")
        btnText:SetJustifyV("MIDDLE")
        btnText:SetTextColor(1, 1, 1)

        btn:EnableMouse(true)
        btn:SetScript("OnClick", function()
            BGCommsCommunications:SendFCRunning("THEIR", btnConfig.direction)
        end)

        table.insert(self.ctfButtons, btn)
    end

    -- Horizontal separator (with padding above and below)
    local separator = frame:CreateTexture(nil, "ARTWORK")
    separator:SetSize(256, 1)
    separator:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -92)
    separator:SetColorTexture(0.5, 0.5, 0.5, 1)

    -- DEFENSE SECTION (with padding after h-rule)
    local defenseLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    defenseLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -102)
    defenseLabel:SetText("DEFENSE: Our FC")

    local defenseButtons = {
        {label = "West", direction = "WEST", x = 10},
        {label = "Mid", direction = "MID", x = 95},
        {label = "East", direction = "EAST", x = 175}
    }

    for i, btnConfig in ipairs(defenseButtons) do
        local btn = CreateFrame("Button", "BGCTFDefense" .. i, frame)
        btn:SetSize(70, 22)
        btn:SetPoint("TOPLEFT", frame, "TOPLEFT", btnConfig.x, -119)

        -- Blue background for defense buttons
        local btnBg = btn:CreateTexture(nil, "BACKGROUND")
        btnBg:SetAllPoints(btn)
        btnBg:SetColorTexture(0.2, 0.2, 0.8, 1)

        local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btnText:SetAllPoints(btn)
        btnText:SetText(btnConfig.label)
        btnText:SetJustifyH("CENTER")
        btnText:SetJustifyV("MIDDLE")
        btnText:SetTextColor(1, 1, 1)

        btn:EnableMouse(true)
        btn:SetScript("OnClick", function()
            BGCommsCommunications:SendFCRunning("OUR", btnConfig.direction)
        end)

        table.insert(self.ctfButtons, btn)
    end

    -- Defense action buttons (below defense directions with spacing)
    local defenseActionButtons = {
        {label = "INC Flag Room", action = "FLAG_ROOM", x = 10},
        {label = "FC Needs HELP", action = "NEEDS_HELP", x = 135}
    }

    for i, btnConfig in ipairs(defenseActionButtons) do
        local btn = CreateFrame("Button", "BGCTFDefenseAction" .. i, frame)
        btn:SetSize(100, 22)
        btn:SetPoint("TOPLEFT", frame, "TOPLEFT", btnConfig.x, -144)

        -- Green background for action buttons
        local btnBg = btn:CreateTexture(nil, "BACKGROUND")
        btnBg:SetAllPoints(btn)
        btnBg:SetColorTexture(0.2, 0.8, 0.2, 1)

        local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btnText:SetAllPoints(btn)
        btnText:SetText(btnConfig.label)
        btnText:SetJustifyH("CENTER")
        btnText:SetJustifyV("MIDDLE")
        btnText:SetTextColor(0, 0, 0)

        btn:EnableMouse(true)
        btn:SetScript("OnClick", function()
            if btnConfig.action == "FLAG_ROOM" then
                BGCommsCommunications:SendINCFlagRoom()
            elseif btnConfig.action == "NEEDS_HELP" then
                BGCommsCommunications:SendFCNeedsHelp()
            end
        end)

        table.insert(self.ctfButtons, btn)
    end

    self.frame = frame
    self:ApplyLockState()
    self:ApplyOpacity()
    BGCommsLogger:Debug("CTF CreateFrame: COMPLETE - CTF frame fully initialized")
end

-- Apply lock state to CTF frame
function BGCommsCTF:ApplyLockState()
    if not self.frame or not BGCommsDB then return end

    local isLocked = BGCommsDB.isLocked

    if isLocked then
        self.frame:SetMovable(false)
    else
        self.frame:SetMovable(true)
    end
end

-- Apply opacity to CTF frame
function BGCommsCTF:ApplyOpacity()
    if not self.frame then return end
    local opacity = BGCommsDB and BGCommsDB.backgroundOpacity or 0.5
    -- Find and update the background texture
    for i = 1, self.frame:GetNumRegions() do
        local region = select(i, self.frame:GetRegions())
        if region and region:GetObjectType() == "Texture" and region:GetDrawLayer() == "BACKGROUND" then
            region:SetAlpha(opacity)
        end
    end
end

function BGCommsCTF:ToggleFrame()
    BGCommsLogger:Debug("CTF ToggleFrame called, frame exists: " .. tostring(self.frame ~= nil))
    if self.frame then
        if self.frame:IsShown() then
            BGCommsLogger:Debug("Hiding CTF frame")
            self:Hide()
        else
            BGCommsLogger:Debug("Showing CTF frame")
            self:Show()
        end
    else
        BGCommsLogger:Debug("Creating CTF frame...")
        local success, err = pcall(function()
            self:CreateFrame()
        end)
        BGCommsLogger:Debug("CreateFrame pcall returned, success: " .. tostring(success))
        if success then
            BGCommsLogger:Debug("CTF frame created, showing...")
            self:Show()
        else
            BGCommsLogger:Error("ERROR creating CTF frame: " .. tostring(err))
        end
    end
end

function BGCommsCTF:Show()
    if not self.frame then
        self:CreateFrame()
    end
    -- Hide main frame when showing CTF frame
    if BGCommsUI then
        BGCommsUI:Hide()
    end
    if BGCommsDB then
        BGCommsDB.activeFrame = "CTF"
    end
    self.frame:Show()
end

function BGCommsCTF:Hide()
    if self.frame then
        self.frame:Hide()
    end
end
