-- Locations.lua - Battleground location definitions
-- Easy to modify: just add new locations to the relevant battleground table

local Locations = {}

-- Arathi Basin zones
Locations.ArathiBasin = {
    "Stables",
    "Blacksmith",
    "Farm",
    "Lumber Mill",
    "Gold Mine",
}

-- Alterac Valley zones
Locations.AlteracValley = {
    "Dun Baldar",
    "Frostwolf Keep",
    "Galv",
    "Thrall",
}

-- Warsong Gulch zones
Locations.WarsongGulch = {
    "Alliance Base",
    "Horde Base",
    "Midfield",
}

-- Bastion of Twilight (example for future expansion)
Locations.BastionOfTwilight = {
    "East Flag",
    "West Flag",
    "Midfield",
}

-- Temple of Kotmogu
Locations.TempleOfKotmogu = {
    "North",
    "South",
    "East",
    "West",
    "Center",
}

-- Silvershard Mines
Locations.SilvershadMines = {
    "North Mine",
    "South Mine",
    "East Entrance",
    "West Entrance",
    "Center Cart",
}

-- Deepwind Gorge
Locations.DeepwindGorge = {
    "North Cart",
    "Center Cart",
    "South Cart",
    "East Side",
    "West Side",
}

-- Default/fallback locations
Locations.Default = {
    "Defense",
    "Attack",
    "Midfield",
}

-- Detect current battleground type
function Locations:GetCurrentBattlegroundType()
    -- Check if player is in a battleground
    if not IsInBattleground() then
        return nil
    end

    -- Get battleground information
    local bgName, bgType, _, _, _, _, _ = GetBattlegroundInfo()

    -- Return battleground type/name
    return bgType or bgName
end

-- Map battleground names to location tables
function Locations:GetBattlegroundLocationMap()
    return {
        -- Common battleground identifiers
        ["Arathi Basin"] = self.ArathiBasin,
        ["Alterac Valley"] = self.AlteracValley,
        ["Warsong Gulch"] = self.WarsongGulch,
        ["Temple of Kotmogu"] = self.TempleOfKotmogu,
        ["Silvershard Mines"] = self.SilvershadMines,
        ["Deepwind Gorge"] = self.DeepwindGorge,
        ["Battleground of Twilight"] = self.BastionOfTwilight,
    }
end

-- Get locations for current battleground
function Locations:GetCurrentBattlegroundZones()
    local bgType = self:GetCurrentBattlegroundType()

    if not bgType then
        -- Not in a battleground, return default zones
        return self.Default
    end

    -- Look up the location table for this battleground
    local map = self:GetBattlegroundLocationMap()
    local zones = map[bgType]

    if zones then
        return zones
    else
        -- Unknown battleground, fall back to default
        return self.Default
    end
end

-- Get a zone name by index
function Locations:GetZone(index)
    local zones = self:GetCurrentBattlegroundZones()
    return zones[index]
end

-- Get the player's current location
function Locations:GetPlayerLocation()
    -- Try to get sub-zone (more specific location)
    local subZone = GetSubZoneText()
    if subZone and subZone ~= "" then
        return subZone
    end

    -- Fall back to main zone
    local zone = GetRealZoneText()
    if zone and zone ~= "" then
        return zone
    end

    -- If no zone detected, return generic location
    return "Location"
end

return Locations
