-- Rule.lua - the auto-target rule: macro text, secure snippets, and the
-- "is this button's content harmful?" decision. No frames are made here, so
-- the offline test harness (tests/run.lua) can load this file alone.
--
-- The rule, pressed on a harmful ability:
--   1. you have a living hostile target   -> keep it
--   2. else an enemy under the mouse / crosshair (alive) -> target it
--   3. else (1.1, client with nameplate unit tokens) the living enemy whose
--      nameplate is nearest the aim point (screen centre; for the pointer-aimed
--      button: the pointer), inside the aim circle -> target it
--   4. else the game's own "nearest enemy" pick (/targetenemy), unless the
--      option "nearest if nobody is in my aim" is off
--   then the real ability is pressed as before.
-- Helpful spells, self buffs, mounts, macros, potions: pressed exactly as before.
-- 1.1.1: a spell that both heals and harms (Holy Shock, Penance) keeps a living
-- friendly target: the pick runs only when the target is not one
-- (/click [nohelp][dead] ...). Pure harmful spells: unchanged.
-- 1.1.1: each real bar button is clicked exactly once per key press, on the
-- edge (key down or key up) it is registered for (see KEY_SNIPPET).
-- Lua 5.1, WoW 3.3.5 API only.

AutoTarget = AutoTarget or {}
local AT = AutoTarget

AT.VERSION = "1.1.1"
AT.PICK_BUTTON = "AutoTargetPick"          -- the secure button that runs the rule (aim = screen centre)
AT.PICK_PAD_BUTTON = "AutoTargetPickPad"   -- same rule, aim = the pointer
AT.MAX_SLOT = 120                          -- action slots above this (vehicle / possess pages) are never touched
AT.MAX_PLATES = 60                         -- plate frames remembered (the client reuses its plate frames)
AT.AIM_SIZE_DEFAULT = 0.18                 -- aim circle radius, fraction of the screen height
AT.AIM_SIZE_MIN, AT.AIM_SIZE_MAX = 0.05, 0.40
AT.AIM_Y_WEIGHT = 0.5                      -- vertical offsets count half (plates sit above heads and stack upwards)

-- Macro text for a choice made by the secure chooser (CHOOSE_SNIPPET).
-- tok: "keep" | "mouseover" | "nameplateN" | "nearest" | "none"
-- startAttack: add /startattack; fallback: add the /targetenemy safety line
-- after a chosen unit. "" = nothing to run. The secure PICK_SNIPPET builds the
-- very same text (tests/run.lua checks both agree).
function AT.MacroFor(tok, startAttack, fallback)
  local t = ""
  if tok == "mouseover" or (type(tok) == "string" and tok:match("^nameplate%d+$")) then
    t = "/target [target=" .. tok .. ",harm,nodead]"
    if fallback then t = t .. "\n/targetenemy [noharm][dead]" end
  elseif tok == "nearest" then
    t = "/targetenemy [noharm][dead]"
  end
  if startAttack and tok ~= "none" and tok ~= nil then
    if t ~= "" then t = t .. "\n" end
    t = t .. "/startattack [harm,nodead]"
  end
  return t
end

-- Line put in front of an ability (slots of another add-on may use the pointer-aimed pick button).
-- dual = the spell also helps (1.1.1): pick only without a living friendly target.
function AT.PrefixLine(button, dual)
  return "/click " .. (dual and "[nohelp][dead] " or "") .. (button or AT.PICK_BUTTON) .. "\n"
end

