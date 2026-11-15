-- Loremaster: its own quest tracker
--
-- A small window with the quests you track, their objectives and progress.
-- It keeps its own list (by quest name, saved per character), so it does not
-- depend on the game's watch list, which other addons or the client can
-- clear. While it is on, the game's tracker is hidden.
--
-- Shift-click a quest in the quest log (chat box closed) to track it or stop
-- tracking it; the quest log shows the usual check mark. In the tracker:
-- click a quest to open it in the quest log, right-click to stop tracking.

local ZQ = Loremaster
local Print = ZQ.Print

local WIDTH = 250

local function On()
  return Loremaster_DB and Loremaster_DB.tracker ~= false and Loremaster_Char and Loremaster_Char.tracked
end

local function PlainTitle(index)
  local title, level, tag, header, _, complete = ZQ.LogTitle(index)
  return title, level, tag, header, complete
end

function ZQ:IsTracked(title)
  return title and Loremaster_Char and Loremaster_Char.tracked and Loremaster_Char.tracked[title] and true or false
end

function ZQ:SetTracked(title, track)
  if not title or not Loremaster_Char or not Loremaster_Char.tracked then return end
  Loremaster_Char.tracked[title] = track and true or nil
  self:UpdateTracker()
end

------------------------------------------------------------------------
-- the window
------------------------------------------------------------------------

local tracker = CreateFrame("Frame", "LoremasterTracker", UIParent)
tracker:SetWidth(WIDTH)
tracker:SetHeight(20)
tracker:SetFrameStrata("LOW")
tracker:SetMovable(true)
tracker:SetClampedToScreen(true)
tracker:Hide()

local header = CreateFrame("Button", "LoremasterTrackerHeader", tracker)
header:SetPoint("TOPLEFT", tracker, "TOPLEFT", 0, 0)
header:SetWidth(WIDTH)
header:SetHeight(16)
header:RegisterForDrag("LeftButton")
header:RegisterForClicks("RightButtonUp")
header.text = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
header.text:SetPoint("LEFT", header, "LEFT", 0, 0)
header:SetScript("OnDragStart", function()
  if not Loremaster_DB.trackerLocked then tracker:StartMoving() end
end)
header:SetScript("OnDragStop", function()
  tracker:StopMovingOrSizing()
  local point, _, relPoint, x, y = tracker:GetPoint()
  Loremaster_DB.trackerPos = { point, relPoint, x, y }
end)
header:SetScript("OnEnter", function()
  GameTooltip:SetOwner(this, "ANCHOR_LEFT")
  GameTooltip:SetText("Loremaster quest tracker")
  GameTooltip:AddLine("Shift-click a quest in the quest log to track it.", 1, 1, 1)
  GameTooltip:AddLine(Loremaster_DB.trackerLocked and "Locked (/lm tracker lock to move it)" or "Drag to move. /lm tracker lock keeps it in place.", .6, .6, .6)
  GameTooltip:Show()
end)
header:SetScript("OnLeave", function() GameTooltip:Hide() end)

local rows, lines = {}, {}

-- a clickable quest name
local function Row(n)
  if rows[n] then return rows[n] end
  local row = CreateFrame("Button", "LoremasterTrackerQuest" .. n, tracker)
  row:SetWidth(WIDTH)
  row:SetHeight(14)
  row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  row.text:SetPoint("LEFT", row, "LEFT", 0, 0)
  row.text:SetWidth(WIDTH)
  row.text:SetHeight(14)
  row.text:SetJustifyH("LEFT")
  row:SetScript("OnClick", function()
    if arg1 == "RightButton" then
      ZQ:SetTracked(this.title, false)
      if QuestLogFrame and QuestLogFrame:IsVisible() then QuestLog_Update() end
    elseif this.index then
      ShowUIPanel(QuestLogFrame)
      QuestLog_SetSelection(this.index)
      QuestLog_Update()
    end
  end)
  row:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT")
    GameTooltip:SetText(this.title or "")
    if this.note then GameTooltip:AddLine(this.note, 1, .6, .2) end
    GameTooltip:AddLine("Click: open it in the quest log", .6, .6, .6)
    GameTooltip:AddLine("Right-click: stop tracking", .6, .6, .6)
    GameTooltip:Show()
  end)
  row:SetScript("OnLeave", function() GameTooltip:Hide() end)
  rows[n] = row
  return row
end

-- an objective line
local function Line(n)
  if lines[n] then return lines[n] end
  local line = tracker:CreateFontString("LoremasterTrackerLine" .. n, "OVERLAY", "GameFontHighlightSmall")
  line:SetWidth(WIDTH - 10)
  line:SetHeight(12)
  line:SetJustifyH("LEFT")
  lines[n] = line
  return line
