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
    frame:SetSize(310, 125)
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

    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -8)
    title:SetText("CTF")

    local contentMargin = 10
    local buttonHeight = 25

    -- Row 1: Flag Status Buttons (Secure, Taken, Dropped)
    local flagButtons = {
        {label = "Secure", status = "SECURE", x = contentMargin},
        {label = "Taken", status = "TAKEN", x = contentMargin + 105},
        {label = "Dropped", status = "DROPPED", x = contentMargin + 210}
    }

    for i, btnConfig in ipairs(flagButtons) do
        local btn = CreateFrame("Button", "BGCTFFlag" .. i, frame)
        btn:SetSize(90, buttonHeight)
        btn:SetPoint("TOPLEFT", frame, "TOPLEFT", btnConfig.x, -30)

        -- Blue background for flag buttons
        local btnBg = btn:CreateTexture(nil, "BACKGROUND")
        btnBg:SetAllPoints(btn)
        btnBg:SetColorTexture(0.2, 0.2, 0.8, 1)

        -- Button text
        local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btnText:SetAllPoints(btn)
        btnText:SetText(btnConfig.label)
        btnText:SetJustifyH("CENTER")
        btnText:SetJustifyV("MIDDLE")
        btnText:SetTextColor(1, 1, 1)

        btn:EnableMouse(true)
        btn:SetScript("OnClick", function()
            local location = BGCommsLocations:GetPlayerLocation()
            BGCommsCommunications:SendFlagStatus(btnConfig.status, location)
        end)

        table.insert(self.ctfButtons, btn)
    end

    -- Row 2: Base Defense Buttons (Defended, Clear, Under Attack)
    local baseButtons = {
        {label = "Defended", status = "DEFENDED", x = contentMargin},
        {label = "Clear", status = "CLEAR", x = contentMargin + 105},
        {label = "Under Attack", status = "UNDER_ATTACK", x = contentMargin + 210}
    }

    for i, btnConfig in ipairs(baseButtons) do
        local btn = CreateFrame("Button", "BGCTFBase" .. i, frame)
        btn:SetSize(90, buttonHeight)
        btn:SetPoint("TOPLEFT", frame, "TOPLEFT", btnConfig.x, -60)

        -- Green background for base defense buttons
        local btnBg = btn:CreateTexture(nil, "BACKGROUND")
        btnBg:SetAllPoints(btn)
        btnBg:SetColorTexture(0.2, 0.8, 0.2, 1)

        -- Button text
        local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btnText:SetAllPoints(btn)
        btnText:SetText(btnConfig.label)
        btnText:SetJustifyH("CENTER")
        btnText:SetJustifyV("MIDDLE")
        btnText:SetTextColor(0, 0, 0)

        btn:EnableMouse(true)
        btn:SetScript("OnClick", function()
            BGCommsCommunications:SendBaseStatus(btnConfig.status)
        end)

        table.insert(self.ctfButtons, btn)
    end

    -- Row 3: Flag Carrier Button
    local carrierBtn = CreateFrame("Button", "BGCTFCarrier", frame)
    carrierBtn:SetSize(90, buttonHeight)
    carrierBtn:SetPoint("TOPLEFT", frame, "TOPLEFT", contentMargin, -90)

    -- Red background for flag carrier button
    local carrierBg = carrierBtn:CreateTexture(nil, "BACKGROUND")
    carrierBg:SetAllPoints(carrierBtn)
    carrierBg:SetColorTexture(0.8, 0.2, 0.2, 1)

    -- Button text
    local carrierText = carrierBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    carrierText:SetAllPoints(carrierBtn)
    carrierText:SetText("Flag Carrier")
    carrierText:SetJustifyH("CENTER")
    carrierText:SetJustifyV("MIDDLE")
    carrierText:SetTextColor(1, 1, 1)

    carrierBtn:EnableMouse(true)
    carrierBtn:SetScript("OnClick", function()
        local location = BGCommsLocations:GetPlayerLocation()
        BGCommsCommunications:SendFlagCarrier(location)
    end)

    table.insert(self.ctfButtons, carrierBtn)

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
