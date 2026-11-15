-- AutoTarget.lua - secure buttons, override bindings, events, public API.
--
-- How it works (keyboard + mouse):
--   For every key bound to an action button (Blizzard bars, ElvUI bars, or a
--   key bound straight to one of those buttons) an override binding points
--   the key at our own hidden secure button AutoTargetKey<n>. Its secure
--   pre-click finds the real button and its current action slot, and runs
--     /click AutoTargetPick          (only if that slot holds a harmful action)
--     /click <real button>
--   so the real bar keeps cooldowns, range colours, paging and its own
--   key-down / key-up setting. Nothing of ElvUI or Blizzard is written to:
--   their buttons are only clicked.
-- 1.1.1: exactly one click per key press, on the edge the real button is
--   registered for (attributes kd / kd-bonus / kd-veh, refreshed out of combat).
-- 1.1 (aim pick): out of combat, every enemy nameplate frame the client shows
--   is remembered as a frame reference on our header (a pool, filled from
--   NAME_PLATE_UNIT_ADDED and a light sweep of the nameplateN tokens), plus a
--   reference to WorldFrame. The secure chooser (Rule.lua CHOOSE_SNIPPET)
--   reads those plates' positions and "unit" attributes at press time, in
--   combat too. Plates and their tables are only read, never written.
-- All binding / attribute work happens out of combat; changes asked for in
-- combat are applied when combat ends.

local AT = AutoTarget
AT.DEFAULT_ON = false        -- off until the player turns it on
AT.callbacks = {}

local header, pick, pickPad, screen
local keyButtons = {}        -- n -> button (reused, never destroyed)
local pending = {}           -- what to redo after combat: { bindings=true, slots={...}, all=true }
local applied = { enabled = nil, startAttack = nil, clickMode = nil, aim = nil }

local function Print(msg) DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffAutoTarget|r: " .. tostring(msg)) end
AT.CLICK_MODES = { auto = true, down = true, up = true, split = true, single = true }
AT.Print = Print