end

function ZQ:PlaceTracker()
  tracker:ClearAllPoints()
  local pos = Loremaster_DB and Loremaster_DB.trackerPos
  if pos then
    tracker:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
  else
    tracker:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -60, -240)
  end
end

local function Color(r, g, b) return string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255) end

function ZQ:UpdateTracker()
  if not On() then
    tracker:Hide()
    return
  end
  local tracked = Loremaster_Char.tracked

  -- the tracked quests, in quest log order
  local list, seen, collapsed = {}, {}, false
  for i = 1, GetNumQuestLogEntries() do
    local title, level, tag, header, complete = PlainTitle(i)
    if header then
      local _, _, _, _, isCollapsed = ZQ.LogTitle(i)
      if isCollapsed then collapsed = true end
    elseif title then
      seen[title] = true
      if tracked[title] then
        table.insert(list, { index = i, title = title, level = level, tag = tag, complete = complete })
      end
    end
  end
  -- tracked quests that are not in the quest log as the game shows it now:
  -- turned in or abandoned, so stop tracking them. Only when a header is
  -- collapsed can a quest be hidden; then trust what Loremaster saw last.
  -- (An empty log right after login/loading is not trusted.)
  local known = {}
  if collapsed then
    for _, entry in pairs(ZQ.log or {}) do known[entry.title] = entry end
  end
  for title in pairs(tracked) do
    if not seen[title] then
      if known[title] then
        table.insert(list, { title = title, level = known[title].level, hidden = true, ready = known[title].ready })
      elseif ZQ.logready and GetNumQuestLogEntries() > 0 then
        tracked[title] = nil
      end
    end
  end

  local nrow, nline = 0, 0
  local y = -18
  local showLevels = Loremaster_DB.levels ~= false and Loremaster_DB.levelsTracker ~= false
  for _, q in ipairs(list) do
    nrow = nrow + 1
    local row = Row(nrow)
    row.title, row.index, row.note = q.title, q.index, nil
    local name = q.title
    if showLevels and q.level and q.level > 0 then name = ZQ:LevelTag(q.level, q.tag) .. name end
    row.text:SetText(name)
    if q.level and GetDifficultyColor then
      local c = GetDifficultyColor(q.level)
      row.text:SetTextColor(c.r, c.g, c.b)
    else
      row.text:SetTextColor(1, .82, 0)
    end
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", tracker, "TOPLEFT", 0, y)
    row:Show()
    y = y - 14

    local function Add(text, r, g, b)
      nline = nline + 1
      local line = Line(nline)
      line:SetText(text)
      line:SetTextColor(r, g, b)
      line:ClearAllPoints()
      line:SetPoint("TOPLEFT", tracker, "TOPLEFT", 10, y)
      line:Show()
      y = y - 12
    end

    if q.hidden then
      row.note = "Its header is collapsed in the quest log, so its objectives cannot be read."
      if q.ready then Add("Ready to turn in", .2, 1, .2) else Add("(header collapsed in the quest log)", .6, .6, .6) end
    elseif q.complete == -1 then
      Add("Failed", 1, .2, .2)
    else
      local n = GetNumQuestLeaderBoards(q.index)
      if q.complete == 1 or n == 0 then
        Add("Ready to turn in", .2, 1, .2)
      else
        for j = 1, n do
          local text, _, finished = GetQuestLogLeaderBoard(j, q.index)
          if text then
            if finished then Add("- " .. text, .6, .6, .6) else Add("- " .. text, 1, 1, 1) end
          end
        end
      end
    end
    y = y - 4
  end

  for i = nrow + 1, table.getn(rows) do rows[i]:Hide() end
  for i = nline + 1, table.getn(lines) do lines[i]:Hide() end

  if nrow == 0 then
    tracker:Hide()
    return
  end
  header.text:SetText("Quests (" .. nrow .. ")")
  tracker:SetHeight(-y)
  tracker:Show()
end

------------------------------------------------------------------------
-- the game's tracker and quest log
------------------------------------------------------------------------

-- hide the game's tracker while ours is on
local function HideGameTracker()
  if On() and QuestWatchFrame then QuestWatchFrame:Hide() end
end
if QuestWatchFrame then
  local onShow = QuestWatchFrame:GetScript("OnShow")
  QuestWatchFrame:SetScript("OnShow", function()
    if onShow then onShow() end
    if On() then this:Hide() end
  end)
end

