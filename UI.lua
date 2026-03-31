-- UI.lua - Create the button frame and UI elements

local Communications = require("Communications")
local Locations = require("Locations")
local Macros = require("Macros")
local Settings = require("Settings")

local UI = {}
UI.frame = nil
UI.macroButtons = {}
UI.lockButton = nil
UI.opacityMinusButton = nil
UI.opacityPlusButton = nil
UI.gearButton = nil
UI.minimapIcon = nil

-- Toggle frame lock
function UI:ToggleLock()
    if not BGCommsDB then return end

    BGCommsDB.isLocked = not BGCommsDB.isLocked
    self:ApplyLockState()
end

-- Apply lock state to frame
function UI:ApplyLockState()
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
function UI:AdjustOpacity(delta)
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
    self:ApplyOpacity(newOpacity)
end

-- Apply opacity to frame background
function UI:ApplyOpacity(opacity)
    if not self.frame then return end
    self.frame:SetBackdropColor(0, 0, 0, opacity)
end

-- Create minimap icon
function UI:CreateMinimapIcon()
    if self.minimapIcon then return end

    local icon = CreateFrame("Button", "BGCommsMinimapIcon", Minimap)
    icon:SetSize(36, 36)
    icon:SetFrameLevel(8)

    -- Restore position or use default (top-right of minimap)
    local iconX = BGCommsDB and BGCommsDB.minimapIconX or 50
    local iconY = BGCommsDB and BGCommsDB.minimapIconY or -70
    icon:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", iconX, iconY)

    -- Icon backdrop
    icon:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    icon:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
    icon:SetBackdropBorderColor(1, 1, 1, 0.5)

    -- Icon text
    local iconText = icon:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    iconText:SetPoint("CENTER", icon, "CENTER", 0, 0)
    iconText:SetText("⚙")

    -- Make draggable
    icon:SetMovable(true)
    icon:EnableMouse(true)
    icon:RegisterForDrag("LeftButton")
    icon:SetScript("OnDragStart", function(dragFrame)
        dragFrame:StartMoving()
    end)
    icon:SetScript("OnDragStop", function(dragFrame)
        dragFrame:StopMovingOrSizing()
        -- Save minimap icon position
        if BGCommsDB then
            BGCommsDB.minimapIconX = dragFrame:GetPoint() and (select(4, dragFrame:GetPoint())) or 50
            BGCommsDB.minimapIconY = dragFrame:GetPoint() and (select(5, dragFrame:GetPoint())) or -70
        end
    end)

    -- Click to toggle settings
    icon:SetScript("OnClick", function()
        Settings:ToggleFrame()
    end)

    self.minimapIcon = icon
end

-- Create macro buttons dynamically
function UI:CreateMacroButtons(parentFrame, startY)
    -- Clear existing macro buttons
    for _, button in ipairs(self.macroButtons) do
        button:Hide()
    end
    self.macroButtons = {}

    local macros = Macros:GetMacros()
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
            Macros:ExecuteMacro(macroName)
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

function UI:CreateFrame()
    if self.frame then return end

    -- Create main frame
    local frame = CreateFrame("Frame", "BGCommsFrame", UIParent)
    frame:SetSize(200, 100)

    -- Restore window position from SavedVariables or use defaults
    local posX = BGCommsDB and BGCommsDB.windowX or -300
    local posY = BGCommsDB and BGCommsDB.windowY or 200
    frame:SetPoint("CENTER", UIParent, "CENTER", posX, posY)

    frame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.5)
    frame:SetBackdropBorderColor(1, 1, 1, 0.8)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(dragFrame)
        dragFrame:StopMovingOrSizing()
        -- Save window position to SavedVariables
        if BGCommsDB then
            BGCommsDB.windowX = dragFrame:GetLeft()
            BGCommsDB.windowY = dragFrame:GetTop()
        end
    end)

    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", frame, "TOP", 0, -10)
    title:SetText("BG Comms")

    -- Gear/Settings button
    local gearButton = CreateFrame("Button", "BGGearButton", frame, "GameMenuButtonTemplate")
    gearButton:SetSize(25, 25)
    gearButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -25)
    gearButton:SetText("⚙")
    gearButton:SetScript("OnClick", function()
        Settings:ToggleFrame()
    end)

    -- Opacity minus button
    local opacityMinusButton = CreateFrame("Button", "BGOpacityMinusButton", frame, "GameMenuButtonTemplate")
    opacityMinusButton:SetSize(25, 25)
    opacityMinusButton:SetPoint("LEFT", gearButton, "RIGHT", 2, 0)
    opacityMinusButton:SetText("-")
    opacityMinusButton:SetScript("OnClick", function()
        self:AdjustOpacity(-0.1)
    end)

    -- Opacity plus button
    local opacityPlusButton = CreateFrame("Button", "BGOpacityPlusButton", frame, "GameMenuButtonTemplate")
    opacityPlusButton:SetSize(25, 25)
    opacityPlusButton:SetPoint("LEFT", opacityMinusButton, "RIGHT", 2, 0)
    opacityPlusButton:SetText("+")
    opacityPlusButton:SetScript("OnClick", function()
        self:AdjustOpacity(0.1)
    end)

    -- Lock button
    local lockButton = CreateFrame("Button", "BGLockButton", frame, "GameMenuButtonTemplate")
    lockButton:SetSize(30, 25)
    lockButton:SetPoint("LEFT", opacityPlusButton, "RIGHT", 5, 0)
    lockButton:SetText("🔓")
    lockButton:SetScript("OnClick", function()
        self:ToggleLock()
    end)

    self.gearButton = gearButton
    self.lockButton = lockButton
    self.opacityMinusButton = opacityMinusButton
    self.opacityPlusButton = opacityPlusButton

    -- CLEAR button
    local clearButton = CreateFrame("Button", "BGClearButton", frame, "GameMenuButtonTemplate")
    clearButton:SetSize(80, 25)
    clearButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -55)
    clearButton:SetText("CLEAR")
    clearButton:SetScript("OnClick", function()
        Communications:SendClear()
    end)

    -- INC button
    local incButton = CreateFrame("Button", "BGIncButton", frame, "GameMenuButtonTemplate")
    incButton:SetSize(80, 25)
    incButton:SetPoint("LEFT", clearButton, "RIGHT", 10, 0)
    incButton:SetText("INC")
    incButton:SetScript("OnClick", function()
        local location = Locations:GetPlayerLocation()
        Communications:SendIncoming(location)
    end)

    self.frame = frame
    self.clearButton = clearButton
    self.incButton = incButton

    -- Create macro buttons (starting below CLEAR/INC buttons)
    self:CreateMacroButtons(frame, -80)

    -- Create minimap icon
    self:CreateMinimapIcon()

    -- Apply saved lock state
    self:ApplyLockState()

    -- Apply saved opacity
    local opacity = BGCommsDB and BGCommsDB.backgroundOpacity or 0.5
    self:ApplyOpacity(opacity)
end

function UI:ToggleFrame()
    if self.frame then
        if self.frame:IsShown() then
            self.frame:Hide()
        else
            self.frame:Show()
        end
    else
        self:CreateFrame()
        self.frame:Show()
    end
end

function UI:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

function UI:Show()
    if not self.frame then
        self:CreateFrame()
    end
    self.frame:Show()
end

-- Refresh the UI (e.g., when macros are added/removed)
function UI:RefreshUI()
    if self.frame then
        self:CreateMacroButtons(self.frame, -30)
    end
end

return UI
