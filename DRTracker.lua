-- ================================
-- DRTracker - Project-Epoch (3.3.5a)
-- ================================
local ADDON_NAME, DRTracker = ...
local _, playerClass = UnitClass("player")

local metaDB  = DRTracker.metaDB      -- icons per class/category (from DRData.lua)
local spellDB = DRTracker.spellDB     -- DR categories -> spellIDs (from DRData.lua)
local nameDB  = DRTracker.nameDB or {}-- optional name->category filled in DRData.lua

-- WoW API locals (3.3.5-safe)
local ipairs, pairs = ipairs, pairs
local tinsert, tsort = table.insert, table.sort
local min, max = math.min, math.max

local GetTime, UnitGUID, UnitName = GetTime, UnitGUID, UnitName
local UnitPlayerControlled, UnitIsUnit, UnitExists = UnitPlayerControlled, UnitIsUnit, UnitExists
local UnitIsPlayer, UnitAura, GetSpellInfo = UnitIsPlayer, UnitAura, GetSpellInfo
local InCombatLockdown = InCombatLockdown

-- -------------------------
-- Config & SavedVariables
-- -------------------------
local FRAME_SIZE = 25
local DR_TIME    = 18     -- seconds for DR to expire
local MIN_SCALE, MAX_SCALE = 0.5, 3.0
local BORDER_EXTRA = 18   -- outside glow thickness

DRT_Saved = DRT_Saved or {}
local function asnum(v, default) v = (type(v)=="number") and v or tonumber(v); if not v or v<=0 then return default end; return v end

DRT_Saved.scaleTarget = asnum(DRT_Saved.scaleTarget, 1.0)
DRT_Saved.scaleFocus  = asnum(DRT_Saved.scaleFocus,  1.0)
DRT_Saved.scaleAll    = asnum(DRT_Saved.scaleAll,    1.0)
DRT_Saved.allMax      = math.floor(asnum(DRT_Saved.allMax, 8))
DRT_Saved.allMode     = DRT_Saved.allMode or "relevant"  -- kept internally; UI disabled
-- default: icons always visible (green until DR is active)
if type(DRT_Saved.iconsAlwaysOn) ~= "boolean" then
  DRT_Saved.iconsAlwaysOn = true
end

if type(DRT_Saved.allEnabled) ~= "boolean" then DRT_Saved.allEnabled = false end -- HIDDEN BY DEFAULT

-- Debug toggle: when ON, we also track NPCs (for testing on mobs)
local DRT_DEBUG = false

-- -------------------------
-- State
-- -------------------------
-- DRDB[guid][category] = { lastStart, count, hadAura, lastExpire, byPlayer }
local DRDB, DRNames, DRKind = {}, {}, {}  -- DRKind[guid] = "player"|"pet"|"npc"

local SpellToCat   = {}   -- spellID -> category  (built from DRData.lua)
local Interested   = {}   -- categories your class cares about (from metaDB[playerClass])
local DRFrames     = {}   -- per-unit icon frames
local DRAnchors    = {}   -- anchors for target/focus

-- (ALL window structs are kept but UI is disabled)
local AllAnchor
local AllRows      = {}

local COLS, PAD = 3, 2

local function clamp(v, a, b) return min(max(v, a), b) end
local function defaultPointFor(unit)
  if unit == "target" then return "CENTER", UIParent, "CENTER", 260, -160
  elseif unit == "focus" then return "CENTER", UIParent, "CENTER", 260, -210
  elseif unit == "all"   then return "CENTER", UIParent, "CENTER",   0, -260 end
  return "CENTER", UIParent, "CENTER", 0, 0
end

-- Build LUTs
local function BuildSpellLUT()
  wipe(SpellToCat)
  for cat, list in pairs(spellDB or {}) do
    for i = 1, #list do SpellToCat[list[i]] = cat end
  end
end
local function BuildInterested()
  wipe(Interested)
  for cat in pairs(metaDB[playerClass] or {}) do Interested[cat] = true end
end

-- 3.3.5 GUID classifier (hex form)
local function classifyGUID_hex(guid)
  if not guid then return "npc" end
  -- Player: 0x00..., Creature: 0xF13..., Pet/Guardian/Vehicle: 0xF14/0xF15...
  if guid:sub(1,2) == "0x" then
    local b3b4 = guid:sub(3,4)  -- two hex chars after 0x
    if b3b4 == "00" then return "player" end
    if guid:find("^0xF14") or guid:find("^0xF15") then return "pet" end
    return "npc"
  end
  return "npc"
