-- test_locations.lua - Tests for the Locations module

describe("Locations", function()
    local Locations

    before_each(function()
        Locations = require("Locations")
    end)

    describe("GetZone", function()
        it("should return a zone from default zones", function()
            local zone = Locations:GetZone(1)
            assert.is_not_nil(zone)
            assert.is_string(zone)
        end)

        it("should return nil for out-of-range index", function()
            local zone = Locations:GetZone(999)
            assert.is_nil(zone)
        end)
    end)

    describe("Arathi Basin zones", function()
        it("should have the expected zones", function()
            assert.is_equal("Stables", Locations.ArathiBasin[1])
            assert.is_equal("Blacksmith", Locations.ArathiBasin[2])
            assert.is_equal("Farm", Locations.ArathiBasin[3])
            assert.is_equal("Lumber Mill", Locations.ArathiBasin[4])
            assert.is_equal("Gold Mine", Locations.ArathiBasin[5])
        end)
    end)

    describe("Default zones", function()
        it("should have at least 3 default zones", function()
            assert.is_true(#Locations.Default >= 3)
        end)
    end)
end)
