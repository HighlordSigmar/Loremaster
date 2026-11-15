-- MapLevels.lua: the hovered zone's name gets its level range, in retail colors
local DIR = "/home/claude/addon/Loremaster/"
format = string.format
LEVEL = 1
function UnitLevel() return LEVEL end
QuestDifficultyColor = {
  impossible = { r = 1, g = .1, b = .1 }, verydifficult = { r = 1, g = .5, b = .25 },
  difficult = { r = 1, g = 1, b = 0 }, standard = { r = .25, g = .75, b = .25 }, trivial = { r = .5, g = .5, b = .5 } }
function GetQuestGreenRange() return 8 end
function GetDifficultyColor(level, isQuest)
	local levelDiff = level - UnitLevel("player");
	local greenRange = isQuest and 25 or GetQuestGreenRange();
	local color;
	if ( levelDiff >= 5 ) then
		color = QuestDifficultyColor["impossible"];
	elseif ( levelDiff >= 3 ) then
		color = QuestDifficultyColor["verydifficult"];
	elseif ( levelDiff >= -2 ) then
		color = QuestDifficultyColor["difficult"];
	elseif ( -levelDiff <= greenRange ) then
		color = QuestDifficultyColor["standard"];
	else
		color = QuestDifficultyColor["trivial"];
	end
	return color;
end
Loremaster = { Print = function(m) print("[chat] " .. m) end }
Loremaster_DB = {}
WorldMapFrame = {}
WorldMapFrameAreaLabel = { SetText = function(self, t) self.text = t end }
function WorldMapButton_OnUpdate(elapsed) if not WorldMapFrame.poiHighlight then WorldMapFrameAreaLabel:SetText(WorldMapFrame.areaName) end end  -- the game's part
dofile(DIR .. "MapLevels.lua")
local function show(t) t = string.gsub(t or "nil", "|c(%x%x)(%x%x)(%x%x)(%x%x)", function(a, r, g, b) return "<" .. r .. g .. b .. ">" end); return (string.gsub(t, "|r", "</>")) end
local function hover(name, level)
  LEVEL = level; WorldMapFrame.areaName = name; WorldMapButton_OnUpdate(0.02)
  print(string.format("level %2d, hover %-22s -> %s", level, tostring(name), show(WorldMapFrameAreaLabel.text)))
end
hover("Westfall", 5); hover("Westfall", 9); hover("Westfall", 15); hover("Westfall", 22); hover("Westfall", 35)
hover("Stormwind City", 30); hover("Alah'Thalas", 3)
hover("Tel'Abim", 40); hover("Grim Reaches", 35); hover("Moonglade", 20)
hover("GM Island", 20); hover(nil, 20); hover("", 20)
WorldMapFrame.poiHighlight = 1; WorldMapFrameAreaLabel.text = "Some POI"; WorldMapFrame.areaName = "Westfall"; WorldMapButton_OnUpdate(0.02)
print("hovering a map marker, label stays: " .. show(WorldMapFrameAreaLabel.text)); WorldMapFrame.poiHighlight = nil
Loremaster:MapLevelsCommand(); hover("Westfall", 15); Loremaster:MapLevelsCommand(); hover("Westfall", 15)
print("DONE")