end

-- -------------------------
-- Icon + border helpers (SOLID, opaque ring above cooldown)
-- -------------------------
-- thickness in pixels (scales with the anchor)
local BORDER_THICK = 2

local function createIcon(parent, category, icon)
  local f = CreateFrame("Frame", nil, parent)
  f:SetSize(FRAME_SIZE, FRAME_SIZE)

  -- Icon
  f.t = f:CreateTexture(nil, "ARTWORK")
  f.t:SetAllPoints()
  f.t:SetTexture("Interface\\Icons\\" .. (icon or "INV_Misc_QuestionMark"))

  -- Cooldown sweep (keep this under our border)
  f.cd = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
  f.cd:SetAllPoints(f.t)
  f.cd:SetFrameLevel(f:GetFrameLevel() + 1)

  -- Opaque border on a top overlay frame
  f.borderF = CreateFrame("Frame", nil, f)
  f.borderF:SetAllPoints()
  f.borderF:SetFrameLevel(f.cd:GetFrameLevel() + 5)
  f.borderF:SetBackdrop({
    bgFile   = nil,                            -- no fill, only edge
    edgeFile = "Interface\\Buttons\\WHITE8X8", -- solid edge
    edgeSize = BORDER_THICK,
    insets   = { left = 0, right = 0, top = 0, bottom = 0 },
  })
  f.borderF:Hide()

  -- Back-compat alias
  f.border = f.borderF

  -- Helpers so the rest of the code can call Border* and we color the ring
  f.ShowBorder = function(self, r, g, b, a)
    self.borderF:Show()
    self.borderF:SetBackdropBorderColor(r or 1, g or 1, b or 1, a or 1)
  end
  f.HideBorder = function(self)
    self.borderF:Hide()
  end

  -- ===== DR COUNT NUMBER =====
  -- Put the number *on the top overlay frame* so it renders above the border.
  f.countText = f.borderF:CreateFontString(nil, "OVERLAY")
  f.countText:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 1, 1)
  f.countText:SetJustifyH("LEFT")
  f.countText:SetJustifyV("BOTTOM")

  -- BIGGER font + thick outline + strong black shadow so it pops off the border
  f.countText:SetFont(STANDARD_TEXT_FONT, math.floor(FRAME_SIZE * 0.95), "THICKOUTLINE")
  f.countText:Hide()

  f:Hide()
  return f
end

-- Color helpers (ONLY these—don’t re-declare later)
local function BorderGreen(f)  if f and f.ShowBorder then f:ShowBorder(0, 1, 0, 1) end end
local function BorderYellow(f) if f and f.ShowBorder then f:ShowBorder(1, 1, 0, 1) end end
local function BorderRed(f)    if f and f.ShowBorder then f:ShowBorder(1, 0, 0, 1) end end

local function BumpBorderByCount(frame, count)
  if count >= 2 then BorderRed(frame)
  elseif count >= 1 then BorderYellow(frame)
  else BorderGreen(frame) end
end

-- Paint color + small number by DR stage (0 = none)
local function ApplyStage(frame, stage)
  if not frame then return end

  -- clear when no DR
  if not stage or stage <= 0 then
    if frame.HideBorder then frame:HideBorder() end
    if frame.countText then frame.countText:SetText(""); frame.countText:Hide() end
    return
  end

  -- choose color + border by stage
  local r, g, b = 1, 1, 1
  if stage == 1 then
    BorderGreen(frame);  r, g, b = 0, 1, 0   -- green
  elseif stage == 2 then
    BorderYellow(frame); r, g, b = 1, 1, 0   -- yellow
  else
    BorderRed(frame);    r, g, b = 1, 0, 0   -- red
  end

  -- update the number text and color
  if frame.countText then
    frame.countText:SetText(tostring(stage))
    frame.countText:SetTextColor(r, g, b, 1)
    frame.countText:Show()
  end
end

