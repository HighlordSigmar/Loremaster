-- Runs Turtle WoW's real FrameXML QuestLogFrame.lua (quest log + tracker code)
-- with Loremaster's Levels.lua, on mock frames.
local FRAMEXML = "/home/claude/ref/turtle_QuestLogFrame.lua"
local DIR = "/home/claude/addon/Loremaster/"

bit = { band = function(a, b) local r, v = 0, 1 while a > 0 and b > 0 do local ra, rb = math.mod(a, 2), math.mod(b, 2) if ra == 1 and rb == 1 then r = r + v end a, b, v = (a - ra) / 2, (b - rb) / 2, v * 2 end return r end }
format, gsub, tremove, tinsert, strlen = string.format, string.gsub, table.remove, table.insert, string.len
getglobal = function(k) return _G[k] end; setglobal = function(k, v) _G[k] = v end

-- frames
local M = {}
local MT = { __index = function(t, k)
  if M[k] then return M[k] end
  if string.find(k, "^%u") then return function() end end
end }
local function Frame(name, kind)
  local f = setmetatable({ _name = name, _text = nil, _shown = true, _kind = kind or "Frame" }, MT)
  if name then _G[name] = f end
  return f
end
function M:SetText(t) self._text = t end
function M:GetText() return self._text end
function M:GetWidth() return self._text and string.len(self._text) * 6 or (self._w or 100) end
function M:SetWidth(w) self._w = w end
function M:Show() self._shown = true end
function M:Hide() self._shown = false end
function M:IsVisible() return self._shown end
function M:IsShown() return self._shown end
function M:GetID() return self._id end
function M:GetName() return self._name end
function M:SetScript(k, f) self["_" .. k] = f end
function M:GetScript(k) return self["_" .. k] end
function M:StartMoving() end
function M:StopMovingOrSizing() end
function M:RegisterEvent() end
function M:CreateFontString(name) return Frame(name, "FontString") end
function M:CreateTexture() return Frame(nil, "Texture") end
function M:GetFrameLevel() return 1 end
function M:GetCenter() return 0, 0 end
function M:GetEffectiveScale() return 1 end
function M:GetPoint() return "CENTER", nil, "CENTER", 0, 0 end
function M:GetValue() return 0 end
function CreateFrame(kind, name, parent, template)
  local f = Frame(name, kind)
  if template == "FauxScrollFrameTemplate" then Frame(name .. "ScrollBar") end
  return f
end
UIParent, Minimap, GameTooltip = Frame("UIParent"), Frame("Minimap"), Frame("GameTooltip")
ChatFrameEditBox = Frame("ChatFrameEditBox"); ChatFrameEditBox._shown = false
function ChatFrameEditBox:Insert(t) print("  chat box gets: '" .. t .. "'") end
UISpecialFrames, SlashCmdList = {}, {}
DEFAULT_CHAT_FRAME = { AddMessage = function(self, m) print("[chat] " .. string.gsub(string.gsub(m, "|c%x%x%x%x%x%x%x%x", ""), "|r", "")) end }
for i = 1, 24 do
  local b = Frame("QuestLogTitle" .. i, "Button"); b._id = i
  for _, s in ipairs({ "Tag", "GroupMates", "Check", "NormalText", "Highlight" }) do Frame("QuestLogTitle" .. i .. s) end
end
for i = 1, 30 do Frame("QuestWatchLine" .. i, "FontString") end
for _, n in ipairs({ "QuestLogFrame", "QuestLogDummyText", "QuestLogHighlightFrame", "EmptyQuestLogFrame", "QuestLogFrameAbandonButton",
  "QuestLogDetailScrollFrame", "QuestLogExpandButtonFrame", "QuestLogQuestCount", "QuestLogCountMiddle", "QuestLogListScrollFrame",
  "QuestLogCollapseAllButton", "QuestFramePushQuestButton", "QuestLogQuestTitle", "QuestWatchFrame", "QuestLogTrackTracking",
  "QuestLogSkillHighlight", "QuestLogObjectivesText", "QuestLogQuestDescription", "QuestLogDescriptionTitle" }) do Frame(n) end
