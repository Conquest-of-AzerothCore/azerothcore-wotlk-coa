-- Options.lua - Esc > Interface > AddOns > AutoTarget, and /autotarget.

local AT = AutoTarget

local panel = CreateFrame("Frame", "AutoTargetOptionsPanel", UIParent)
panel.name = "AutoTarget"
panel:Hide()

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("AutoTarget")

local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
sub:SetWidth(560)
sub:SetJustifyH("LEFT")
sub:SetText("Press an attack and it picks the enemy for you: your living enemy target if you have one, "
  .. "else the enemy under the mouse (or the controller crosshair), else the enemy in the middle of the screen, "
  .. "else the nearest enemy. Healing spells, buffs, mounts, potions and macros work exactly as before.")

local function Check(name, label, tip, y, get, set, x)
  local c = CreateFrame("CheckButton", name, panel, "UICheckButtonTemplate")
  c:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", x or 0, y)
  local text = _G[name .. "Text"]
  if text then text:SetText(label) end
  c.tooltipText = tip
  c:SetScript("OnShow", function(self) self:SetChecked(get()) end)
  c:SetScript("OnClick", function(self) set(self:GetChecked() and true or false) end)
  return c
end

Check("AutoTargetOptEnabled", "Target automatically when I press an ability",
  "Key presses on your action bars pick an enemy first when the ability is harmful. Off: keys work exactly as without this add-on.",
  -16, function() return AT.DB().enabled end, function(v) AT.Set("enabled", v) end)
Check("AutoTargetOptAttack", "Also start auto attack",
  "When an attack picks or keeps an enemy, your auto attack starts too.",
  -46, function() return AT.DB().startAttack end, function(v) AT.Set("startAttack", v) end)

-- 1.1: aim at the enemy in the middle of the screen (nameplates)
local AIM_TIP = "With no enemy target and nobody under the mouse or crosshair, an attack picks the living enemy "
  .. "whose nameplate is nearest the middle of the screen (controller: the crosshair dot), inside the aim circle. "
  .. "Needs enemy nameplates shown. Nameplates show through walls and far away: you may get an enemy you cannot "
  .. "hit yet; the game then says out of range or not in line of sight."
local aimBox = Check("AutoTargetOptAim", "Aim at the enemy in the middle of the screen", AIM_TIP,
  -86, function() return AT.DB().aim end, function(v) AT.Set("aim", v) end)

local slider = CreateFrame("Slider", "AutoTargetOptAimSize", panel, "OptionsSliderTemplate")
slider:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 30, -136)
slider:SetWidth(220)
slider:SetMinMaxValues(AT.AIM_SIZE_MIN, AT.AIM_SIZE_MAX)
slider:SetValueStep(0.01)
slider.tooltipText = "Radius of the aim circle around the middle of the screen, as a part of the screen height. "
  .. "Bigger = easier to catch an enemy, smaller = more exact."
local function SliderLabel(v)
  local t = _G["AutoTargetOptAimSizeText"]
  if t then t:SetText(("Aim circle size: %d%% of the screen height"):format(floor(v * 100 + 0.5))) end
end
if _G["AutoTargetOptAimSizeLow"] then _G["AutoTargetOptAimSizeLow"]:SetText("small") end
if _G["AutoTargetOptAimSizeHigh"] then _G["AutoTargetOptAimSizeHigh"]:SetText("large") end
slider:SetScript("OnShow", function(self) self:SetValue(AT.DB().aimSize); SliderLabel(AT.DB().aimSize) end)
slider:SetScript("OnValueChanged", function(self, v)
  v = floor(v * 100 + 0.5) / 100
  SliderLabel(v)
  if v ~= AT.DB().aimSize then AT.Set("aimSize", v) end
end)

local nearestBox = Check("AutoTargetOptAimNearest", "Nearest enemy if nobody is in my aim",
  "On: with nobody inside the aim circle, the game's nearest enemy is taken (as without aim). "
  .. "Off: nothing is targeted and the attack says you have no target.",
  -166, function() return AT.DB().aimNearest end, function(v) AT.Set("aimNearest", v) end)

local platesBtn = CreateFrame("Button", "AutoTargetOptPlates", panel, "UIPanelButtonTemplate")
platesBtn:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 4, -200)
platesBtn:SetWidth(200)
platesBtn:SetHeight(22)
platesBtn:SetText("Show enemy nameplates")
platesBtn:SetScript("OnClick", function(self) if AT.TurnOnPlates() then self:Hide() end end)

local aimNote = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
aimNote:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -230)
aimNote:SetWidth(560)
aimNote:SetJustifyH("LEFT")