-- -------------------------
-- Anchors (target/focus)
-- -------------------------
local function CreateAnchor(unit)
  if DRAnchors[unit] then return DRAnchors[unit] end
  local anchor = CreateFrame("Frame", "DRT_Anchor_"..unit, UIParent)
  anchor:SetSize(COLS*FRAME_SIZE + (COLS+1)*PAD, 2*FRAME_SIZE + 3*PAD)
  anchor:SetMovable(true)
  anchor:EnableMouse(false)
  anchor:RegisterForDrag("LeftButton")
  anchor:SetScript("OnDragStart", function(s) if s._unlocked then s:StartMoving() end end)
  anchor:SetScript("OnDragStop", function(s)
    s:StopMovingOrSizing()
    local p, _, rp, x, y = s:GetPoint()
    DRT_Saved[unit] = {point=p, relPoint=rp, x=x, y=y}
  end)

  anchor.bg = anchor:CreateTexture(nil, "BACKGROUND"); anchor.bg:SetAllPoints(); anchor.bg:SetTexture(0,0,0,0.35); anchor.bg:Hide()
  anchor.label = anchor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  anchor.label:SetPoint("TOPLEFT", 4, -4); anchor.label:SetText("DRTracker: "..unit.." (drag)"); anchor.label:Hide()

  anchor:ClearAllPoints()
  local pos = DRT_Saved[unit]; local p, rel, rp, x, y = defaultPointFor(unit)
  anchor:SetPoint(pos and (pos.point or p) or p, UIParent, pos and (pos.relPoint or rp) or rp, pos and (pos.x or x) or x, pos and (pos.y or y) or y)

  DRFrames[unit] = DRFrames[unit] or {}
  for category, icon in pairs(metaDB[playerClass] or {}) do
    if not DRFrames[unit][category] then
      local count = 0; for _ in pairs(DRFrames[unit]) do count = count + 1 end
      local col = count % COLS
      local row = math.floor(count / COLS)
      local f = createIcon(anchor, category, icon)
      f:SetPoint("TOPLEFT", PAD + col*(FRAME_SIZE+PAD), -PAD - row*(FRAME_SIZE+PAD))
      DRFrames[unit][category] = f
    end
  end

  anchor:SetScale(asnum(unit=="target" and DRT_Saved.scaleTarget or DRT_Saved.scaleFocus, 1.0))
  DRAnchors[unit] = anchor
  return anchor
end
local function EnsureAnchor(unit) return DRAnchors[unit] or CreateAnchor(unit) end
local function EnsureUnitCategoryFrame(unit, category)
  EnsureAnchor(unit)
  DRFrames[unit] = DRFrames[unit] or {}
  if not DRFrames[unit][category] then
    local count = 0; for _ in pairs(DRFrames[unit]) do count = count + 1 end
    local col = count % COLS
    local row = math.floor(count / COLS)
    local icon = metaDB[playerClass] and metaDB[playerClass][category] or nil
    local f = createIcon(DRAnchors[unit], category, icon)
    f:SetPoint("TOPLEFT", PAD + col*(FRAME_SIZE+PAD), -PAD - row*(FRAME_SIZE+PAD))
    DRFrames[unit][category] = f
  end
  return DRFrames[unit][category]
end

-- -------------------------
-- (ALL window code retained but UI disabled)
-- -------------------------
local function ClearAllRows() for _, r in ipairs(AllRows) do r:Hide() end end