function FauxScrollFrame_GetOffset() return 0 end
function FauxScrollFrame_Update() end
function UIParent_ManageFramePositions() end
function IsShiftKeyDown() return SHIFT end
QuestDifficultyColor = { header = { r = 1, g = 1, b = 1 } }
HIGHLIGHT_FONT_COLOR = { r = 1, g = 1, b = 1 }; NORMAL_FONT_COLOR = { r = 1, g = 1, b = 0 }
QUEST_LOG_COUNT_TEMPLATE = "%d/%d"; MAX_QUESTLOG_QUESTS = 20; MAX_QUESTWATCH_LINES = 30; MAX_WATCHABLE_QUESTS = 5
FAILED, COMPLETE = "Failed", "Complete"
TIME_REMAINING = "Time remaining:"; MAX_OBJECTIVES = 10
function GetQuestLogTimeLeft() return nil end

-- the quest log (what the server returns)
LOG = {
  { "Westfall", nil, nil, 1 },
  { "The Defias Brotherhood", 18 },
  { "The Deadmines", 22, "Dungeon" },
  { "Elwynn Forest", nil, nil, 1 },
  { "Princess Must Die!", 12 },
  { "Hogger", 11, "Elite", nil, nil, 1 },
  { "Onyxia's Lair", 60, "Raid" },
}
WATCHED = { [5] = true }
SELECTED = 2
function GetNumQuestLogEntries() return table.getn(LOG), 5 end
function GetQuestLogTitle(i) local e = LOG[i]; if not e then return nil end return e[1], e[2], e[3], e[4], nil, e[6] end
function GetQuestLogSelection() return SELECTED end
function SelectQuestLogEntry(i) SELECTED = i end
function IsQuestWatched(i) return WATCHED[i] end
function GetNumPartyMembers() return 0 end
function GetQuestLogPushable() return nil end
function GetNumQuestWatches() local n = 0 for _ in pairs(WATCHED) do n = n + 1 end return n end
function GetQuestIndexForWatch(n) local k = {} for i in pairs(WATCHED) do table.insert(k, i) end table.sort(k) return k[n] end
function GetNumQuestLeaderBoards(i) return 1 end
OBJ = { [2] = { { "Defias Pillager slain: 3/15" }, { "Red Leather Bandana: 15/15", true } }, [5] = { { "Princess slain: 0/1" } } }
function GetQuestLogLeaderBoard(j, i) local o = OBJ[i] and OBJ[i][j]; if o then return o[1], "monster", o[2] end return "Objective " .. j, "monster", nil end
function GetNumQuestLeaderBoards(i) i = i or SELECTED; return OBJ[i] and table.getn(OBJ[i]) or (LOG[i] and LOG[i][6] and 0) or 1 end
function IsCurrentQuestFailed() return nil end
function GetQuestLogQuestText() return "desc", "obj" end
function GetDifficultyColor() return { r = 1, g = 1, b = 0 } end
function GetTime() return 0 end
function UnitRace() return "Human", "Human" end
function UnitClass() return "Warrior", "WARRIOR" end
function UnitFactionGroup() return "Alliance" end
function UnitLevel() return 12 end
function GetRealZoneText() return "Elwynn Forest" end
GetZoneText = GetRealZoneText
function GetNumSkillLines() return 0 end
function time() return 1 end
function GetQuestReward() end
function AbandonQuest() end
function GetAbandonQuestName() return nil end

-- the rest of QuestLog_UpdateQuestDetails: anything unknown is a harmless no-op
local Any = setmetatable({}, { __call = function() return 0 end, __index = function(t, k) return function() return 0 end end })
setmetatable(_G, { __index = function(t, k)
  if type(k) == "string" and string.find(k, "^%u") and not string.find(k, "^QuestLogLevelPatch") then return Any end
end })

-- load order in the game: FrameXML first, then the addon
dofile(FRAMEXML)
dofile(DIR .. "Data.lua"); dofile(DIR .. "Core.lua"); dofile(DIR .. "UI.lua"); dofile(DIR .. "Levels.lua"); dofile(DIR .. "Auto.lua"); dofile(DIR .. "Tracker.lua")
Loremaster_DB = { minimap = {} }; Loremaster_Char = { done = {}, ignored = {} }


