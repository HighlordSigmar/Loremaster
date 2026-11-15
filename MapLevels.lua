-- Loremaster: level ranges of the zones on the world map, like retail
-- Hover a zone on the continent map: "Westfall (10-20)". The range is
-- colored for your level: red/orange when it is above you, yellow while you
-- are in it, green/gray when you have outgrown it.
--
-- Ranges for OctoWoW 1.18.1, as audited against the current client by
-- Questie-Octo (Docs/ZONE_LEVEL_RANGE_AUDIT_2026-08-21.md, MIT license),
-- based on LevelRange-Turtle / LevelRange-Octo. Keyed by the name the map
-- shows (the client has two areas named "Westfall"; the name is unique here).

local ZQ = Loremaster

local RANGES = {
  -- Eastern Kingdoms
  ["Elwynn Forest"] = { 1, 10 },        ["Dun Morogh"] = { 1, 10 },
  ["Tirisfal Glades"] = { 1, 10 },      ["Loch Modan"] = { 10, 20 },
  ["Silverpine Forest"] = { 10, 20 },   ["Westfall"] = { 10, 20 },
  ["Redridge Mountains"] = { 15, 25 },  ["Duskwood"] = { 18, 30 },
  ["Hillsbrad Foothills"] = { 20, 30 }, ["Wetlands"] = { 20, 30 },
  ["Alterac Mountains"] = { 30, 40 },   ["Arathi Highlands"] = { 30, 40 },
  ["Stranglethorn Vale"] = { 30, 45 },  ["Badlands"] = { 35, 45 },
  ["Swamp of Sorrows"] = { 35, 45 },    ["The Hinterlands"] = { 40, 50 },
  ["Searing Gorge"] = { 43, 50 },       ["Blasted Lands"] = { 45, 55 },
  ["Burning Steppes"] = { 50, 58 },     ["Western Plaguelands"] = { 51, 58 },
  ["Eastern Plaguelands"] = { 53, 60 }, ["Deadwind Pass"] = { 55, 60 },
  -- Kalimdor
  ["Durotar"] = { 1, 10 },              ["Mulgore"] = { 1, 10 },
  ["Teldrassil"] = { 1, 10 },           ["Darkshore"] = { 10, 20 },
  ["The Barrens"] = { 10, 25 },         ["Stonetalon Mountains"] = { 15, 27 },
  ["Ashenvale"] = { 18, 30 },           ["Thousand Needles"] = { 25, 35 },
  ["Desolace"] = { 30, 40 },            ["Dustwallow Marsh"] = { 35, 45 },
  ["Feralas"] = { 40, 50 },             ["Tanaris"] = { 40, 50 },
  ["Azshara"] = { 45, 55 },             ["Felwood"] = { 48, 55 },
  ["Un'Goro Crater"] = { 48, 55 },      ["Silithus"] = { 55, 60 },
  ["Winterspring"] = { 55, 60 },        ["Moonglade"] = { 1, 60 },
  -- Turtle / OctoWoW zones
  ["Thalassian Highlands"] = { 1, 10 }, ["Blackstone Island"] = { 1, 10 },
  ["Northwind"] = { 28, 34 },           ["Balor"] = { 29, 34 },
  ["Grim Reaches"] = { 33, 38 },        ["Gilneas"] = { 39, 46 },
  ["Icepoint Rock"] = { 40, 50 },       ["Gillijim's Isle"] = { 48, 53 },
  ["Lapidis Isle"] = { 48, 53 },        ["Moonwhisper Coast"] = { 50, 56 },
  ["Tel'Abim"] = { 54, 60 },            ["Scarlet Enclave"] = { 55, 60 },
  ["Hyjal"] = { 58, 60 },
}

-- capitals show the range of the zone around them
local ALIASES = {
  ["Stormwind City"] = "Elwynn Forest", ["Ironforge"] = "Dun Morogh",
  ["Undercity"] = "Tirisfal Glades",    ["Orgrimmar"] = "Durotar",
  ["Thunder Bluff"] = "Mulgore",        ["Darnassus"] = "Teldrassil",
  ["Alah'Thalas"] = "Thalassian Highlands",
}

function ZQ:ZoneRange(name)
  if not name then return nil end
  name = string.gsub(string.gsub(name, "^%s+", ""), "%s+$", "")
  local range = RANGES[ALIASES[name] or name]
  if range then return range[1], range[2] end
  return nil
end

local function Hex(c)
  return string.format("|cff%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255)
end

-- " (10-20)" in retail's colors for your level
function ZQ:ZoneRangeText(name)
  local min, max = self:ZoneRange(name)
  if not min then return nil end
  local level = UnitLevel("player") or 1
  local color
  if level < min then
    color = GetDifficultyColor(min)
  elseif level > max then
    color = GetDifficultyColor(max - 2)
  else
    color = QuestDifficultyColor and QuestDifficultyColor["difficult"] or { r = 1, g = 1, b = 0 }
  end
  local range = (min == max) and tostring(min) or (min .. "-" .. max)
  return " " .. Hex(color) .. "(" .. range .. ")|r"
end

-- the game writes the hovered zone's name every frame; add the range to it
local MapOnUpdate = WorldMapButton_OnUpdate
if MapOnUpdate then
  WorldMapButton_OnUpdate = function(a1)
    MapOnUpdate(a1)
    if Loremaster_DB and Loremaster_DB.mapLevels == false then return end
    if not WorldMapFrame or WorldMapFrame.poiHighlight then return end
    local name = WorldMapFrame.areaName
    if not name or name == "" then return end
    local text = ZQ:ZoneRangeText(name)
    if text then WorldMapFrameAreaLabel:SetText(name .. text) end
  end
end

-- /lm maplevels
function ZQ:MapLevelsCommand()
  Loremaster_DB.mapLevels = (Loremaster_DB.mapLevels == false)
  self.Print("Zone level ranges on the world map: " .. (Loremaster_DB.mapLevels and "on" or "off"))
end