local function CreateAllAnchor()
  if AllAnchor then return AllAnchor end
  local a = CreateFrame("Frame", "DRT_All", UIParent)
  a:SetMovable(true); a:EnableMouse(false)
  a:RegisterForDrag("LeftButton")
  a:SetScript("OnDragStart", function(s) if s._unlocked then s:StartMoving() end end)
  a:SetScript("OnDragStop", function(s)
    s:StopMovingOrSizing()
    local p, _, rp, x, y = s:GetPoint()
    DRT_Saved.allPos = {point=p, relPoint=rp, x=x, y=y}
  end)

  a:ClearAllPoints()
  local pos = DRT_Saved.allPos; local p, rel, rp, x, y = defaultPointFor("all")
  a:SetPoint(pos and (pos.point or p) or p, UIParent, pos and (pos.relPoint or rp) or rp, pos and (pos.x or x) or x, pos and (pos.y or y) or y)

  a.bg = a:CreateTexture(nil, "BACKGROUND"); a.bg:SetAllPoints(); a.bg:SetTexture(0,0,0,0.35); a.bg:Hide()
  a.label = a:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  a.label:SetPoint("TOPLEFT", 4, -4); a.label:SetText("DRTracker: ALL (drag)"); a.label:Hide()

  local maxRows = clamp(asnum(DRT_Saved.allMax, 8), 1, 40)
  local rowH = FRAME_SIZE + 16 + PAD
  a:SetSize(FRAME_SIZE + PAD*2 + 120, maxRows*rowH + PAD*2)

  AllRows = {}
  for i=1, maxRows do
    local row = CreateFrame("Frame", nil, a)
    row:SetSize(a:GetWidth()-PAD*2, rowH)
    row:SetPoint("TOPLEFT", PAD, -PAD - (i-1)*rowH)

    local iconF = CreateFrame("Frame", nil, row)
    iconF:SetSize(FRAME_SIZE, FRAME_SIZE)
    iconF:SetPoint("TOP", row, "TOP", 0, 0)

    iconF.t = iconF:CreateTexture(nil, "ARTWORK")
    iconF.t:SetAllPoints()
    iconF.t:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

    iconF.cd = CreateFrame("Cooldown", nil, iconF, "CooldownFrameTemplate")
    iconF.cd:SetAllPoints(iconF.t)

    iconF.border = iconF:CreateTexture(nil, "OVERLAY")
    iconF.border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    iconF.border:SetBlendMode("ADD")
    iconF.border:SetPoint("CENTER", iconF, "CENTER")
    iconF.border:SetWidth(FRAME_SIZE + BORDER_EXTRA)
    iconF.border:SetHeight(FRAME_SIZE + BORDER_EXTRA)
    iconF.border:Hide()

    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.name:SetPoint("TOP", iconF, "BOTTOM", 0, -2)
    row.name:SetText("")

    row.btn = CreateFrame("Button", nil, row, "SecureActionButtonTemplate")
    row.btn:SetAllPoints(iconF)
    row.btn:RegisterForClicks("AnyUp")

    row.icon = iconF
    row._name, row._guid, row._cat = "", nil, nil
    row:Hide()
    AllRows[i] = row
  end

  AllAnchor = a
  a:Hide() -- always hidden (UI disabled)
  return a
end

local function RebuildAllAnchor() AllAnchor = nil end

local function IncludeInAll(rec, cat, guid)
  local kind = DRKind[guid] or "npc"
  if not DRT_DEBUG and kind == "npc" then return false end
  if DRT_Saved.allMode == "all" then
    return true
  elseif DRT_Saved.allMode == "mine" then
    return rec.byPlayer
  else
    return rec.byPlayer or Interested[cat]
  end
end

local function BuildActiveListForAll()
  local now = GetTime()
  local list = {}
  for guid, cats in pairs(DRDB) do
    for cat, rec in pairs(cats) do
      local remain = (rec.lastStart or 0) + DR_TIME - now
      if remain > 0 and IncludeInAll(rec, cat, guid) then
        tinsert(list, { guid=guid, name=DRNames[guid] or "unknown", cat=cat, lastStart=rec.lastStart, remain=remain, count=rec.count or 0 })
      end
    end
  end
  tsort(list, function(a,b) return a.remain > b.remain end)
  return list
end

function UpdateAllWindow()
  -- UI disabled; keep list building off to save cycles
  return
end

-- -------------------------
-- Unlock/Lock (do NOT show ALL window)
-- -------------------------
local function SetUnlocked(state)
  for _, unit in ipairs({"target","focus"}) do
    local a = EnsureAnchor(unit)
    if a then
      a._unlocked = state
      a:EnableMouse(state)
      if a.bg    then a.bg:SetShown(state) end
      if a.label then a.label:SetShown(state) end
    end
  end
  if not state then
    UpdateOnChange("target"); UpdateOnChange("focus")
  end
end

-- -------------------------
-- UNIT_AURA scanner (apply/refresh bump; timer starts on falloff)
-- -------------------------
local function isMine(unitCaster)
  return UnitIsUnit(unitCaster, "player") or UnitIsUnit(unitCaster, "pet") or UnitIsUnit(unitCaster, "vehicle")
end

