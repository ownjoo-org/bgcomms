-- Macros.lua - Manage custom battleground communication macros

local Communications = require("Communications")

local Macros = {}

-- Add a custom macro
function Macros:AddMacro(name, message)
    if not BGCommsCharDB then
        BGCommsCharDB = {}
    end
    if not BGCommsCharDB.customMacros then
        BGCommsCharDB.customMacros = {}
    end

    BGCommsCharDB.customMacros[name] = message
    return true
end

-- Remove a custom macro
function Macros:RemoveMacro(name)
    if BGCommsCharDB and BGCommsCharDB.customMacros then
        BGCommsCharDB.customMacros[name] = nil
        return true
    end
    return false
end

-- Get all custom macros
function Macros:GetMacros()
    if BGCommsCharDB and BGCommsCharDB.customMacros then
        return BGCommsCharDB.customMacros
    end
    return {}
end

-- Execute a custom macro (send its message)
function Macros:ExecuteMacro(name)
    local macros = self:GetMacros()
    local message = macros[name]

    if message then
        Communications:SendMessage(message)
        return true
    end
    return false
end

-- List all macros (for debugging/admin)
function Macros:ListMacros()
    local macros = self:GetMacros()
    if not next(macros) then
        print("|cFF00FF00[BGComms]|r No custom macros defined.")
        return
    end

    print("|cFF00FF00[BGComms]|r Custom Macros:")
    for name, message in pairs(macros) do
        print(string.format("  |cFFFFFF00%s:|r %s", name, message))
    end
end

return Macros