getn = table.getn
function AddQuestWatch(i) WATCHED[i] = true end
function RemoveQuestWatch(i) WATCHED[i] = nil end
function ShowUIPanel(f) f._shown = true; print("  quest log opened") end
UIErrorsFrame = { AddMessage = function() end }
QuestLogListScrollFrame = Frame("QuestLogListScrollFrame")
Loremaster_DB = { minimap = {} }; Loremaster_Char = { done = {}, ignored = {} }
local E = LoremasterTrackerEvents
NOW = 0; function GetTime() return NOW end
local function frames(sec) for k = 1, sec * 10 do NOW = NOW + 0.1; this = E; E._OnUpdate(); if LoremasterTracker._shown then this = LoremasterTracker; LoremasterTracker._OnUpdate() end end end
local function ev(e) this = E; event = e; E._OnEvent(); frames(1.5) end
local function show(label)
  print("---- " .. label .. " ----")
  if not LoremasterTracker._shown then print("  tracker hidden") else
    print("  " .. LoremasterTrackerHeader.text._text)
    for i = 1, 10 do local r = rawget(_G, "LoremasterTrackerQuest" .. i); if r and r._shown then print("  quest: " .. r.text._text) end end
    for i = 1, 20 do local l = rawget(_G, "LoremasterTrackerLine" .. i); if l and l._shown then print("    " .. l._text) end end
  end
  print("  game tracker shown: " .. tostring(QuestWatchFrame._shown))
end
Loremaster:ScanLog(); Loremaster:ScanLog()
ev("PLAYER_ENTERING_WORLD")
show("first login: takes over the game's watched quest (Princess Must Die!)")

-- shift-click "The Defias Brotherhood" (quest log line 2), chat box closed
SHIFT = true; this = QuestLogTitle2; QuestLogTitleButton_OnClick("LeftButton"); SHIFT = false
ev("QUEST_LOG_UPDATE")
show("after shift-click on The Defias Brotherhood")
print("  check mark next to it in the quest log: " .. tostring(QuestLogTitle2Check._shown) .. ", game watch untouched: " .. tostring(WATCHED[2] == nil))

-- progress, and the quest is done
OBJ[2][1] = { "Defias Pillager slain: 15/15", true }; LOG[2][6] = 1
QuestWatchFrame._shown = true; QuestWatch_Update()  -- the game tries to show its tracker
ev("QUEST_LOG_UPDATE")
show("Defias Brotherhood complete, game tries to show its tracker")

-- progress WITHOUT any event reaching Loremaster: the tracker reads it within a second
OBJ[5][1] = { "Princess slain: 1/1", true }
frames(1.2)
show("progress with no event: picked up by the tracker's own check")
OBJ[5][1] = { "Princess slain: 0/1" }

-- click a tracked quest: opens the quest log there
this = LoremasterTrackerQuest1; arg1 = "LeftButton"; LoremasterTrackerQuest1._OnClick(); print("  selected in the quest log: line " .. SELECTED)
-- turned in: leaves the log, leaves the tracker
table.remove(LOG, 2); OBJ[2] = nil; OBJ[4] = OBJ[5]; OBJ[5] = nil
Loremaster:ScanLog(); ev("QUEST_LOG_UPDATE")
show("Defias Brotherhood turned in")
print("  still saved as tracked: " .. tostring(Loremaster_Char.tracked["The Defias Brotherhood"]))
-- turned in right away (before Loremaster re-read its log): gone at once
table.insert(LOG, { "Lost Necklace", 6 })
Loremaster:ScanLog(); Loremaster_Char.tracked["Lost Necklace"] = true; ev("QUEST_LOG_UPDATE")
show("tracking Lost Necklace")
table.remove(LOG); ev("QUEST_LOG_UPDATE")
show("Lost Necklace turned in (Loremaster's own copy of the log not re-read yet)")
print("  still saved as tracked: " .. tostring(Loremaster_Char.tracked["Lost Necklace"]))

-- right-click: stop tracking
this = LoremasterTrackerQuest1; arg1 = "RightButton"; LoremasterTrackerQuest1._OnClick(); ev("QUEST_LOG_UPDATE")
show("right-click on Princess Must Die!")

-- off: the game's tracker and shift-click work as before
SlashCmdList["LOREMASTER"]("tracker")
SHIFT = true; this = QuestLogTitle4; QuestLogTitleButton_OnClick("LeftButton"); SHIFT = false
print("  tracker off, shift-click sets the game's watch: " .. tostring(WATCHED[4]))
SlashCmdList["LOREMASTER"]("tracker")
SlashCmdList["LOREMASTER"]("tracker lock"); SlashCmdList["LOREMASTER"]("tracker reset")
print("DONE")