local function ScanUnit(unit)
  if not UnitExists(unit) then return end
  local guid = UnitGUID(unit); if not guid then return end

  -- classify (Wrath-safe)
  local kind = UnitIsPlayer(unit) and "player" or (UnitPlayerControlled(unit) and "pet" or "npc")
  if kind == "npc" then kind = classifyGUID_hex(guid) end
  DRKind[guid]  = kind
  DRNames[guid] = UnitName(unit) or DRNames[guid] or "unknown"

  -- gate NPCs when debug is OFF
  if not DRT_DEBUG and kind == "npc" then return end

  local seenCat = {}

  for i = 1, 40 do
    local name, _, _, _, _, duration, expirationTime, unitCaster, _, _, spellId = UnitAura(unit, i, "HARMFUL")
    if not name then break end
    local cat = SpellToCat[spellId] or (name and nameDB[name]) or nil
    if cat then
      seenCat[cat] = true
      DRDB[guid] = DRDB[guid] or {}
      -- record fields
      local rec = DRDB[guid][cat] or { hadAura=false, lastExpire=0, count=0, lastStart=0, byPlayer=false }
      local now = GetTime()

      local expire = expirationTime or 0
      local appliedOrRefreshed = (not rec.hadAura) or (expire > (rec.lastExpire or 0) + 0.05)

      if appliedOrRefreshed then
        -- if the DR window fully elapsed before this new application, reset stage
        if (rec.lastStart or 0) > 0 and (now > (rec.lastStart + DR_TIME)) and not rec.hadAura then
          rec.count = 0
        end
        -- bump stage on each apply/refresh while aura is ON (cap at 3)
        rec.count      = math.min((rec.count or 0) + 1, 3)  -- 0->1->2->3
        rec.hadAura    = true
        rec.lastExpire = expire
        if unitCaster then rec.byPlayer = rec.byPlayer or isMine(unitCaster) end
        -- NOTE: timer starts on falloff, not here
      else
        if unitCaster then rec.byPlayer = rec.byPlayer or isMine(unitCaster) end
        rec.hadAura = true
      end

      DRDB[guid][cat] = rec
    end
  end

  -- handle falloffs + cleanup
  if DRDB[guid] then
    local now = GetTime()
    for cat, rec in pairs(DRDB[guid]) do
      if rec.hadAura and not seenCat[cat] then
        -- aura fell off -> start the 18s DR timer NOW
        rec.hadAura    = false
        rec.lastExpire = 0
        rec.lastStart  = now
      end
      -- purge when window elapsed and aura not up anymore
      if (not rec.hadAura) and (rec.lastStart or 0) > 0 and now > (rec.lastStart + DR_TIME) then
        DRDB[guid][cat] = nil
      end
    end
    local any=false; for _ in pairs(DRDB[guid]) do any=true break end
    if not any then DRDB[guid] = nil; DRKind[guid] = nil; DRNames[guid] = nil end
  end
end

-- -------------------------
-- Retarget refresh (borders during aura; cooldown only after falloff)
-- -------------------------
function UpdateOnChange(unit)
  EnsureAnchor(unit)
  if not DRFrames[unit] then return end

  if not UnitExists(unit) then
    for _, f in pairs(DRFrames[unit]) do f:Hide() end
    return
  end

  local guid = UnitGUID(unit)
  if not guid then
    for _, f in pairs(DRFrames[unit]) do f:Hide() end
    return
  end

  -- classify + NPC gate (when debug off)
  local kind = (UnitIsPlayer(unit) and "player") or (UnitPlayerControlled(unit) and "pet") or classifyGUID_hex(guid)
  DRKind[guid]  = kind
  DRNames[guid] = UnitName(unit) or DRNames[guid] or "unknown"
  if not DRT_DEBUG and kind == "npc" then
    for _, f in pairs(DRFrames[unit]) do f:Hide() end
    return
  end

  local now    = GetTime()
  local cats   = DRDB[guid]
  local always = DRT_Saved.iconsAlwaysOn

  for category, frame in pairs(DRFrames[unit]) do
    local rec         = cats and cats[category]
    local hasAura     = rec and rec.hadAura
    local timerActive = rec and (not rec.hadAura) and (rec.lastStart or 0) > 0 and (now < (rec.lastStart + DR_TIME))
    local count       = rec and (rec.count or 0) or 0  -- stage: 0..3

    if always then
      frame:Show()
      if hasAura then
        frame.cd:Hide()
        ApplyStage(frame, count)
      elseif timerActive then
        frame.cd:SetCooldown(rec.lastStart, DR_TIME)
        frame.cd:Show()
        ApplyStage(frame, count)
      else
        frame.cd:Hide()
        ApplyStage(frame, 0)  -- no DR: no border & no number
      end
    else
      if hasAura or timerActive then
        frame:Show()
        if hasAura then
          frame.cd:Hide()
        else
          frame.cd:SetCooldown(rec.lastStart, DR_TIME)
          frame.cd:Show()
        end
        ApplyStage(frame, count)
      else
        frame.cd:Hide()
        ApplyStage(frame, 0)
        frame:Hide()
      end
    end
  end