---------------------------------------------------------------------------
-- Secure snippets (run by the game's restricted code: work in combat).
-- Only functions of the 3.3.5 restricted environment are used:
-- UnitExists, UnitIsDead, PlayerCanAttack, IsModifiedClick,
-- GetActionBarPage, GetBonusBarOffset, newtable, tinsert, strmatch, format,
-- tonumber, type, frame handle methods (GetAttribute, GetFrameRef, GetRect,
-- GetEffectiveScale, IsProtected, IsVisible, GetChildList, GetMousePosition)
-- and control:RunAttribute.
-- RestrictedExecution.lua refuses any snippet that contains the word
-- "f-u-n-c-t-i-o-n" or a curly brace, even in a comment: keep them out.
---------------------------------------------------------------------------

-- The chooser: header attribute "at-choose", run with control:RunAttribute
-- (self = the header). Arguments: aimAt ("centre" | "pointer"), verbose.
-- Returns tok, why, list (list only when verbose).
-- Plates are read from (a) the pool of plate frame references p1..pN made out
-- of combat as plates appear, and (b) the protected children of WorldFrame
-- when the WorldFrame handle is usable (always out of combat; in combat only
-- if WorldFrame counts as protected), which also finds a plate frame first
-- created during combat. A plate counts when it is protected, shown, its
-- "unit" attribute is a nameplateN token of a living attackable unit, and its
-- reference point (centre x, bottom y) is on the screen.
AT.CHOOSE_SNIPPET = [=[
  local aimAt, verbose = ...
  if UnitExists("target") and PlayerCanAttack("target") and not UnitIsDead("target") then
    return "keep", "you have a living enemy target", ""
  end
  if UnitExists("mouseover") and PlayerCanAttack("mouseover") and not UnitIsDead("mouseover") then
    return "mouseover", "a living enemy is under the pointer or crosshair", ""
  end
  local miss = "none"
  if self:GetAttribute("fb") == 1 then miss = "nearest" end
  if self:GetAttribute("aim") ~= 1 then
    return miss, "aim is off or not available on this client", ""
  end
  local scr = self:GetFrameRef("screen")
  local sl, sb, sw, sh
  if scr then sl, sb, sw, sh = scr:GetRect() end
  if not sw or sw <= 0 or not sh or sh <= 0 then
    return miss, "screen size unknown", ""
  end
  local se = scr:GetEffectiveScale()
  local L, B, W, H = sl * se, sb * se, sw * se, sh * se
  local fx, fy = 0.5, 0.5
  if aimAt == "pointer" then
    local mx, my = scr:GetMousePosition()
    if mx and my then fx, fy = mx, my end
  end
  local ax, ay = L + W * fx, B + H * fy
  local rad = tonumber(self:GetAttribute("aimsize")) or 0.18
  local yw = tonumber(self:GetAttribute("aimyw")) or 0.5
  local cands = newtable()
  local np = tonumber(self:GetAttribute("np")) or 0
  for i = 1, np do
    local p = self:GetFrameRef("p" .. i)
    if p then tinsert(cands, p) end
  end
  local world = self:GetFrameRef("world")
  local walked = 0
  if world and world:IsProtected() then
    world:GetChildList(cands)
    walked = 1
  end
  local done = newtable()
  local best, bestd = nil, nil
  local seen, nDead, nFriend, nOff, nFar = 0, 0, 0, 0, 0
  local list = ""
  for i = 1, #cands do
    local p = cands[i]
    if p and not done[p] and p:IsProtected() and p:IsVisible() then
      done[p] = true
      local u = p:GetAttribute("unit")
      if type(u) == "string" and strmatch(u, "^nameplate%d+$") and UnitExists(u) then
        seen = seen + 1
        if UnitIsDead(u) then
          nDead = nDead + 1
          if verbose then list = list .. " " .. u .. ":dead" end
        elseif not PlayerCanAttack(u) then
          nFriend = nFriend + 1
          if verbose then list = list .. " " .. u .. ":friendly" end
        else
          local l, b, w, h = p:GetRect()
          if l and b and w then
            local e = p:GetEffectiveScale()
            local x, y = (l + w / 2) * e, b * e
            if x < L or x > L + W or y < B or y > B + H then
              nOff = nOff + 1
              if verbose then list = list .. " " .. u .. ":offscreen" end
            else
              local dx, dy = x - ax, (y - ay) * yw
              local d = ((dx * dx + dy * dy) ^ 0.5) / H
              if verbose then list = list .. " " .. u .. format(":%.2f", d) end
              if d > rad then
                nFar = nFar + 1
              elseif not bestd or d < bestd then
                best, bestd = u, d
              end
            end
          end
        end
      end
    end
  end
  local counts = format("%d plates (%d dead, %d friendly, %d off screen, %d outside the circle; world walk %d)",
                        seen, nDead, nFriend, nOff, nFar, walked)
  if best then
    return best, format("nearest the aim: %.2f of the screen height (circle %.2f); ", bestd, rad) .. counts, list
  end
  if miss == "nearest" then
    return "nearest", "nobody in the aim circle, nearest enemy: " .. counts, list
  end
  return "none", "nobody in the aim circle, nearest is off: " .. counts, list
]=]

-- Pre-click of AutoTargetPick / AutoTargetPickPad (owner = the AutoTarget
-- header). The wrapped pre-click runs before the button's own OnClick
-- (SecureHandlers.lua Wrapped_Click), so the macrotext written here is the one
-- the click then runs.
AT.PICK_SNIPPET = [=[
  if owner:GetAttribute("enabled") ~= 1 then return false end
  if IsModifiedClick("SELFCAST") or IsModifiedClick("FOCUSCAST") then return false end
  local tok = control:RunAttribute("at-choose", self:GetAttribute("aim-at") or "centre")
  local text = ""
  if tok == "mouseover" or strmatch(tok or "", "^nameplate%d+$") then
    text = "/target [target=" .. tok .. ",harm,nodead]"
    if owner:GetAttribute("fb") == 1 then text = text .. "\n/targetenemy [noharm][dead]" end
  elseif tok == "nearest" then
    text = "/targetenemy [noharm][dead]"
  end
  if owner:GetAttribute("sa") == 1 and tok and tok ~= "none" then
    if text ~= "" then text = text .. "\n" end
    text = text .. "/startattack [harm,nodead]"
  end
  if text == "" then return false end
  self:SetAttribute("macrotext", text)
]=]

-- Run by SecureHandlerExecute out of combat for "/autotarget aim who".
AT.WHO_SNIPPET = [=[
  local tok, why, list = control:RunAttribute("at-choose", "centre", true)
  self:SetAttribute("who-tok", tok)
  self:SetAttribute("who-why", why)
  self:SetAttribute("who-list", list)
]=]

-- Pre-click of each AutoTargetKey<n> button (one per bound key; owner = header).
-- Finds the real action button and its action slot now (paging, stance, bonus
-- bar can change in combat), then builds the macro: pick (harmful only) +
-- /click the real button.
-- 1.1.1 (review B1): the real button gets exactly ONE click per key press,
-- whatever Button:Click() does with the button's RegisterForClicks setting:
-- the key button acts on one edge only and drops the other (return false).
-- Which edge: "kd" (or "kd-bonus" / "kd-veh" for the Blizzard main bar's
-- twins) = 1 when the real button is registered for key / mouse DOWN (ElvUI
-- "cast on key down", the client's hold-to-cast), 0 for UP (Blizzard bars).
-- Written out of combat by AutoTarget.lua (AT.ClickEdge). On the down edge the
-- click says "down" ("LeftButton 1"), on the up edge it is a plain click, so a
-- client that does honour the registration fires it too.
-- Manual override (header "clickmode"): auto (default) | down | up |
-- split (1.1.0: both edges, may fire twice) | single (1.1.0: plain click on key down).
AT.KEY_SNIPPET = [=[
  local real = self:GetFrameRef("btn")
  local kind = self:GetAttribute("at-kind")
  local id = self:GetAttribute("at-id") or 0
  local kdn = "kd"
  local slot
  if kind == "blizzmain" then
    local veh = self:GetFrameRef("veh")
    local bon = self:GetFrameRef("bonus")
    local page = GetActionBarPage()
    if veh and veh:IsVisible() then
      real = veh
      kdn = "kd-veh"
    elseif bon and bon:IsVisible() then
      real = bon
      kdn = "kd-bonus"
      local off = GetBonusBarOffset()
      if page == 1 and off > 0 then slot = id + (5 + off) * 12 else slot = id + (page - 1) * 12 end
    else
      slot = id + (page - 1) * 12
    end
  elseif kind == "fixed" then
    slot = id + ((self:GetAttribute("at-page") or 1) - 1) * 12
  elseif real and real:GetAttribute("type") == "action" then
    slot = real:GetAttribute("action")
  end
  if not real then return false end
  local name = real:GetName()
  local mode = owner:GetAttribute("clickmode")
  local isDown = down and true or false
  if mode == "split" then
    if not isDown then
      self:SetAttribute("macrotext", "/click " .. name)
      return
    end
  else
    local onDown = self:GetAttribute(kdn) == 1
    if mode == "down" or mode == "single" then onDown = true elseif mode == "up" then onDown = false end
    if isDown ~= onDown then return false end
  end
  local pre = ""
  if owner:GetAttribute("enabled") == 1 and slot and slot >= 1 and slot <= 120 then
    local h = owner:GetAttribute("h" .. slot)
    if h == 1 then
      pre = "/click AutoTargetPick\n"
    elseif h == 2 then
      pre = "/click [nohelp][dead] AutoTargetPick\n"
    end
  end
  if isDown and mode ~= "single" then
    self:SetAttribute("macrotext", pre .. "/click " .. name .. " LeftButton 1")
  else
    self:SetAttribute("macrotext", pre .. "/click " .. name)
  end
]=]

-- Which edge a real bar button acts on (insecure, out of combat): 1 = key /
-- mouse down, 0 = up. Read from what the button was registered with:
--  * this client (CoA FrameXML SecureTemplates.lua, SecureActionButton_OnLoad)
--    keeps the RegisterForClicks arguments in btn.DesiredClickButtons, and a
--    hold-to-cast button (btn.IsHoldCast) is registered for both edges;
--  * LibActionButton (ElvUI 7.27): btn.clickState / btn.config.clickOnDown
--    ("AnyDown" when ElvUI's "cast on key down" is on, LibActionButton-1.0.lua 636);
--  * else 0: stock Blizzard action buttons are registered "AnyUp"
--    (ActionButton.lua ActionButton_OnLoad).
function AT.EdgeOfList(list)
  if type(list) ~= "table" then return nil end
  for _, v in ipairs(list) do
    if type(v) == "string" and v:lower():find("down$") then return 1 end
  end
  return 0
end
function AT.ClickEdge(btn)
  if type(btn) ~= "table" then return 0 end
  if rawget(btn, "IsHoldCast") then return 1 end
  local e = AT.EdgeOfList(rawget(btn, "DesiredClickButtons"))
  if e then return e end
  local st = rawget(btn, "clickState")
  if type(st) == "string" then return AT.EdgeOfList({ st }) end
  local cfg = rawget(btn, "config")
  if type(cfg) == "table" and cfg.clickOnDown ~= nil then return cfg.clickOnDown and 1 or 0 end
  return 0
end

---------------------------------------------------------------------------
-- Harmful or not (insecure, out of combat; results go into header attributes)
---------------------------------------------------------------------------
local function safe(f, ...)
  if type(f) ~= "function" then return nil end
  local ok, a = pcall(f, ...)
  if ok then return a end
  return nil
end

-- A spell by name: harmful (damage / debuff on an enemy) or an attack spell.
function AT.IsHarmfulSpellName(name)
  if type(name) ~= "string" or name == "" then return false end
  if safe(IsHarmfulSpell, name) then return true end
  if safe(IsAttackSpell, name) then return true end   -- "Attack" (auto attack)
  return false
end

-- 1.1.1 (review S8): harmful AND helpful (Holy Shock, Penance): the pick must
-- not move a living friendly target away.
function AT.IsDualSpellName(name)
  if not AT.IsHarmfulSpellName(name) then return false end
  return safe(IsHelpfulSpell, name) and true or false
end

function AT.IsHarmfulItemRef(item)
  if item == nil then return false end
  return safe(IsHarmfulItem, item) and true or false
end

-- The spell name behind a GetActionInfo "spell" result. 3.3.5 returns
-- (type, id, subType, spellID); id is read as a spellbook slot only if the
-- 4th value is missing. The name is what IsHarmfulSpell(name) takes.
local function ActionSpellName(id, sub, gid)
  local name = gid and safe(GetSpellInfo, gid)
  if name then return name end
  if type(id) == "number" then
    name = safe(GetSpellName, id, (sub == "pet") and "pet" or "spell")
    if name then return name end
    name = safe(GetSpellInfo, id)
  end
  return name
end

-- Decision for one action slot. Macros are left alone on purpose: a macro
-- already says who it targets, and its spell can change with its conditions.
-- 1.1.1: AT.SlotKind(slot) = 0 (pressed as before), 1 (harmful: pick first),
-- 2 (harmful and helpful: pick only without a living friendly target).
function AT.SlotKind(slot)
  if not AT.SlotIsHarmful(slot) then return 0 end
  if safe(IsAttackAction, slot) then return 1 end
  local t, id, sub, gid = GetActionInfo(slot)
  if t == "spell" and sub ~= "pet" and AT.IsDualSpellName(ActionSpellName(id, sub, gid)) then return 2 end
  return 1
end

function AT.SlotIsHarmful(slot)
  if not safe(HasAction, slot) then return false end
  if safe(IsAttackAction, slot) then return true end
  local t, id, sub, gid = GetActionInfo(slot)
  if t == "spell" then
    if sub == "pet" then
      -- pet ability placed on a player bar: by book slot
      if type(id) == "number" and safe(IsHarmfulSpell, id, "pet") then return true end
    end
    return AT.IsHarmfulSpellName(ActionSpellName(id, sub, gid))
  elseif t == "item" then
    return AT.IsHarmfulItemRef(id)
  end
  return false   -- macro, companion (mounts, pets), equipmentset, empty
end

-- Slot data of another add-on ({kind=, name=, id=}) -> macro text with the rule,
-- or nil when the slot must stay as it is. Such slots click the pointer-aimed
-- pick button: its aim point is the pointer, so the mouse-over step and the
-- plate step look at the same spot.
function AT.SlotMacro(d)
  if type(d) ~= "table" then return nil end
  if d.kind == "spell" and AT.IsHarmfulSpellName(d.name) then
    return AT.PrefixLine(AT.PICK_PAD_BUTTON, AT.IsDualSpellName(d.name)) .. "/cast " .. d.name
  elseif d.kind == "item" and d.id and AT.IsHarmfulItemRef(d.id) then
    return AT.PrefixLine(AT.PICK_PAD_BUTTON) .. "/use item:" .. d.id
  end
  return nil
end

---------------------------------------------------------------------------
-- Which keys to take over, and which real button each one presses.
---------------------------------------------------------------------------
-- Blizzard bars without a bar add-on: command -> bar, fixed action page.
AT.BLIZZ_MULTI = {
  MULTIACTIONBAR1BUTTON = { "MultiBarBottomLeftButton", 6 },
  MULTIACTIONBAR2BUTTON = { "MultiBarBottomRightButton", 5 },
  MULTIACTIONBAR3BUTTON = { "MultiBarRightButton", 3 },
  MULTIACTIONBAR4BUTTON = { "MultiBarLeftButton", 4 },
}

local function keysOf(cmd)
  local out = {}
  if type(GetBindingKey) ~= "function" then return out end
  local all = { GetBindingKey(cmd) }
  for i = 1, #all do
    if type(all[i]) == "string" and all[i] ~= "" then out[#out + 1] = all[i] end
  end
  return out
end

-- Keys another add-on owns (listed in AutoTarget.reservedKeys): never taken over.
function AT.ReservedKeys()
  local r = {}
  if type(AT.reservedKeys) == "table" then
    for _, k in pairs(AT.reservedKeys) do r[k] = true end
  end
  return r
end

-- Returns a list of { key=, kind=, id=, page=, btn=, bonus=, veh=, cmd= }.
-- kind: "attr" (bar add-on button, slot read from its "action" attribute),
-- "blizzmain" (Blizzard main bar, with bonus and vehicle twins), "fixed"
-- (Blizzard side / bottom bars, fixed page).
function AT.BuildTargets()
  local list, seen = {}, {}
  local reserved = AT.ReservedKeys()
  local function add(key, t)
    if seen[key] or reserved[key] then return end
    seen[key] = true
    local e = { key = key }
    for k, v in pairs(t) do e[k] = v end
    list[#list + 1] = e
  end
  local mapped = {}   -- binding command prefix -> handled by a bar add-on
  local known = {}    -- button names we know, for CLICK bindings
  -- ElvUI (and anything shaped like it): ElvUI_Bar<i>.bindButtons
  if rawget(_G, "ElvUI_Bar1Button1") then
    for i = 1, 10 do
      local bar = rawget(_G, "ElvUI_Bar" .. i)
      local cmd = type(bar) == "table" and rawget(bar, "bindButtons")
      if type(cmd) == "string" then
        mapped[cmd] = true
        for n = 1, 12 do
          local name = "ElvUI_Bar" .. i .. "Button" .. n
          if rawget(_G, name) then
            known[#known + 1] = { name = name, t = { kind = "attr", btn = name, cmd = cmd .. n } }
            for _, key in ipairs(keysOf(cmd .. n)) do add(key, { kind = "attr", btn = name, cmd = cmd .. n }) end
          end
        end
      end
    end
  end
  if not mapped.ACTIONBUTTON then
    for n = 1, 12 do
      local t = { kind = "blizzmain", id = n, btn = "ActionButton" .. n, bonus = "BonusActionButton" .. n,
                  veh = (n <= 6) and ("VehicleMenuBarActionButton" .. n) or nil, cmd = "ACTIONBUTTON" .. n }
      known[#known + 1] = { name = t.btn, t = t }
      for _, key in ipairs(keysOf("ACTIONBUTTON" .. n)) do add(key, t) end
    end
  end
  for cmd, b in pairs(AT.BLIZZ_MULTI) do
    if not mapped[cmd] then
      for n = 1, 12 do
        local t = { kind = "fixed", id = n, page = b[2], btn = b[1] .. n, cmd = cmd .. n }
        known[#known + 1] = { name = t.btn, t = t }
        for _, key in ipairs(keysOf(cmd .. n)) do add(key, t) end
      end
    end
  end
  -- Keys bound straight to a button ("CLICK ElvUI_Bar1Button1:LeftButton").
  for _, k in ipairs(known) do
    for _, key in ipairs(keysOf("CLICK " .. k.name .. ":LeftButton")) do add(key, k.t) end
  end
  table.sort(list, function(a, b) return a.key < b.key end)
  return list
end