---------------------------------------------------------------------------
-- Saved settings
---------------------------------------------------------------------------
local function DB()
  AutoTargetDB = AutoTargetDB or {}
  local db = AutoTargetDB
  if db.enabled == nil then db.enabled = AT.DEFAULT_ON and true or false end
  if db.startAttack == nil then db.startAttack = false end
  -- 1.1.1: "auto" (one click, on the real button's own edge) replaces the
  -- 1.1.0 default "split" (which could fire a button twice); a saved
  -- "single" / "down" / "up" stays.
  if db.clickVer ~= 2 then
    db.clickVer = 2
    if db.clickMode == nil or db.clickMode == "split" then db.clickMode = "auto" end
  end
  if not AT.CLICK_MODES[db.clickMode] then db.clickMode = "auto" end
  if db.aim == nil then db.aim = true end                    -- 1.1: aim pick on by default
  if db.aimNearest == nil then db.aimNearest = true end      -- nearest if nobody is in my aim
  local sz = tonumber(db.aimSize)
  if not sz or sz < AT.AIM_SIZE_MIN or sz > AT.AIM_SIZE_MAX then db.aimSize = AT.AIM_SIZE_DEFAULT end
  return db
end
AT.DB = DB

-- What is in force right now (a change asked in combat waits).
function AT.IsEnabled() return applied.enabled == true end
function AT.StartsAttack() return applied.startAttack == true end
function AT.AimActive() return applied.aim == true end

-- The client has nameplate unit tokens (nameplateN) and a way to get a
-- token's plate frame. Stock 3.3.5a has neither: then 1.1 = 1.0.
-- UnitExists("nameplate1") cannot tell (no plates in view = false), so the
-- client function is the test.
function AT.PlatesSupported()
  return type(rawget(_G, "GetNamePlateForUnit")) == "function"
end

local function PlateForUnit(unit)
  local c = rawget(_G, "C_NamePlate")
  local f
  if type(c) == "table" and type(c.GetNamePlateForUnit) == "function" then
    local ok, r = pcall(c.GetNamePlateForUnit, unit); if ok then f = r end
  end
  if not f then
    local ok, r = pcall(GetNamePlateForUnit, unit); if ok then f = r end
  end
  if type(f) == "table" and type(f.GetObjectType) == "function" then return f end
  return nil
end

function AT.RegisterCallback(fn)
  if type(fn) == "function" then AT.callbacks[#AT.callbacks + 1] = fn end
end
local function FireCallbacks()
  for _, fn in ipairs(AT.callbacks) do pcall(fn) end
end

---------------------------------------------------------------------------
-- Secure frames (created once, out of combat)
---------------------------------------------------------------------------
local function Setup()
  if header then return true end
  if InCombatLockdown() then return false end
  header = CreateFrame("Frame", "AutoTargetHeader", UIParent, "SecureHandlerBaseTemplate")
  header:SetAttribute("enabled", 0)
  header:SetAttribute("at-choose", AT.CHOOSE_SNIPPET)
  -- Our own protected full-screen frame: its rect is the screen the aim
  -- point and the "off screen" test use (WorldFrame can be stretched by the
  -- client's smooth nameplate stacking, so it is not the screen).
  screen = CreateFrame("Frame", "AutoTargetScreen", UIParent, "SecureFrameTemplate")
  screen:SetAllPoints(UIParent)
  SecureHandlerSetFrameRef(header, "screen", screen)
  if WorldFrame then SecureHandlerSetFrameRef(header, "world", WorldFrame) end
  local function MakePick(name, aimAt)
    local b = CreateFrame("Button", name, UIParent, "SecureActionButtonTemplate")
    b:RegisterForClicks("AnyUp", "AnyDown")   -- /click sends a plain (up) click
    b:SetAttribute("type", "macro")
    b:SetAttribute("macrotext", "")
    b:SetAttribute("aim-at", aimAt)
    SecureHandlerWrapScript(b, "OnClick", header, AT.PICK_SNIPPET)
    return b
  end
  pick = MakePick(AT.PICK_BUTTON, "centre")
  pickPad = MakePick(AT.PICK_PAD_BUTTON, "pointer")
  AT.header = header
  return true
end

local function KeyButton(n)
  local b = keyButtons[n]
  if b then return b end
  b = CreateFrame("Button", "AutoTargetKey" .. n, UIParent, "SecureActionButtonTemplate")
  b:RegisterForClicks("AnyDown", "AnyUp")       -- key down and key up are both passed on
  b:SetAttribute("type", "macro")
  b:SetAttribute("macrotext", "")
  SecureHandlerWrapScript(b, "OnClick", header, AT.KEY_SNIPPET)
  keyButtons[n] = b
  return b
end

---------------------------------------------------------------------------
-- Harmful flags per action slot (header attributes h1..h120)
---------------------------------------------------------------------------
local function RefreshSlot(slot)
  if slot < 1 or slot > AT.MAX_SLOT then return end
  header:SetAttribute("h" .. slot, AT.SlotKind(slot))   -- 0 / 1 / 2 (1.1.1: 2 = also helpful)
end
local function RefreshAllSlots()
  for s = 1, AT.MAX_SLOT do RefreshSlot(s) end
end

---------------------------------------------------------------------------
-- Click edge of each real button (1.1.1, review B1); out of combat only.
-- Hold-to-cast and ElvUI's hover switch can change a button's registration,
-- so this runs again on slot changes, right before combat and once a second.
---------------------------------------------------------------------------
local function SetIfChanged(b, k, v)
  if b:GetAttribute(k) ~= v then b:SetAttribute(k, v) end
end
local function RefreshEdge(t)
  local b = t.keyButton
  if not b then return end
  SetIfChanged(b, "kd", AT.ClickEdge(_G[t.btn]))
  if t.bonus and _G[t.bonus] then SetIfChanged(b, "kd-bonus", AT.ClickEdge(_G[t.bonus])) end
  if t.veh and _G[t.veh] then SetIfChanged(b, "kd-veh", AT.ClickEdge(_G[t.veh])) end
end
function AT.RefreshEdges()
  if not header or InCombatLockdown() then return end
  for _, t in ipairs(AT.targets) do RefreshEdge(t) end
end

---------------------------------------------------------------------------
-- Bindings
---------------------------------------------------------------------------
AT.targets = {}
local function ApplyBindings()
  ClearOverrideBindings(header)
  wipe(AT.targets)
  if not applied.enabled then return end
  local list = AT.BuildTargets()
  for n, t in ipairs(list) do
    local real = _G[t.btn]
    if real then
      local b = KeyButton(n)
      b:SetAttribute("at-kind", t.kind)
      b:SetAttribute("at-id", t.id)
      b:SetAttribute("at-page", t.page)
      SecureHandlerSetFrameRef(b, "btn", real)
      if t.bonus and _G[t.bonus] then SecureHandlerSetFrameRef(b, "bonus", _G[t.bonus]) end
      if t.veh and _G[t.veh] then SecureHandlerSetFrameRef(b, "veh", _G[t.veh]) end
      SetOverrideBindingClick(header, true, t.key, b:GetName())
      t.button = b:GetName()
      t.keyButton = b
      RefreshEdge(t)
      AT.targets[#AT.targets + 1] = t
    end
  end
end

---------------------------------------------------------------------------
-- Apply settings (out of combat; else queued)
---------------------------------------------------------------------------
function AT.Apply()
  if not Setup() or InCombatLockdown() then pending.all = true; return false end
  local db = DB()
  applied.enabled = db.enabled == true
  applied.startAttack = db.startAttack == true
  applied.clickMode = db.clickMode
  applied.aim = db.aim == true and AT.PlatesSupported()
  header:SetAttribute("sa", applied.startAttack and 1 or 0)
  -- /targetenemy after (or instead of) a choice: always with aim off (= 1.0),
  -- else by the option "nearest if nobody is in my aim".
  header:SetAttribute("fb", ((not applied.aim) or db.aimNearest == true) and 1 or 0)
  header:SetAttribute("aim", applied.aim and 1 or 0)
  header:SetAttribute("aimsize", db.aimSize)
  header:SetAttribute("aimyw", AT.AIM_Y_WEIGHT)
  header:SetAttribute("clickmode", applied.clickMode)
  RefreshAllSlots()
  header:SetAttribute("enabled", applied.enabled and 1 or 0)
  ApplyBindings()
  AT.FlushPlates()
  pending = {}
  FireCallbacks()   -- other add-ons that registered a callback re-apply their slots
  AT.CheckPlatesShown(false)
  return true
end

-- Option changes from the panel / slash command.
function AT.Set(field, value)
  local db = DB()
  db[field] = value
  if AT.Apply() then return true end
  Print("In combat: the change applies when combat ends.")
  return false
end

---------------------------------------------------------------------------
-- Plate pool (1.1): frame references to the client's plate frames, made out
-- of combat. The client reuses its plate frames (a plate frame stays once it
-- exists; its "unit" attribute changes), so the pool is complete after the
-- first few pulls. A plate frame first made during combat is queued and
-- added when combat ends; meanwhile the chooser can still find it through
-- WorldFrame's protected children if WorldFrame is usable in combat.
---------------------------------------------------------------------------
local plates = {}           -- n -> frame
local plateIndex = {}       -- frame -> n
local queuedPlates = {}     -- frames seen in combat
AT.plates = plates

function AT.AddPlate(f)
  if not f or plateIndex[f] or not header then return false end
  if InCombatLockdown() then queuedPlates[f] = true; return false end
  if #plates >= AT.MAX_PLATES then return false end
  local n = #plates + 1
  plates[n] = f
  plateIndex[f] = n
  SecureHandlerSetFrameRef(header, "p" .. n, f)
  header:SetAttribute("np", n)
  return true
end

function AT.SweepPlates()
  if not header or InCombatLockdown() or not AT.PlatesSupported() then return end
  for i = 1, 40 do
    local u = "nameplate" .. i
    if UnitExists(u) then AT.AddPlate(PlateForUnit(u)) end
  end
end

function AT.FlushPlates()
  if InCombatLockdown() then return end
  for f in pairs(queuedPlates) do AT.AddPlate(f) end
  wipe(queuedPlates)
  AT.SweepPlates()
end

function AT.OnPlateAdded(unit)
  if not AT.PlatesSupported() or type(unit) ~= "string" then return end
  local f = PlateForUnit(unit)
  if not f then return end
  if InCombatLockdown() then queuedPlates[f] = true else AT.AddPlate(f) end
end

-- Enemy nameplates off: the aim pick sees nothing. Say so once per session,
-- never change the setting without the player asking.
local platesHinted = false
local function ElvUIEnemyCombatToggle()
  local E = type(rawget(_G, "ElvUI")) == "table" and rawget(_G, "ElvUI")[1]
  local db = type(E) == "table" and type(E.db) == "table" and E.db.nameplates
  return type(db) == "table" and db.showEnemyCombat or nil
end
function AT.PlatesShown()
  return GetCVar and tostring(GetCVar("nameplateShowEnemies")) == "1"
end
function AT.CheckPlatesShown(manual)
  if not AT.PlatesSupported() then return end
  local db = DB()
  if not (db.enabled and db.aim) then return end
  if AT.PlatesShown() then return end
  if platesHinted and not manual then return end
  platesHinted = true
  local msg = "enemy nameplates are off, so \"aim at the enemy in the middle of the screen\" finds nobody "
    .. "(the nearest enemy is used instead). Turn them on: /autotarget aim plates, or the button in "
    .. "Esc > Interface > AddOns > AutoTarget."
  if ElvUIEnemyCombatToggle() == "TOGGLE_ON" then
    msg = msg .. " (Your ElvUI profile shows enemy nameplates in combat only: the aim works in combat.)"
  end
  Print(msg)
end
function AT.TurnOnPlates()
  if InCombatLockdown() then Print("In combat: try again when combat ends."); return false end
  SetCVar("nameplateShowEnemies", "1")
  Print("Enemy nameplates: on.")
  return true
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local ev = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "UPDATE_BINDINGS",
                     "ACTIONBAR_SLOT_CHANGED", "SPELLS_CHANGED", "LEARNED_SPELL_IN_TAB",
                     "ACTIVE_TALENT_GROUP_CHANGED", "ADDON_ACTION_BLOCKED", "ADDON_ACTION_FORBIDDEN" }) do
  ev:RegisterEvent(e)
end
-- Client events of the nameplate tokens (absent on stock 3.3.5a: guarded).
pcall(ev.RegisterEvent, ev, "NAME_PLATE_UNIT_ADDED")
ev:SetScript("OnEvent", function(_, event, arg1, arg2)
  if event == "NAME_PLATE_UNIT_ADDED" then
    AT.OnPlateAdded(arg1)
    return
  end
  if event == "PLAYER_REGEN_DISABLED" then   -- 1.1.1: last chance before lockdown
    AT.RefreshEdges()
    return
  end
  if event == "PLAYER_LOGIN" then
    local db = DB()
    AT.Apply()
    if not db.hinted then
      db.hinted = true
      if not db.enabled then
        Print("installed, switched off. Turn it on with /autotarget on, or Esc > Interface > AddOns > AutoTarget.")
      end
    end
  elseif event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN" then
    if arg1 == "AutoTarget" then Print(event .. ": " .. tostring(arg2)) end
  elseif not header then
    AT.Apply()
  elseif InCombatLockdown() then
    if event == "ACTIONBAR_SLOT_CHANGED" and type(arg1) == "number" then
      pending.slots = pending.slots or {}
      pending.slots[arg1] = true
      if arg1 == 0 then pending.all = true end
    elseif event == "UPDATE_BINDINGS" then
      pending.bindings = true
    else
      pending.all = true
    end
  elseif event == "PLAYER_REGEN_ENABLED" then
    if pending.all then AT.Apply()
    else
      for s in pairs(pending.slots or {}) do RefreshSlot(s) end
      if pending.bindings then ApplyBindings() end
      pending = {}
      AT.FlushPlates()
    end
  elseif event == "ACTIONBAR_SLOT_CHANGED" then
    if type(arg1) == "number" and arg1 > 0 then RefreshSlot(arg1) else RefreshAllSlots() end
    AT.RefreshEdges()
  elseif event == "UPDATE_BINDINGS" then
    ApplyBindings()
  else  -- entering world, spells / spec changed: all slots again
    RefreshAllSlots()
    if event == "PLAYER_ENTERING_WORLD" then ApplyBindings(); AT.FlushPlates() end
  end
end)

-- Light sweep of the nameplateN tokens, out of combat, once a second, while
-- the aim pick is in use (catches plates shown before this add-on loaded).
local sweepAcc = 0
ev:SetScript("OnUpdate", function(_, elapsed)
  sweepAcc = sweepAcc + elapsed
  if sweepAcc < 1 then return end
  sweepAcc = 0
  if applied.enabled and not InCombatLockdown() then
    AT.RefreshEdges()                                   -- 1.1.1
    if applied.aim then AT.FlushPlates() end
  end
end)

---------------------------------------------------------------------------
-- Diagnostics for testers
---------------------------------------------------------------------------
local function ActionLabel(slot)
  if not slot or not HasAction(slot) then return "empty" end
  local t, id, sub, gid = GetActionInfo(slot)
  local name = (gid and GetSpellInfo(gid)) or (t == "item" and GetItemInfo(id)) or tostring(id)
  return tostring(t) .. ":" .. tostring(name) .. (sub and ("/" .. tostring(sub)) or "")
end

-- The slot the real button would use now (insecure mirror of KEY_SNIPPET).
local function CurrentSlot(t)
  local real = _G[t.btn]
  if t.kind == "attr" then
    return real and real:GetAttribute("type") == "action" and real:GetAttribute("action") or nil, t.btn
  elseif t.kind == "fixed" then
    return t.id + (t.page - 1) * 12, t.btn
  end
  local page = GetActionBarPage()
  if t.veh and _G[t.veh] and _G[t.veh]:IsVisible() then return nil, t.veh end
  if t.bonus and _G[t.bonus] and _G[t.bonus]:IsVisible() then
    local off = GetBonusBarOffset()
    if page == 1 and off > 0 then return t.id + (5 + off) * 12, t.bonus end
  end
  return t.id + (page - 1) * 12, t.btn
end

function AT.Check()
  Print(("on=%s attack=%s clicks=%s keys=%d"):format(tostring(applied.enabled), tostring(applied.startAttack),
        tostring(applied.clickMode), #AT.targets))
  local db = DB()
  Print(("aim=%s (asked %s, client tokens %s) size=%.2f nearest=%s plates known=%d enemy plates shown=%s"):format(
        tostring(applied.aim), tostring(db.aim), tostring(AT.PlatesSupported()), db.aimSize,
        tostring(db.aimNearest), #plates, tostring(AT.PlatesShown())))
  for _, t in ipairs(AT.targets) do
    local slot, name = CurrentSlot(t)
    local h = slot and slot <= AT.MAX_SLOT and header:GetAttribute("h" .. slot)
    local b = t.keyButton
    local kdn = (name == t.veh and "kd-veh") or (name == t.bonus and "kd-bonus") or "kd"
    local edge = b and b:GetAttribute(kdn) == 1 and "down" or "up"
    Print(("%s -> %s slot %s %s: %s, clicked on key %s"):format(t.key, name, tostring(slot), ActionLabel(slot),
          (h == 1 and "|cffff5555targets first|r") or (h == 2 and "|cffff5555targets first unless a friend is targeted|r")
          or "pressed as before", edge))
  end
end

-- /autotarget who [label]: write down who is targeted now (measurement aid).
function AT.Who(label)
  local db = DB()
  db.log = db.log or {}
  local line = ("%s %s target=%s guid=%s mouseover=%s"):format(date("%H:%M:%S"), label or "-",
               tostring(UnitName("target")), tostring(UnitGUID("target")), tostring(UnitName("mouseover")))
  table.insert(db.log, line)
  while #db.log > 300 do table.remove(db.log, 1) end
  Print(line)
end

-- /autotarget aim who [label]: run the real secure chooser now (out of
-- combat) and print who it would pick and why. Logged like /autotarget who.
function AT.AimWho(label)
  if not header then Print("not ready yet."); return end
  if InCombatLockdown() then
    Print("aim who works out of combat only (the pick itself works in combat).")
    return
  end
  AT.FlushPlates()
  SecureHandlerExecute(header, AT.WHO_SNIPPET)
  local tok = header:GetAttribute("who-tok")
  local why = header:GetAttribute("who-why")
  local list = header:GetAttribute("who-list")
  local unit = tok
  if tok == "keep" then unit = "target" elseif tok == "nearest" or tok == "none" then unit = nil end
  local name = unit and UnitName(unit) or "-"
  local line = ("%s %s aim pick=%s (%s): %s |%s"):format(date("%H:%M:%S"), label or "-", tostring(tok),
               tostring(name), tostring(why), tostring(list or ""))
  local db = DB()
  db.log = db.log or {}
  table.insert(db.log, line)
  while #db.log > 300 do table.remove(db.log, 1) end
  Print(line)
  return tok, why, list
end