end

-- periodic updater — re-scans target/focus and refreshes UI
local ticker = CreateFrame("Frame")
ticker.elapsed = 0
ticker:SetScript("OnUpdate", function(self, e)
  self.elapsed = self.elapsed + e
  if self.elapsed > 0.25 then
    self.elapsed = 0
    ScanUnit("target")
    ScanUnit("focus")
    UpdateOnChange("target")
    UpdateOnChange("focus")
  end
end)

-- Remove NPC entries when leaving debug mode
local function PurgeNPCsIfNeeded()
  if DRT_DEBUG then return end
  for guid in pairs(DRDB) do
    local kind = DRKind[guid] or classifyGUID_hex(guid)
    if kind ~= "player" and kind ~= "pet" then
      DRDB[guid] = nil
      DRNames[guid] = nil
      DRKind[guid]  = nil
    end
  end
end

-- -------------------------
-- Events
-- -------------------------
local EventHandler = CreateFrame("Frame")
EventHandler:RegisterEvent("UNIT_AURA")
EventHandler:RegisterEvent("PLAYER_TARGET_CHANGED")
EventHandler:RegisterEvent("PLAYER_FOCUS_CHANGED")
EventHandler:RegisterEvent("PLAYER_ENTERING_WORLD")
EventHandler:RegisterEvent("PLAYER_LOGIN")

EventHandler:SetScript("OnEvent", function(self, event, arg1)
  if event == "UNIT_AURA" then
    if arg1 == "target" or arg1 == "focus" then
      ScanUnit(arg1)
      UpdateOnChange(arg1)
    end

  elseif event == "PLAYER_TARGET_CHANGED" then
    ScanUnit("target"); UpdateOnChange("target")

  elseif event == "PLAYER_FOCUS_CHANGED" then
    ScanUnit("focus"); UpdateOnChange("focus")

  elseif event == "PLAYER_ENTERING_WORLD" then
    wipe(DRDB); wipe(DRNames); wipe(DRKind)

  elseif event == "PLAYER_LOGIN" then
    BuildSpellLUT()
    BuildInterested()
    EnsureAnchor("target"); EnsureAnchor("focus")
    -- Do NOT create AllAnchor on login (UI disabled by default)
    SetUnlocked(false)
    ScanUnit("target"); ScanUnit("focus")
    UpdateOnChange("target"); UpdateOnChange("focus")

    local ver = GetAddOnMetadata("DRTracker", "Version") or ""
    local vt  = (ver ~= "" and (" v"..ver) or "")
    DEFAULT_CHAT_FRAME:AddMessage("|cffffff00DRTracker|r"..vt.." loaded — by |cffa335eeRetroUnreal|r aka |cffa335eeBhop|r. Type |cffffff00/drt|r for commands.")
  end
end)

