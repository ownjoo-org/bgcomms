-- test_locations.lua - Tests for the Locations module

describe("Locations", function()
    local Locations

    before_each(function()
        Locations = require("Locations")

        -- Mock WoW APIs
        _G.C_Map = {
            GetBestMapID = function() return nil end,
            GetMapInfo = function() return nil end,
        }

        _G.GetSubZoneText = function() return "" end
        _G.GetRealZoneText = function() return "" end

        _G.C_PvP = {
            IsInBattleground = function() return false end
        }

        _G.BGCommsLogger = {
            Debug = function() end,
        }
    end)

    describe("BattlegroundLocations", function()
        it("should have Arathi Basin zones", function()
            assert.is_equal("Stables", Locations.ArathiBasin[1])
            assert.is_equal("Blacksmith", Locations.ArathiBasin[2])
            assert.is_equal("Farm", Locations.ArathiBasin[3])
            assert.is_equal("Lumber Mill", Locations.ArathiBasin[4])
            assert.is_equal("Gold Mine", Locations.ArathiBasin[5])
        end)

        it("should have Alterac Valley zones", function()
            assert.is_equal("Dun Baldar", Locations.AlteracValley[1])
            assert.is_equal("Frostwolf Keep", Locations.AlteracValley[2])
            assert.is_equal("Galv", Locations.AlteracValley[3])
            assert.is_equal("Thrall", Locations.AlteracValley[4])
        end)

        it("should have Warsong Gulch zones", function()
            assert.is_equal("Alliance Base", Locations.WarsongGulch[1])
            assert.is_equal("Horde Base", Locations.WarsongGulch[2])
            assert.is_equal("Midfield", Locations.WarsongGulch[3])
        end)

        it("should have Temple of Kotmogu zones", function()
            assert.is_equal("North", Locations.TempleOfKotmogu[1])
            assert.is_equal("South", Locations.TempleOfKotmogu[2])
            assert.is_equal("East", Locations.TempleOfKotmogu[3])
            assert.is_equal("West", Locations.TempleOfKotmogu[4])
            assert.is_equal("Center", Locations.TempleOfKotmogu[5])
        end)

        it("should have Silvershard Mines zones", function()
            assert.is_equal("North Mine", Locations.SilvershadMines[1])
            assert.is_equal("South Mine", Locations.SilvershadMines[2])
            assert.is_equal("East Entrance", Locations.SilvershadMines[3])
            assert.is_equal("West Entrance", Locations.SilvershadMines[4])
            assert.is_equal("Center Cart", Locations.SilvershadMines[5])
        end)

        it("should have Deepwind Gorge zones", function()
            assert.is_equal("North Cart", Locations.DeepwindGorge[1])
            assert.is_equal("Center Cart", Locations.DeepwindGorge[2])
            assert.is_equal("South Cart", Locations.DeepwindGorge[3])
            assert.is_equal("East Side", Locations.DeepwindGorge[4])
            assert.is_equal("West Side", Locations.DeepwindGorge[5])
        end)
    end)

    describe("Default zones", function()
        it("should have at least 3 default zones", function()
            assert.is_true(#Locations.Default >= 3)
        end)

        it("should contain standard location names", function()
            local hasDefense = false
            local hasAttack = false
            local hasMidfield = false

            for _, zone in ipairs(Locations.Default) do
                if zone == "Defense" then hasDefense = true end
                if zone == "Attack" then hasAttack = true end
                if zone == "Midfield" then hasMidfield = true end
            end

            assert.is_true(hasDefense and hasAttack and hasMidfield)
        end)
    end)

    describe("GetCurrentBattlegroundType", function()
        it("should return nil when not in battleground", function()
            _G.C_PvP.IsInBattleground = function() return false end
            local bgType = Locations:GetCurrentBattlegroundType()
            assert.is_nil(bgType)
        end)

        it("should return zone name when in battleground", function()
            _G.C_PvP.IsInBattleground = function() return true end
            _G.GetRealZoneText = function() return "Arathi Basin" end
            local bgType = Locations:GetCurrentBattlegroundType()
            assert.is_equal("Arathi Basin", bgType)
        end)
    end)

    describe("GetCurrentBattlegroundZones", function()
        it("should return default zones when not in battleground", function()
            _G.C_PvP.IsInBattleground = function() return false end
            local zones = Locations:GetCurrentBattlegroundZones()
            assert.is_equal(zones, Locations.Default)
        end)

        it("should return Arathi Basin zones in Arathi Basin", function()
            _G.C_PvP.IsInBattleground = function() return true end
            _G.GetRealZoneText = function() return "Arathi Basin" end
            local zones = Locations:GetCurrentBattlegroundZones()
            assert.is_equal("Stables", zones[1])
            assert.is_equal("Blacksmith", zones[2])
        end)

        it("should return default zones for unknown battleground", function()
            _G.C_PvP.IsInBattleground = function() return true end
            _G.GetRealZoneText = function() return "Unknown Battleground" end
            local zones = Locations:GetCurrentBattlegroundZones()
            assert.is_equal(zones, Locations.Default)
        end)
    end)

    describe("GetZone", function()
        it("should return a zone from current battleground zones", function()
            local zone = Locations:GetZone(1)
            assert.is_not_nil(zone)
            assert.is_string(zone)
        end)

        it("should return nil for out-of-range index", function()
            local zone = Locations:GetZone(999)
            assert.is_nil(zone)
        end)
    end)

    describe("GetPlayerLocation", function()
        it("should return Location when no zone detected", function()
            _G.C_Map.GetBestMapID = function() return nil end
            _G.GetSubZoneText = function() return "" end
            _G.GetRealZoneText = function() return "" end
            local location = Locations:GetPlayerLocation()
            assert.is_equal("Location", location)
        end)

        it("should prefer C_Map API if available", function()
            _G.C_Map.GetBestMapID = function() return 1 end
            _G.C_Map.GetMapInfo = function() return { name = "Main Base" } end
            local location = Locations:GetPlayerLocation()
            assert.is_equal("Main Base", location)
        end)

        it("should fallback to GetSubZoneText if C_Map unavailable", function()
            _G.C_Map.GetBestMapID = function() return nil end
            _G.GetSubZoneText = function() return "Blacksmith" end
            local location = Locations:GetPlayerLocation()
            assert.is_equal("Blacksmith", location)
        end)

        it("should fallback to GetRealZoneText if subzone empty", function()
            _G.C_Map.GetBestMapID = function() return nil end
            _G.GetSubZoneText = function() return "" end
            _G.GetRealZoneText = function() return "Arathi Basin" end
            local location = Locations:GetPlayerLocation()
            assert.is_equal("Arathi Basin", location)
        end)
    end)

    describe("GetBattlegroundLocationMap", function()
        it("should contain all known battlegrounds", function()
            local map = Locations:GetBattlegroundLocationMap()
            assert.is_not_nil(map["Arathi Basin"])
            assert.is_not_nil(map["Alterac Valley"])
            assert.is_not_nil(map["Warsong Gulch"])
            assert.is_not_nil(map["Temple of Kotmogu"])
            assert.is_not_nil(map["Silvershard Mines"])
            assert.is_not_nil(map["Deepwind Gorge"])
        end)
    end)
end)