panel:SetScript("OnShow", function()
  if not AT.PlatesSupported() then
    aimNote:SetText("This game client has no nameplate unit tokens, so aiming at the middle of the screen is not "
      .. "available: AutoTarget uses the enemy under the mouse, then the nearest enemy.")
    aimBox:Disable(); nearestBox:Disable()
    if slider.Disable then slider:Disable() end
    platesBtn:Hide()
  elseif not AT.PlatesShown() then
    aimNote:SetText("Enemy nameplates are off: aiming finds nobody until they are shown.")
    platesBtn:Show()
  else
    aimNote:SetText("")
    platesBtn:Hide()
  end
end)

local note = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
note:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -256)
note:SetWidth(560)
note:SetJustifyH("LEFT")
note:SetText("Changes made during combat apply when combat ends. Clicking a bar button with the mouse is not changed. "
  .. "/autotarget check lists your keys and what each one does.")

if InterfaceOptions_AddCategory then InterfaceOptions_AddCategory(panel) end

local function Open()
  if InterfaceOptionsFrame_OpenToCategory then
    InterfaceOptionsFrame_OpenToCategory(panel)
    InterfaceOptionsFrame_OpenToCategory(panel)   -- 3.3.5 needs two calls the first time
  end
end

SLASH_AUTOTARGET1 = "/autotarget"
SlashCmdList.AUTOTARGET = function(msg)
  local a, b, rest = (msg or ""):match("^%s*(%S*)%s*(%S*)%s*(.*)$")
  a, b = (a or ""):lower(), (b or ""):lower()
  if a == "on" or a == "off" then
    AT.Set("enabled", a == "on")
    AT.Print("Target automatically: " .. a)
  elseif a == "attack" and (b == "on" or b == "off") then
    AT.Set("startAttack", b == "on")
    AT.Print("Also start auto attack: " .. b)
  elseif a == "clicks" and AT.CLICK_MODES[b] then
    -- auto (default): one click per key press, on the bar button's own edge.
    -- Manual override: down | up (always that edge), split | single (1.1.0 ways).
    AT.Set("clickMode", b)
    AT.Print("Click mode: " .. b)
  elseif a == "clicks" then
    AT.Print("Click mode now: " .. tostring(AT.DB().clickMode) .. ". /autotarget clicks auto | down | up | split | single")
  elseif a == "aim" then
    local c = (rest or ""):match("^(%S*)") or ""
    local cl = c:lower()
    if b == "on" or b == "off" then
      AT.Set("aim", b == "on")
      AT.Print("Aim at the enemy in the middle of the screen: " .. b
        .. (AT.PlatesSupported() and "" or " (not available on this client: no nameplate unit tokens)"))
      if b == "on" then AT.CheckPlatesShown(true) end
    elseif b == "size" then
      local v = tonumber(c)
      if v and v > 1 then v = v / 100 end        -- "18" = 18 %
      if v and v >= AT.AIM_SIZE_MIN and v <= AT.AIM_SIZE_MAX then
        v = floor(v * 100 + 0.5) / 100
        AT.Set("aimSize", v)
        AT.Print(("Aim circle size: %.2f of the screen height"):format(v))
      else
        AT.Print(("Aim size: a number from %.2f to %.2f (or %d to %d percent)."):format(AT.AIM_SIZE_MIN,
          AT.AIM_SIZE_MAX, AT.AIM_SIZE_MIN * 100, AT.AIM_SIZE_MAX * 100))
      end
    elseif b == "nearest" and (cl == "on" or cl == "off") then
      AT.Set("aimNearest", cl == "on")
      AT.Print("Nearest enemy if nobody is in my aim: " .. cl)
    elseif b == "who" then
      AT.AimWho(c ~= "" and c or nil)
    elseif b == "plates" then
      AT.TurnOnPlates()
    else
      local db = AT.DB()
      AT.Print(("aim=%s size=%.2f nearest=%s. Commands: /autotarget aim on | off | size N | who [label] | nearest on|off | plates")
               :format(tostring(db.aim), db.aimSize, tostring(db.aimNearest)))
    end
  elseif a == "check" then
    AT.Check()
  elseif a == "who" then
    AT.Who(b ~= "" and b or nil)
  elseif a == "options" or a == "config" then
    Open()
  else
    local db = AT.DB()
    AT.Print(("on=%s, attack=%s, aim=%s. Commands: /autotarget on | off | attack on|off | aim ... | check | who | options")
             :format(tostring(db.enabled), tostring(db.startAttack), tostring(db.aim)))
  end
end