-- -------------------------
-- Slash commands
-- -------------------------
local function drtMsg(msg) DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffDRT|r "..tostring(msg)) end
local function listCatsForPlayer()
  local cls = select(2, UnitClass("player"))
  if not metaDB or not metaDB[cls] then return "?" end
  local t = {}; for cat in pairs(metaDB[cls]) do t[#t+1] = cat end; tsort(t); return table.concat(t, ", ")
end

-- full factory reset (positions, scales; ALL UI stays disabled)
local function FactoryReset()
  DRT_Saved.scaleTarget = 1.0
  DRT_Saved.scaleFocus  = 1.0
  DRT_Saved.scaleAll    = 1.0
  DRT_Saved.allMax      = 8
  DRT_Saved.allMode     = "relevant"
  DRT_Saved.allEnabled  = false
  DRT_Saved.target, DRT_Saved.focus, DRT_Saved.allPos = nil, nil, nil
  DRT_Saved.iconsAlwaysOn = true

  wipe(DRDB); wipe(DRNames); wipe(DRKind)

  for _, u in ipairs({"target","focus"}) do
    local aF = EnsureAnchor(u); aF:ClearAllPoints()
    local p, rel, rp, x, y = defaultPointFor(u); aF:SetPoint(p, rel, rp, x, y)
    aF:SetScale(1.0)
  end
  if AllAnchor then AllAnchor:Hide() end

  PurgeNPCsIfNeeded()
  ScanUnit("target"); ScanUnit("focus")
  UpdateOnChange("target"); UpdateOnChange("focus")
end

-- Pretty help (yellow command, white description — like FSR but yellow)
local function DRT_Add(msg) DEFAULT_CHAT_FRAME:AddMessage(msg) end
local function DRT_PrintHelp()
  local C, W, R = "|cffffff00", "|cffffffff", "|r"  -- YELLOW / WHITE / RESET
  DRT_Add(C.."DRT|r "..W.."commands:"..R)
  DRT_Add("  "..C.."/drt unlock|r "..W.."— unlock & show preview (drag to move)"..R)
  DRT_Add("  "..C.."/drt lock|r "..W.."— lock & hide (when idle)"..R)
  DRT_Add("  "..C.."/drt reset|r "..W.."— factory reset (positions/scales)"..R)
  DRT_Add("  "..C.."/drt scale target|focus <"..MIN_SCALE.."–"..MAX_SCALE..">|r "..W.."— set DR frame scale (default 1.0)"..R)
  DRT_Add("  "..C.."/drt icons [on|off]|r "..W.."— show category icons always ("..
          (DRT_Saved.iconsAlwaysOn and "ON" or "OFF")..")"..R)
  DRT_Add("  "..C.."/drt debug|r "..W.."— toggle NPC tracking for testing (ON shows NPCs)"..R)
  DRT_Add("  "..C.."       "..R)
  DRT_Add(W.."  "..C.."Your DR categories: "..R..(listCatsForPlayer() or "?")..R)
end


SLASH_DRT1 = "/drt"
SlashCmdList["DRT"] = function(raw)
  local ok, err = pcall(function()
    local msg = (raw or ""):match("^%s*(.-)%s*$")
    local cmd, a, b = msg:match("^(%S*)%s*(%S*)%s*(%S*)")
    cmd = (cmd or ""):lower()

    if cmd == "" or cmd == "help" then
      DRT_PrintHelp()

    elseif cmd == "unlock" or cmd == "move" then
      SetUnlocked(true)
      drtMsg("Anchors UNLOCKED — drag, then /drt lock.")

    elseif cmd == "lock" then
      SetUnlocked(false)
      drtMsg("Anchors locked.")

    elseif cmd == "reset" then
      FactoryReset()
      drtMsg("Factory reset complete.")

    elseif cmd == "scale" then
      local which, val = (a or ""):lower(), tonumber(b)
      if not (which=="target" or which=="focus") or not val then
        local C, R = "|cffffff00","|r"
        drtMsg("Usage: "..C.."/drt scale target|focus <"..MIN_SCALE.."–"..MAX_SCALE..">"..R)
        return
      end
      val = clamp(val, MIN_SCALE, MAX_SCALE)
      if which=="target" then
        DRT_Saved.scaleTarget = val; EnsureAnchor("target"):SetScale(val)
      else
        DRT_Saved.scaleFocus  = val; EnsureAnchor("focus"):SetScale(val)
      end
      drtMsg("Scale "..which.." set to "..string.format("%.2f", val))

    elseif cmd == "icons" then
      local arg = (a or ""):lower()
      if arg == "on" then
        DRT_Saved.iconsAlwaysOn = true
      elseif arg == "off" then
        DRT_Saved.iconsAlwaysOn = false
      else
        DRT_Saved.iconsAlwaysOn = not DRT_Saved.iconsAlwaysOn
      end
      UpdateOnChange("target"); UpdateOnChange("focus")
      drtMsg("Icons-always-on is now "..(DRT_Saved.iconsAlwaysOn and "ON" or "OFF")..".")

    elseif cmd == "max" or cmd == "all" then
      drtMsg("ALL window is disabled in this build.")

    elseif cmd == "debug" then
      DRT_DEBUG = not DRT_DEBUG
      if not DRT_DEBUG then PurgeNPCsIfNeeded() end
      ScanUnit("target"); ScanUnit("focus")
      UpdateOnChange("target"); UpdateOnChange("focus")
      drtMsg("Debug is "..(DRT_DEBUG and "ON (NPCs included)" or "OFF (players & pets only)"))

    else
      local C, R = "|cffffff00","|r"
      drtMsg("Unknown command. Use "..C.."/drt help"..R)
    end
  end)
  if not ok then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff5555DRT error:|r "..tostring(err))
  end
end
