-- BGCommsLocations.lua - Battleground location definitions
-- Easy to modify: just add new locations to the relevant battleground table

BGCommsLocations = {}

-- Track last location to detect changes
BGCommsLocations.lastLocation = nil

-- Arathi Basin zones
BGCommsLocations.ArathiBasin = {
    "Stables",
    "Blacksmith",
    "Farm",
    "Lumber Mill",
    "Gold Mine",
}

-- Alterac Valley zones
BGCommsLocations.AlteracValley = {
    "Dun Baldar",
    "Frostwolf Keep",
    "Galv",
    "Thrall",
}

-- Warsong Gulch zones
BGCommsLocations.WarsongGulch = {
    "Alliance Base",
    "Horde Base",
    "Midfield",
}

-- Bastion of Twilight (example for future expansion)
BGCommsLocations.BastionOfTwilight = {
    "East Flag",
    "West Flag",
    "Midfield",
}

-- Temple of Kotmogu
BGCommsLocations.TempleOfKotmogu = {
    "North",
    "South",
    "East",
    "West",
    "Center",
}

-- Silvershard Mines
BGCommsLocations.SilvershadMines = {
    "North Mine",
    "South Mine",
    "East Entrance",
    "West Entrance",
    "Center Cart",
}

-- Deepwind Gorge
BGCommsLocations.DeepwindGorge = {
    "North Cart",
    "Center Cart",
    "South Cart",
    "East Side",
    "West Side",
}

-- Default/fallback locations
BGCommsLocations.Default = {
    "Defense",
    "Attack",
    "Midfield",
}

-- Detect current battleground type
function BGCommsLocations:GetCurrentBattlegroundType()
    -- Check if player is in a battleground (using C_PvP namespace for WoW 12.0)
    local inBattleground = false
    if C_PvP and C_PvP.IsInBattleground then
        inBattleground = C_PvP.IsInBattleground()
    end

    if not inBattleground then
        return nil
    end

    -- Get the current zone name via C_Map API
    if C_Map and C_Map.GetBestMapForUnit then
        local mapID = C_Map.GetBestMapForUnit("player")
        if mapID then
            local mapInfo = C_Map.GetMapInfo(mapID)
            if mapInfo and mapInfo.name then
                return mapInfo.name
            end
        end
    end

    -- Fallback to legacy API if C_Map unavailable
    if GetRealZoneText then
        return GetRealZoneText()
    end

    return nil
end

-- Map battleground names to location tables
function BGCommsLocations:GetBattlegroundLocationMap()
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
function BGCommsLocations:GetCurrentBattlegroundZones()
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
function BGCommsLocations:GetZone(index)
    local zones = self:GetCurrentBattlegroundZones()
    return zones[index]
end

-- Get the player's current location
function BGCommsLocations:GetPlayerLocation()
    local location = nil

    -- WoW 12.0+ uses C_Map for zone information
    if C_Map and C_Map.GetBestMapForUnit then
        local mapID = C_Map.GetBestMapForUnit("player")
        if mapID then
            local mapInfo = C_Map.GetMapInfo(mapID)
            if mapInfo and mapInfo.name then
                location = mapInfo.name
            end
        end
    end

    -- Fallback to legacy API if available
    if not location and GetSubZoneText then
        local subZone = GetSubZoneText()
        if subZone and subZone ~= "" then
            location = subZone
        end
    end

    if not location and GetRealZoneText then
        local zone = GetRealZoneText()
        if zone and zone ~= "" then
            location = zone
        end
    end

    if not location then
        location = "Location"
    end

    -- Log location changes only (avoid spam of same location)
    if location ~= self.lastLocation then
        BGCommsLogger:Debug("Location changed to: " .. location)
        self.lastLocation = location
    end

    return location
end