-- and again each time the game redraws it
local WatchUpdate = QuestWatch_Update
if WatchUpdate then
  QuestWatch_Update = function(a1)
    local ok, err = pcall(WatchUpdate, a1)
    HideGameTracker()
    -- the game redraws its tracker whenever quest progress changes: so do we
    local ev = LoremasterTrackerEvents
    if ev then ev.soon = GetTime() + 0.1; ev.later = GetTime() + 1.0 end
    if not ok then error(err, 0) end
  end
end

-- the quest log shows a check mark for quests in our list
local drawingLog = false
local OriginalIsQuestWatched = IsQuestWatched
IsQuestWatched = function(index)
  if drawingLog and On() then
    return ZQ:IsTracked((PlainTitle(index)))
  end
  return OriginalIsQuestWatched(index)
end
local LogUpdate = QuestLog_Update
if LogUpdate then
  QuestLog_Update = function(a1, a2)
    if drawingLog then return LogUpdate(a1, a2) end
    drawingLog = true
    local ok, err = pcall(LogUpdate, a1, a2)
    drawingLog = false
    if not ok then error(err, 0) end
  end
end

-- shift-click in the quest log (chat box closed): our tracking, not the game's
local TitleClick = QuestLogTitleButton_OnClick
if TitleClick then
  QuestLogTitleButton_OnClick = function(a1)
    if On() and this and not this.isHeader and IsShiftKeyDown()
      and not (ChatFrameEditBox and ChatFrameEditBox:IsVisible()) then
      local index = this:GetID() + FauxScrollFrame_GetOffset(QuestLogListScrollFrame)
      local title = PlainTitle(index)
      if title then ZQ:SetTracked(title, not ZQ:IsTracked(title)) end
      QuestLog_SetSelection(index)
      QuestLog_Update()
      return
    end
    return TitleClick(a1)
  end
end

------------------------------------------------------------------------
-- events and settings
------------------------------------------------------------------------

-- The game can announce a quest change before the new numbers can be read
-- (on 1.12 the progress shows up a moment later). So: update a moment after
-- any quest event, and every second while the tracker is shown.
local events = CreateFrame("Frame", "LoremasterTrackerEvents")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("QUEST_LOG_UPDATE")
events:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
events:RegisterEvent("QUEST_WATCH_UPDATE")
events:RegisterEvent("QUEST_FINISHED")
events:RegisterEvent("UI_INFO_MESSAGE")      -- "Kobold Vermin slain: 3/10"
events:SetScript("OnEvent", function()
  if event == "PLAYER_ENTERING_WORLD" then
    if Loremaster_Char and not Loremaster_Char.tracked then
      -- first time: start with the quests the game is tracking now
      Loremaster_Char.tracked = {}
      for i = 1, GetNumQuestWatches() do
        local title = PlainTitle(GetQuestIndexForWatch(i))
        if title then Loremaster_Char.tracked[title] = true end
      end
    end
    ZQ:PlaceTracker()
    HideGameTracker()
  end
  -- update now-ish, and once more a bit later
  this.soon = GetTime() + 0.2
  this.later = GetTime() + 1.0
end)
events:SetScript("OnUpdate", function()
  local now = GetTime()
  local due = false
  if this.soon and now >= this.soon then this.soon = nil; due = true end
  if this.later and now >= this.later then this.later = nil; due = true end
  if not due then return end
  ZQ:Safe("updating the quest tracker", ZQ.UpdateTracker)
end)

-- while the tracker is shown it also reads the quest log every second by itself
tracker:SetScript("OnUpdate", function()
  local now = GetTime()
  if now < (this.tick or 0) then return end
  this.tick = now + 1
  ZQ:Safe("updating the quest tracker", ZQ.UpdateTracker)
end)

-- /lm tracker [lock|reset]
function ZQ:TrackerCommand(arg)
  local db = Loremaster_DB
  if arg == "lock" then
    db.trackerLocked = not db.trackerLocked or nil
    Print("Quest tracker " .. (db.trackerLocked and "locked." or "unlocked: drag its title to move it."))
  elseif arg == "reset" then
    db.trackerPos = nil
    self:PlaceTracker()
    Print("Quest tracker moved back to its starting place.")
  else
    db.tracker = (db.tracker == false)
    if db.tracker then
      Print("Loremaster's quest tracker is on. Shift-click quests in the quest log to track them.")
    else
      Print("Loremaster's quest tracker is off; the game's tracker is back.")
    end
  end
  self:UpdateTracker()
  if not On() and QuestWatch_Update then QuestWatch_Update() else HideGameTracker() end
  if QuestLogFrame and QuestLogFrame:IsVisible() then QuestLog_Update() end
end
