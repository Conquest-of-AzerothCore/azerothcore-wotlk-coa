-- Open-world pet battle UI (retail-style top VS bar + bottom action bar). The server (pb_battle.lua) runs everything; wild pets start battles, /pbtest is the GM debug start.
-- /pbtest        start a test battle next to you        /pbtest quit   forfeit        /pbtest fx <spellId>   cast a visual on your pet        /pbtest trace   toggle the battle transcript in world.out (GM)
local GOLD = { 0.95, 0.78, 0.25 }
local WHITE = "Interface\\Buttons\\WHITE8X8"
local BACKDROP = { bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
                   tile = true, tileSize = 32, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } }

local S = { P = {}, E = {}, act = { P = 1, E = 1 }, abil = {}, cd = { 0, 0, 0 }, canAct = false, force = false, tips = {}, info = {}, eabil = {}, own = {} }
local CollectedFx
local top, bottom, banner, abBtns, benchBtns, quitBtn, trapBtn, turnTxt
local Close   -- defined below
local QCOL = { { 1, 1, 1 }, { 0.12, 1, 0 }, { 0, 0.44, 0.87 }, { 0.64, 0.21, 0.93 } }   -- common / uncommon / rare / epic: white, green, blue, purple
local QHEX = { "|cffffffff", "|cff1eff00", "|cff0070dd", "|cffa335ee" }
local QNAME = { "Common", "Uncommon", "Rare", "Epic" }

local side = {}   -- side.P / side.E = top-bar widgets

-- 3.3.5 has no SetShown / SetEnabled
local function ShowIf(f, c) if c then f:Show() else f:Hide() end end
local function EnableIf(f, c) if c then f:Enable() else f:Disable() end end

local function HPColor(r)   -- full = green, half = yellow, low = red (smooth)
    if r > 0.5 then return 2 * (1 - r) * 0.85 + 0.1, 0.8, 0.12 end
    return 0.9, 1.6 * r + 0.1, 0.1
end
local BARTEX = "Interface\\TargetingFrame\\UI-StatusBar"
local function Bar(parent, w, h)
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetSize(w, h); bar:SetStatusBarTexture(BARTEX); bar:SetMinMaxValues(0, 1); bar:SetValue(1)
    bar:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
    bar:SetBackdropBorderColor(0.75, 0.62, 0.25, 1)
    bar.bg = bar:CreateTexture(nil, "BACKGROUND"); bar.bg:SetPoint("TOPLEFT", 2, -2); bar.bg:SetPoint("BOTTOMRIGHT", -2, 2); bar.bg:SetTexture(0.05, 0.05, 0.05, 0.9)
    bar.ghost = bar:CreateTexture(nil, "BACKGROUND", nil, 1); bar.ghost:SetTexture(WHITE); bar.ghost:SetVertexColor(0.95, 0.9, 0.7, 0.85)   -- the part you just lost, draining slowly
    bar.ghost:SetPoint("TOPLEFT", 2, -2); bar.ghost:SetPoint("BOTTOMLEFT", 2, 2); bar.ghost:SetWidth(1)
    bar.gloss = bar:CreateTexture(nil, "OVERLAY"); bar.gloss:SetTexture(WHITE)
    bar.gloss:SetPoint("TOPLEFT", 3, -3); bar.gloss:SetPoint("TOPRIGHT", -3, -3); bar.gloss:SetHeight(h * 0.4)
    bar.gloss:SetGradientAlpha("VERTICAL", 1, 1, 1, 0, 1, 1, 1, 0.28)
    bar.txt = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); bar.txt:SetPoint("CENTER")
    bar.w = w - 4; bar.shown = 1; bar.target = 1; bar.gh = 1
    bar:SetScript("OnUpdate", function(self, e)   -- smooth drain/fill; the pale ghost follows more slowly
        if math.abs(self.shown - self.target) > 0.002 then
            self.shown = self.shown + (self.target - self.shown) * math.min(1, e * 7); self:SetValue(self.shown)
            self:SetStatusBarColor(HPColor(self.shown))
        end
        if self.gh > self.shown + 0.002 then self.gh = self.gh - math.max((self.gh - self.shown) * e * 2.2, e * 0.04) elseif self.gh < self.shown then self.gh = self.shown end
        self.ghost:SetWidth(math.max(1, self.w * self.gh))
    end)
    return bar
end

local function SetHP(bar, hp, max, instant)
    bar.target = max > 0 and hp / max or 0
    if instant then bar.shown = bar.target; bar.gh = bar.target; bar:SetValue(bar.shown) end
    bar:SetStatusBarColor(HPColor(bar.target))
    bar.txt:SetText(hp .. " / " .. max .. "   " .. (max > 0 and math.floor(hp / max * 100 + 0.5) or 0) .. "%")
end

-- 3D model of a pet in a framed box. entry = creature entry of the species (the client draws it once the server has primed/sent the record)
local function ModelBox(parent, size)
    local f = CreateFrame("Frame", nil, parent); f:SetSize(size, size)
    f:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    f.m = CreateFrame("DressUpModel", nil, f); f.m:SetPoint("TOPLEFT", 4, -4); f.m:SetPoint("BOTTOMRIGHT", -4, 4)
    f.fallback = f:CreateTexture(nil, "ARTWORK"); f.fallback:SetPoint("TOPLEFT", 6, -6); f.fallback:SetPoint("BOTTOMRIGHT", -6, 6)
    function f:Set(entry, icon, q, dead, scale)
        if self.entry ~= entry then
            self.entry = entry
            self.fallback:SetTexture("Interface\\Icons\\" .. (icon or "INV_Misc_QuestionMark"))
            if false and entry and entry > 0 then   -- 3D previews are off in the battle frames: the pet TYPE icon is shown instead (heads of tall models were cut off)
                local ok = pcall(function()
                    self.m:SetCreature(entry); self.m:SetRotation(0.61)
                    -- the world scale shrinks big models more than small ones; scaling the preview by the same number evens them out
                    self.m:SetModelScale(math.max(0.5, math.min(1.6, (scale or 0.4) * 2.6)))
                end)
                ShowIf(self.m, ok); ShowIf(self.fallback, not ok)
            else self.m:Hide(); self.fallback:Show() end
        end
        local c = QCOL[q or 1]; self:SetBackdropBorderColor(c[1], c[2], c[3], 1)
        self.fallback:SetDesaturated(dead and true or false); self.m:SetAlpha(dead and 0.35 or 1)
    end
    return f
end

local function Float(parent, text, red)   -- damage / heal number that rises and fades
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    fs:SetText(text); local c = text:sub(1, 1)
    if c == "-" then fs:SetTextColor(1, 0.15, 0.15) elseif c == "+" then fs:SetTextColor(0.3, 1, 0.3) else fs:SetTextColor(1, 0.85, 0.2) end
    local t = 0
    local f = CreateFrame("Frame", nil, parent)
    f:SetScript("OnUpdate", function(self, e)
        t = t + e; fs:ClearAllPoints(); fs:SetPoint("CENTER", parent, "BOTTOM", 0, -10 - t * 38); fs:SetAlpha(1 - t / 1.2)
        if t > 1.2 then fs:Hide(); self:SetScript("OnUpdate", nil) end
    end)
end

local function StatusIcon(parent)
    local b = CreateFrame("Frame", nil, parent); b:SetSize(30, 30); b:EnableMouse(true)
    b.edge = b:CreateTexture(nil, "BACKGROUND"); b.edge:SetPoint("TOPLEFT", -2, 2); b.edge:SetPoint("BOTTOMRIGHT", 2, -2); b.edge:SetTexture(WHITE)
    b.t = b:CreateTexture(nil, "ARTWORK"); b.t:SetAllPoints(); b.t:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    b.turns = b:CreateFontString(nil, "OVERLAY", "NumberFontNormal"); b.turns:SetPoint("BOTTOMRIGHT", 3, -3)
    b.stk = b:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall"); b.stk:SetPoint("TOPLEFT", -2, 3); b.stk:SetTextColor(1, 1, 0.4)
    b:SetScript("OnEnter", function(self)
        if not self.st then return end
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM"); GameTooltip:SetText(self.st.label .. (self.st.stacks > 1 and ("  x" .. self.st.stacks) or ""), 1, 0.82, 0)
        GameTooltip:AddLine(self.st.bad and "Harmful effect" or "Beneficial effect", self.st.bad and 1 or 0.4, self.st.bad and 0.4 or 1, 0.4)
        local tip = S.tips[self.st.label]; if tip and tip ~= "" then GameTooltip:AddLine(tip, 1, 1, 1, 1) end
        if self.st.turns > 0 then GameTooltip:AddLine(self.st.turns .. (self.st.turns == 1 and " turn remaining" or " turns remaining"), 1, 1, 1) end
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return b
end

local function Panel(name, isRight)
    local p = CreateFrame("Frame", nil, top)
    p:SetSize(344, 100); p:SetBackdrop(BACKDROP)
    p:SetPoint(isRight and "TOPLEFT" or "TOPRIGHT", top, "TOP", isRight and 36 or -36, 0)
    p.model = ModelBox(p, 82); p.model:SetPoint(isRight and "RIGHT" or "LEFT", isRight and -8 or 8, 0)
    p.lvlf = CreateFrame("Frame", nil, p); p.lvlf:SetAllPoints(p.model); p.lvlf:SetFrameLevel(p.model.m:GetFrameLevel() + 3)   -- above the 3D model, or the level hides behind it
    p.lvl = p.lvlf:CreateFontString(nil, "OVERLAY", "GameFontNormal"); p.lvl:SetPoint("BOTTOM", 0, 5)
    p.name = p:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    p.hp = Bar(p, 226, 24)
    p.own = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); p.own:SetPoint("TOPLEFT", p, "BOTTOMLEFT", 6, -8); p.own:SetJustifyH("LEFT")   -- BELOW the panel (the screen top would cut it off), left of the team pips   -- enemy: collected / not collected / upgrade
    if isRight then
        p.name:SetPoint("TOPRIGHT", p.model, "TOPLEFT", -10, -6); p.hp:SetPoint("TOPRIGHT", p.model, "TOPLEFT", -8, -30)
    else
        p.name:SetPoint("TOPLEFT", p.model, "TOPRIGHT", 10, -6); p.hp:SetPoint("TOPLEFT", p.model, "TOPRIGHT", 8, -30)
    end
    p:EnableMouse(true)   -- hover the pet panel: family matchup and (enemy) abilities with their cooldowns
    p:SetScript("OnEnter", function(self)
        local s = isRight and "E" or "P"; local pet = S[s][S.act[s]]; local f = S.info[s]
        if not pet then return end
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM"); GameTooltip:SetText(pet.name .. "  (level " .. pet.lv .. ")", 1, 0.82, 0)
        if pet.power then
            GameTooltip:AddLine("Power " .. pet.power .. "   Speed " .. pet.speed, 0.8, 0.8, 0.8)
        end
        if f then
            GameTooltip:AddLine("Family: " .. f.name, 1, 1, 1)
            if f.strong ~= "" then GameTooltip:AddLine("Hits harder against: " .. f.strong, 0.4, 1, 0.4) end
            if f.weak ~= "" then GameTooltip:AddLine("Hits weaker against: " .. f.weak, 1, 0.5, 0.4) end
            if f.hurtBy ~= "" then GameTooltip:AddLine("Takes extra damage from: " .. f.hurtBy, 1, 0.5, 0.4) end
            if f.resists ~= "" then GameTooltip:AddLine("Takes less damage from: " .. f.resists, 0.4, 1, 0.4) end
        end
        if s == "E" then
            GameTooltip:AddLine(" ")
            for slot = 1, 3 do
                local a = S.eabil[slot]
                if a then
                    GameTooltip:AddLine(a.name .. (a.cdLeft > 0 and ("  |cffff6060(ready in " .. a.cdLeft .. (a.cdLeft == 1 and " round)|r" or " rounds)|r")) or (a.cd > 0 and ("  |cff999999(cooldown " .. a.cd .. ")|r") or "")), 1, 0.82, 0)
                    GameTooltip:AddLine(a.tip, 0.9, 0.9, 0.9, 1)
                end
            end
        end
        GameTooltip:Show()
    end)
    p:SetScript("OnLeave", function() GameTooltip:Hide() end)
    p.st = {}   -- status icons (buffs / debuffs with turns left), up to 6
    for i = 1, 6 do
        local b = StatusIcon(p)
        b:SetPoint(isRight and "TOPRIGHT" or "TOPLEFT", p.hp, isRight and "BOTTOMRIGHT" or "BOTTOMLEFT", (isRight and -1 or 1) * (2 + (i - 1) * 38), -8)
        b:Hide(); p.st[i] = b
    end
    p.pips = {}   -- the team's other pets as small status icons below the panel
    for i = 1, 3 do
        local b = CreateFrame("Frame", nil, p); b:SetSize(26, 26)
        b:SetPoint(isRight and "TOPRIGHT" or "TOPLEFT", p, isRight and "BOTTOMRIGHT" or "BOTTOMLEFT", (isRight and -1 or 1) * (8 + (i - 1) * 30), -2)
        b.t = b:CreateTexture(nil, "ARTWORK"); b.t:SetAllPoints()
        b.x = b:CreateTexture(nil, "OVERLAY"); b.x:SetAllPoints(); b.x:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up"); b.x:Hide()
        b.ring = b:CreateTexture(nil, "OVERLAY"); b.ring:SetPoint("TOPLEFT", -2, 2); b.ring:SetPoint("BOTTOMRIGHT", 2, -2)
        b.ring:SetTexture(WHITE); b.ring:SetVertexColor(1, 0.85, 0.2); b.ring:SetDrawLayer("BACKGROUND")
        p.pips[i] = b
    end
    return p
end

local function ShowStatuses(s, list)   -- list = parsed statuses of side s
    local w = side[s]
    for i, b in ipairs(w.st) do
        local st = list[i]; b.st = st
        if st then
            b:Show(); b.t:SetTexture("Interface\\Icons\\" .. st.icon)
            if st.bad then b.edge:SetVertexColor(0.9, 0.15, 0.15, 1) else b.edge:SetVertexColor(0.3, 0.85, 0.3, 1) end
            b.turns:SetText(st.turns > 0 and st.turns or ""); b.stk:SetText(st.stacks > 1 and ("x" .. st.stacks) or "")
        else b:Hide() end
    end
end
local function ParseStatuses(text)
    local list = {}
    for label, icon, turns, stacks, bad in (text or ""):gmatch("([^~;]+)~([^~;]+)~(%d+)~(%d+)~(%d)") do
        list[#list + 1] = { label = label, icon = icon, turns = tonumber(turns), stacks = tonumber(stacks), bad = bad == "1" }
    end
    return list
end

local BREED = { [3] = "B/B", [4] = "P/P", [5] = "S/S", [6] = "H/H", [7] = "H/P", [8] = "P/S",
    [9] = "H/S", [10] = "P/B", [11] = "S/B", [12] = "H/B" }

local function Refresh(instantSide)
    for _, s in ipairs({ "P", "E" }) do
        local w, a = side[s], S[s][S.act[s]]
        if a then
            w.model:Set(a.entry, a.icon, a.q, a.hp <= 0, a.scale); w.name:SetText(a.name); w.name:SetTextColor(unpack(QCOL[a.q or 1])); w.lvl:SetText("Lv " .. a.lv .. (a.breed and ("  " .. a.breed) or ""))
            if s == "E" then local o = S.own[S.act.E]; w.own:SetText(o and o.text or ""); if o then w.own:SetTextColor(o.r, o.g, o.b) end else w.own:SetText("") end
            SetHP(w.hp, a.hp, a.max, instantSide == s or instantSide == "all")
        end
        for i = 1, 3 do
            local pip, p = w.pips[i], S[s][i]
            ShowIf(pip, p ~= nil)
            if p then
                pip.t:SetTexture("Interface\\Icons\\" .. p.icon); pip.t:SetDesaturated(p.hp <= 0)
                ShowIf(pip.x, p.hp <= 0); ShowIf(pip.ring, i == S.act[s])
            end
        end
    end
    -- bottom bar
    for i, b in ipairs(abBtns) do
        local a = S.abil[i]; ShowIf(b, a ~= nil)
        if a then b.icon:SetTexture("Interface\\Icons\\" .. a.icon) end
        local cd = S.cd[i] or 0
        local ok = S.canAct and not S.force and cd == 0
        EnableIf(b, ok); b.icon:SetDesaturated(not ok)
        b.cdTxt:SetText(cd > 0 and cd or "")
    end
    local n = 0
    for i = 1, 3 do
        if i ~= S.act.P and S.P[i] then
            n = n + 1; local b, p = benchBtns[n], S.P[i]
            b.idx = i; b:Show(); b.model:Set(p.entry, p.icon, p.q, p.hp <= 0, p.scale)
            b.lv:SetText(p.lv)
            local ok = S.canAct and p.hp > 0
            EnableIf(b, ok); b.icon:SetDesaturated(not ok); b.model:SetAlpha(ok and 1 or 0.55)
            b.hpbar:SetValue(p.max > 0 and p.hp / p.max or 0); b.hpbar:SetStatusBarColor(HPColor(p.max > 0 and p.hp / p.max or 0))
        end
    end
    for k = n + 1, #benchBtns do benchBtns[k]:Hide() end
    EnableIf(quitBtn, true)
    local tok = S.canAct and S.canTrap and not S.force; EnableIf(trapBtn, tok); trapBtn.icon:SetDesaturated(not tok)
end

local function Say(text, secs)
    banner:SetText(text); banner:SetAlpha(1); banner.fade = secs or 2.2
end

-- "You have collected <Pet>": big text in the middle of the screen for a few seconds
local colFrame
CollectedFx = function(name, q)
    if not colFrame then
        colFrame = CreateFrame("Frame", nil, UIParent); colFrame:SetSize(600, 60); colFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 120); colFrame:SetFrameStrata("FULLSCREEN_DIALOG"); colFrame:Hide()
        colFrame.t = colFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge"); colFrame.t:SetAllPoints()
        colFrame:SetScript("OnUpdate", function(self, e) self.left = self.left - e; if self.left <= 0 then self:Hide() elseif self.left < 1 then self:SetAlpha(self.left) end end)
    end
    local c = QHEX[q or 1] or "|cffffffff"
    colFrame.t:SetText("You have collected " .. c .. name .. "|r!"); colFrame.left = 4.5; colFrame:SetAlpha(1); colFrame:Show()
end

-- Level-up graphic (like the character's): a gold star burst behind a big "Level Up!" with the pet's name and new level, plus the level-up sound; fades after ~3.5 s
local luFrame
local function LevelUpFx(name, lv)
    if not luFrame then
        local f = CreateFrame("Frame", nil, UIParent); f:SetSize(420, 160); f:SetPoint("CENTER", UIParent, "CENTER", 0, 170); f:SetFrameStrata("FULLSCREEN_DIALOG"); f:Hide()
        f.burst = f:CreateTexture(nil, "BACKGROUND"); f.burst:SetTexture("Interface\\Cooldown\\star4"); f.burst:SetBlendMode("ADD"); f.burst:SetPoint("CENTER"); f.burst:SetVertexColor(1, 0.85, 0.25)
        f.title = f:CreateFontString(nil, "OVERLAY"); f.title:SetFont("Fonts\\FRIZQT__.TTF", 38, "OUTLINE"); f.title:SetPoint("CENTER", 0, 14); f.title:SetTextColor(1, 0.82, 0)
        f.sub = f:CreateFontString(nil, "OVERLAY"); f.sub:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE"); f.sub:SetPoint("TOP", f.title, "BOTTOM", 0, -6); f.sub:SetTextColor(1, 1, 1)
        f:SetScript("OnUpdate", function(self, e)
            self.t = (self.t or 0) + e; local t = self.t
            local grow = math.min(1, t / 0.5); self.burst:SetSize(120 + 380 * grow, 120 + 380 * grow)
            self.burst:SetAlpha(t < 0.5 and grow or math.max(0, 1 - (t - 0.5) / 2.5))
            self:SetAlpha(t < 2.8 and 1 or math.max(0, 1 - (t - 2.8) / 0.7))
            if t > 3.5 then self:Hide() end
        end)
        luFrame = f
    end
    luFrame.title:SetText("Level Up!"); luFrame.sub:SetText(name .. " is now level " .. lv)
    luFrame.t = 0; luFrame:SetAlpha(1); luFrame:Show()
    pcall(PlaySound, "LEVELUPSOUND")
end

local function ButtonFrame(parent, size, name)
    local b = CreateFrame("Button", name, parent)
    b:SetSize(size, size)
    b.icon = b:CreateTexture(nil, "ARTWORK"); b.icon:SetPoint("TOPLEFT", 3, -3); b.icon:SetPoint("BOTTOMRIGHT", -3, 3)
    b.border = b:CreateTexture(nil, "OVERLAY"); b.border:SetAllPoints(); b.border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    b.border:SetBlendMode("ADD"); b.border:SetAlpha(0)
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square"); b:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    b:SetScript("OnEnter", function(self) self.border:SetAlpha(0.9); if self.tip then self.tip(self) end end)
    b:SetScript("OnLeave", function(self) self.border:SetAlpha(0); GameTooltip:Hide() end)
    return b
end

local function Build()
    top = CreateFrame("Frame", "PBTestTop", UIParent); top:SetSize(760, 130); top:SetPoint("TOP", 0, -8); top:SetFrameStrata("HIGH"); top:Hide()
    side.P = Panel("P", false); side.E = Panel("E", true)
    local vs = top:CreateTexture(nil, "OVERLAY"); vs:SetSize(76, 76); vs:SetPoint("TOP", 0, 6)
    vs:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    local vt = top:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); vt:SetPoint("CENTER", vs, "CENTER", 0, 0); vt:SetText("VS"); vt:SetTextColor(unpack(GOLD))
    turnTxt = top:CreateFontString(nil, "OVERLAY", "GameFontNormal"); turnTxt:SetPoint("TOP", vs, "BOTTOM", 0, 4)

    banner = top:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge"); banner:SetPoint("TOP", top, "BOTTOM", 0, -52); banner:SetTextColor(unpack(GOLD))
    banner.fade = 0
    top:SetScript("OnUpdate", function(_, e)
        if banner.fade > 0 then banner.fade = banner.fade - e; if banner.fade < 0.6 then banner:SetAlpha(math.max(0, banner.fade / 0.6)) end end
    end)

    bottom = CreateFrame("Frame", "PBTestBottom", UIParent); bottom:SetSize(540, 96); bottom:SetPoint("BOTTOM", 0, 78)
    bottom:SetFrameStrata("HIGH"); bottom:SetBackdrop(BACKDROP); bottom:Hide()
    abBtns = {}
    for i = 1, 3 do
        local b = ButtonFrame(bottom, 50, "WotlkPbAbility" .. i); b:SetPoint("LEFT", 24 + (i - 1) * 58, 0)
        b.key = b:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall"); b.key:SetPoint("TOPLEFT", 3, -3); b.key:SetText(i)
        b.cdTxt = b:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge"); b.cdTxt:SetPoint("CENTER")
        b.tip = function(self)
            local a = S.abil[i]; if not a then return end
            GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText(a.name, 1, 0.82, 0); GameTooltip:AddLine(a.tip, 1, 1, 1, 1)
            if a.cd > 0 then GameTooltip:AddLine("Cooldown: " .. a.cd .. " rounds", 0.7, 0.7, 0.7) end
            GameTooltip:Show()
        end
        b:SetScript("OnClick", function() if S.canAct and not S.force then S.canAct = false; AcoreLib.Send("pbt", "cmd", "A" .. i); Refresh() end end)
        abBtns[i] = b
    end
    local div = bottom:CreateTexture(nil, "ARTWORK"); div:SetSize(2, 56); div:SetPoint("LEFT", 208, 0); div:SetTexture(WHITE); div:SetVertexColor(0.5, 0.4, 0.15, 0.8)
    benchBtns = {}
    for k = 1, 2 do
        local b = ButtonFrame(bottom, 62); b:SetPoint("LEFT", 224 + (k - 1) * 72, 0)
        b.model = ModelBox(b, 62); b.model:SetAllPoints(b); b.model:SetFrameLevel(b:GetFrameLevel() - 1)
        b.icon:SetTexture(nil); b.border:SetTexture(nil)
        b.lvf = CreateFrame("Frame", nil, b); b.lvf:SetAllPoints(b); b.lvf:SetFrameLevel(b.model.m:GetFrameLevel() + 3); b.lv = b.lvf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); b.lv:SetPoint("BOTTOMRIGHT", -5, 12)
        b.key = b:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall"); b.key:SetPoint("TOPLEFT", 3, -3); b.key:SetText(3 + k)
        b.hpbar = CreateFrame("StatusBar", nil, b); b.hpbar:SetStatusBarTexture(WHITE); b.hpbar:SetStatusBarColor(0.2, 0.85, 0.2)
        b.hpbar:SetMinMaxValues(0, 1); b.hpbar:SetPoint("BOTTOMLEFT", 5, 4); b.hpbar:SetPoint("BOTTOMRIGHT", -5, 4); b.hpbar:SetHeight(6); b.hpbar:SetFrameLevel(b:GetFrameLevel() + 2)
        b.tip = function(self)
            local p = S.P[self.idx]; if not p then return end
            GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText("Swap to " .. p.name, 1, 0.82, 0)
            GameTooltip:AddLine("Level " .. p.lv .. "  -  " .. p.hp .. " / " .. p.max .. " HP", 1, 1, 1); GameTooltip:AddLine("Swapping takes your turn.", 0.7, 0.7, 0.7); GameTooltip:Show()
        end
        b:SetScript("OnClick", function(self) if S.canAct then S.canAct = false; AcoreLib.Send("pbt", "cmd", "S" .. self.idx); Refresh() end end)
        benchBtns[k] = b
    end
    local div2 = bottom:CreateTexture(nil, "ARTWORK"); div2:SetSize(2, 56); div2:SetPoint("LEFT", 376, 0); div2:SetTexture(WHITE); div2:SetVertexColor(0.5, 0.4, 0.15, 0.8)
    quitBtn = ButtonFrame(bottom, 50); quitBtn:SetPoint("LEFT", 394, 0); quitBtn.icon:SetTexture("Interface\\Icons\\Ability_Rogue_Sprint")
    quitBtn.tip = function(self) GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText("Forfeit", 1, 0.82, 0); GameTooltip:Show() end
    quitBtn:SetScript("OnClick", function() AcoreLib.Send("pbt", "quit", "") end)
    trapBtn = ButtonFrame(bottom, 50); trapBtn:SetPoint("LEFT", 454, 0); trapBtn.icon:SetTexture("Interface\\Icons\\INV_Misc_Net_01")
    trapBtn.tip = function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText("Capture", 1, 0.82, 0)
        GameTooltip:AddLine("Traps the enemy pet. Only possible when it is at 35% health or less. Uses your turn.", 1, 1, 1, 1)
        if not S.canTrap then GameTooltip:AddLine("Weaken it first.", 1, 0.3, 0.3) end
        GameTooltip:Show()
    end
    trapBtn:SetScript("OnClick", function() if S.canAct and S.canTrap then S.canAct = false; AcoreLib.Send("pbt", "cmd", "T"); Refresh() end end)
    local hint = bottom:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); hint:SetPoint("RIGHT", -16, 0); hint:SetWidth(80); hint:SetJustifyH("CENTER")
    bottom.hint = hint

end

function Close() PBTest_closed = (PBTest_closed or 0) + 1; if top then top:Hide(); bottom:Hide(); pcall(ClearOverrideBindings, bottom) end end
local function Num(x) return tonumber(x) or 0 end

-- ---------------------------------------------------------------- weather: a screen effect while a weather ability is active (visual only)
-- ids: 205 Blizzard (snow), 203 Lightning Storm (rain + flashes), 454 Sandstorm (blowing sand), 229 Cleansing Rain (rain); 0 = clear
local WX = { [205] = { tint = { 0.75, 0.85, 1, 0.16 }, n = 60, w = 3, h = 3, vx = -25, vy = -90, col = { 1, 1, 1, 0.9 } },
             [203] = { tint = { 0.2, 0.22, 0.35, 0.28 }, n = 70, w = 1, h = 16, vx = -60, vy = -700, col = { 0.7, 0.8, 1, 0.55 }, flash = true },
             [454] = { tint = { 0.85, 0.65, 0.3, 0.24 }, n = 70, w = 14, h = 2, vx = 650, vy = -40, col = { 0.9, 0.75, 0.4, 0.6 } },
             [229] = { tint = { 0.25, 0.4, 0.6, 0.18 }, n = 60, w = 1, h = 14, vx = -40, vy = -600, col = { 0.6, 0.75, 1, 0.55 } } }
local wxFrame, wxCur, wxLeft, wxParts, wxFlash = nil, nil, 0, {}, 0
local function WxBuild()
    if wxFrame then return end
    wxFrame = CreateFrame("Frame", "WotlkPbWeather", UIParent)
    wxFrame:SetAllPoints(UIParent); wxFrame:SetFrameStrata("BACKGROUND"); wxFrame:EnableMouse(false); wxFrame:Hide()
    wxFrame.tint = wxFrame:CreateTexture(nil, "BACKGROUND"); wxFrame.tint:SetAllPoints(); wxFrame.tint:SetTexture("Interface\\Buttons\\WHITE8X8")
    wxFrame.flash = wxFrame:CreateTexture(nil, "ARTWORK"); wxFrame.flash:SetAllPoints(); wxFrame.flash:SetTexture("Interface\\Buttons\\WHITE8X8"); wxFrame.flash:SetVertexColor(1, 1, 1, 0)
    for i = 1, 70 do
        local t = wxFrame:CreateTexture(nil, "OVERLAY"); t:SetTexture("Interface\\Buttons\\WHITE8X8"); t:Hide()
        wxParts[i] = { t = t, x = 0, y = 0 }
    end
    wxFrame:SetScript("OnUpdate", function(_, e)
        local w = WX[wxCur]; if not w then return end
        local W, H = UIParent:GetWidth(), UIParent:GetHeight()
        for i = 1, w.n do
            local p = wxParts[i]
            p.x = p.x + w.vx * e * (0.7 + (i % 5) * 0.15); p.y = p.y + w.vy * e * (0.7 + (i % 5) * 0.15)
            if p.y < -10 or p.x < -20 or p.x > W + 20 then p.x = math.random(0, W); p.y = H + math.random(0, 40); if w.vx > 100 then p.x = -10; p.y = math.random(0, H) end end
            p.t:ClearAllPoints(); p.t:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", p.x, p.y)
        end
        if w.flash then
            wxFlash = wxFlash - e
            if wxFlash <= 0 then wxFlash = 2.5 + math.random() * 3; wxFrame.flashT = 0.25 end
            if wxFrame.flashT and wxFrame.flashT > 0 then wxFrame.flashT = wxFrame.flashT - e; wxFrame.flash:SetVertexColor(1, 1, 1, math.max(0, wxFrame.flashT) * 1.4) else wxFrame.flash:SetVertexColor(1, 1, 1, 0) end
        end
    end)
end
local WXICON = { [205] = "Spell_Frost_IceStorm", [203] = "Spell_Lightning_LightningBolt01", [454] = "Spell_Nature_Cyclone", [229] = "Spell_Nature_Tranquility" }
local WXNAME = { [205] = "Blizzard", [203] = "Lightning Storm", [454] = "Sandstorm", [229] = "Cleansing Rain" }
local wxBadge, wxRounds = nil, 0
local function WxBadgeUpdate()
    if not wxBadge then
        wxBadge = CreateFrame("Frame", "WotlkPbWeatherBadge", UIParent); wxBadge:SetSize(150, 62); wxBadge:SetPoint("TOP", UIParent, "TOP", 0, -150); wxBadge:SetFrameStrata("HIGH")
        wxBadge.icon = wxBadge:CreateTexture(nil, "ARTWORK"); wxBadge.icon:SetSize(40, 40); wxBadge.icon:SetPoint("TOP", 0, 0)
        wxBadge.text = wxBadge:CreateFontString(nil, "OVERLAY", "GameFontNormal"); wxBadge.text:SetPoint("TOP", wxBadge.icon, "BOTTOM", 0, -2)
        wxBadge:Hide()
    end
    if wxCur and WXICON[wxCur] and wxRounds > 0 then
        wxBadge.icon:SetTexture("Interface\\Icons\\" .. WXICON[wxCur]); wxBadge.text:SetText(WXNAME[wxCur] .. " (" .. wxRounds .. ")"); wxBadge:Show()
    else wxBadge:Hide() end
end
local function WxSet(id, rounds)
    WxBuild(); wxCur = id; wxRounds = rounds or 0; WxBadgeUpdate()
    local w = WX[id]
    if not w then wxFrame:Hide(); return end
    wxFrame.tint:SetVertexColor(unpack(w.tint)); wxFrame.flash:SetVertexColor(1, 1, 1, 0); wxFlash = 1.5
    local W, H = UIParent:GetWidth(), UIParent:GetHeight()
    for i = 1, 70 do
        local p = wxParts[i]
        if i <= w.n then p.x, p.y = math.random(0, W), math.random(0, H); p.t:SetSize(w.w, w.h); p.t:SetVertexColor(unpack(w.col)); p.t:Show() else p.t:Hide() end
    end
    wxFrame:Show()
end

-- ---------------------------------------------------------------- battle music: a random battleground song while a battle runs (/pbtest music = on/off)
local MUSIC = { "pvp1", "pvp2", "pvp3", "pvp4", "pvp5" }   -- Sound\\Music\\ZoneMusic\\PVP (the same files the Jukebox lists)
local MUSIC_LEN = { 46.7, 52.6, 40.4, 62.9, 61.8 }
local music = { on = false, left = 0, last = 0 }
local musicFrame = CreateFrame("Frame")
local function PlayNext()
    local i; repeat i = math.random(#MUSIC) until i ~= music.last or #MUSIC == 1
    music.last, music.left = i, MUSIC_LEN[i] + 0.5
    pcall(PlayMusic, "Sound\\Music\\ZoneMusic\\PVP\\" .. MUSIC[i] .. ".mp3")
end
musicFrame:SetScript("OnUpdate", function(_, e)
    if not music.on then return end
    music.left = music.left - e
    if music.left <= 0 then PlayNext() end   -- the next random song when one ends
end)
local function MusicStart() if WotlkPbMusicOff or music.on then return end music.on = true; PlayNext() end
local function MusicStop() if not music.on then return end music.on = false; pcall(StopMusic) end

-- ---------------------------------------------------------------- server messages
local function Setup()
    if top then return end
    Build()
    AcoreLib.On("pbt", "begin", function() WxSet(0); MusicStart(); S.P, S.E, S.act, S.canAct, S.force, S.abil, S.cd = {}, {}, { P = 1, E = 1 }, false, false, {}, { 0, 0, 0 }; S.tips, S.info, S.eabil, S.own = {}, {}, {}, {}; ShowStatuses("P", {}); ShowStatuses("E", {}); AcoreLib.Send("pbj", "prime", ""); top:Show(); bottom:Show(); banner:SetText(""); turnTxt:SetText("")
        for i = 1, 3 do pcall(SetOverrideBindingClick, bottom, true, tostring(i), "WotlkPbAbility" .. i) end   -- keys 1-3 use the battle abilities, not the action bar, while the battle runs
    end)
    AcoreLib.On("pbt", "weather", function(p) local id, n = p:match("^(%d+)|(%d+)"); WxSet(tonumber(id) or 0, tonumber(n) or 0) end)
    AcoreLib.On("pbt", "st", function(p)
        local s, i, lv, hp, max, icon, q, entry, sc, name = p:match("^(%a),(%d+),(%d+),(%d+),(%d+),([^,]+),(%d+),(%d+),(%d+),(.+)$")
        if s then
            S[s][Num(i)] = { lv = Num(lv), hp = Num(hp), max = Num(max), icon = icon, q = Num(q), entry = Num(entry), scale = Num(sc) / 100, name = name }; Refresh("all") end
    end)
    AcoreLib.On("pbt", "own", function(p)   -- the enemy pet i against our collection: status 0 = not collected, 1 = this one would be an upgrade, 2 = we own the same or better
        local i, st, oq, ol = p:match("^(%d+),(%d),(%d),(%d+)$"); if not i then return end
        st = tonumber(st); local mine = QNAME[tonumber(oq)] and ("Lv " .. ol .. " " .. QNAME[tonumber(oq)]) or ""
        if st == 0 then S.own[tonumber(i)] = { text = "NOT COLLECTED", r = 0.3, g = 1, b = 0.3 }
        else S.own[tonumber(i)] = { text = "Collected (" .. mine .. ")", r = 0.7, g = 0.7, b = 0.7 } end
        Refresh()
    end)
    AcoreLib.On("pbt", "breed2", function(p)
        local index, breed, power, speed = p:match("^(%d+),(%d+),(%d+),(%d+)$")
        local pet = index and S.E[Num(index)]
        if not pet then return end
        pet.breed, pet.power, pet.speed = BREED[Num(breed)], Num(power), Num(speed)
        Refresh()
    end)
    AcoreLib.On("pbt", "got", function(p) local q, name = p:match("^(%d),(.+)$"); if name then CollectedFx(name, tonumber(q)) end end)
    AcoreLib.On("pbt", "abil", function(p)
        local slot, icon, name, tip, cd = p:match("^(%d)|([^#]*)#([^#]*)#([^#]*)#(%d+)$")
        if slot then S.abil[tonumber(slot)] = { icon = icon, name = name, tip = tip, cd = tonumber(cd) }; Refresh() end
    end)
    AcoreLib.On("pbt", "stip", function(p) local label, tip = p:match("^([^#]*)#(.*)$"); if label then S.tips[label] = tip end end)
    AcoreLib.On("pbt", "info", function(p)
        local s, name, strong, weak, hurtBy, resists = p:match("^(%a)|([^|]*)|([^|]*)|([^|]*)|([^|]*)|([^|]*)$")
        if s then S.info[s] = { name = name, strong = strong, weak = weak, hurtBy = hurtBy, resists = resists } end
    end)
    AcoreLib.On("pbt", "eabil", function(p)
        local slot, icon, name, tip, cd, left = p:match("^(%d)|([^#]*)#([^#]*)#([^#]*)#(%d+)#(%d+)$")
        if slot then S.eabil[tonumber(slot)] = { icon = icon, name = name, tip = tip, cd = tonumber(cd), cdLeft = tonumber(left) } end
    end)
    AcoreLib.On("pbt", "tag", function(p) local s, text = p:match("^(%a)|(.*)$"); if s then S.statuses = S.statuses or {}; S.statuses[s] = ParseStatuses(text); ShowStatuses(s, S.statuses[s]) end end)
    AcoreLib.On("pbt", "tag2", function(p)   -- the rest of a long status list
        local s, text = p:match("^(%a)|(.*)$"); if not s then return end
        S.statuses = S.statuses or {}; local list = S.statuses[s] or {}
        for _, st in ipairs(ParseStatuses(text)) do list[#list + 1] = st end
        S.statuses[s] = list; ShowStatuses(s, list)
    end)
    AcoreLib.On("pbt", "in", function(p) local s, i = p:match("^(%a),(%d+)"); S.act[s] = Num(i); Refresh(s); Say(S[s][Num(i)].name .. (s == "E" and " appears!" or ", go!")) end)
    AcoreLib.On("pbt", "act", function(p)
        local s, i, ab = p:match("^(%a),(%d+),(.+)$"); local pet = S[s][Num(i)]
        Say(pet.name .. " uses " .. ab .. "!", 1.8); S.canAct = false; Refresh(); turnTxt:SetText("")
    end)
    AcoreLib.On("pbt", "hp", function(p)
        local s, i, hp, max, delta = p:match("^(%a),(%d+),(%d+),(%d+),(.+)$"); i = Num(i)
        local pet = S[s][i]; pet.hp, pet.max = Num(hp), Num(max)
        if S.act[s] == i then SetHP(side[s].hp, pet.hp, pet.max); Float(side[s].hp, delta, delta:sub(1, 1) == "-") end
        Refresh()
    end)
    AcoreLib.On("pbt", "fnt", function(p) local s, i = p:match("^(%a),(%d+)"); i = Num(i); S[s][i].hp = 0; Say(S[s][i].name .. " has fainted!"); Refresh() end)
    AcoreLib.On("pbt", "turn", function(p)
        if wxCur and wxCur ~= 0 and wxRounds > 0 then wxRounds = wxRounds - 1; if wxRounds <= 0 then WxSet(0) else WxBadgeUpdate() end end   -- one round passed
        local mode, c1, c2, c3, trap, why = p:match("^(%a+);(%d+),(%d+),(%d+);?(%d?);?(.*)$")
        S.canTrap = trap == "1"
        S.cd = { tonumber(c1) or 0, tonumber(c2) or 0, tonumber(c3) or 0 }
        S.force = (mode == "force"); S.canAct = (mode ~= "stun" and mode ~= "lock"); Refresh()   -- "stun": crowd controlled, every button stays grey and the server passes the turn
        turnTxt:SetText(mode == "lock" and (why or "") or mode == "stun" and ((why and why ~= "" and why or "Stunned") .. " - turn passes") or (S.force and "Choose your next pet" or "Your turn"))
        bottom.hint:SetText(S.force and "Pick a pet to send out" or "")
        if S.force then Say("Choose your next pet!", 3) end
    end)
    AcoreLib.On("pbt", "msg", function(p) Say(p, 3); DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[Pet battle]|r " .. p) end)
    AcoreLib.On("pbt", "end", function(p)
        MusicStop(); WxSet(0)
        S.canAct = false; Refresh(); turnTxt:SetText("")
        if p == "win" then Say("Victory!", 4) elseif p == "loss" then Say("Defeat... your pets limp home with 1 HP.", 4) else Say("The battle has ended.", 4) end
    end)
    AcoreLib.On("pbt", "xp", function(p)
        local name, gain, lv, ups = p:match("^([^,]+),(%d+),(%d+),(%d+)$")
        if not name then return end
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100" .. name .. " gains " .. gain .. " experience.|r")
        if Num(ups) > 0 then
            DEFAULT_CHAT_FRAME:AddMessage("|cff66ff66" .. name .. " reached level " .. lv .. "!|r")
            LevelUpFx(name, lv)
        end
    end)
    AcoreLib.On("pbt", "done", function()   -- the battle is over: leave the result banner up for a few seconds, then close the bars
        local f = CreateFrame("Frame"); local t = 0
        f:SetScript("OnUpdate", function(self, e) t = t + e; if t > 3.5 then Close(); self:SetScript("OnUpdate", nil) end end)
    end)
end

-- Build the windows and register the server message handlers AT LOAD: a battle can be started by a wild pet's gossip menu, long before /pbtest is ever typed.
Setup()

local protocol = CreateFrame("Frame")
protocol:RegisterEvent("PLAYER_ENTERING_WORLD")
protocol:SetScript("OnEvent", function() AcoreLib.Send("pbj", "hello2", "") end)

SLASH_PBTEST1 = "/pbtest"
SlashCmdList["PBTEST"] = function(arg)
    Setup()
    local cmd, rest = (arg or ""):match("^(%S*)%s*(.*)$")
    if cmd == "quit" then AcoreLib.Send("pbt", "quit", "")
    elseif cmd == "clean" then Setup(); top:Show(); AcoreLib.Send("pbt", "clean", "")
    elseif cmd == "music" then
        WotlkPbMusicOff = not WotlkPbMusicOff; if WotlkPbMusicOff then MusicStop() end
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[Pet battle]|r battle music " .. (WotlkPbMusicOff and "off" or "on"))
    elseif cmd == "fx" then AcoreLib.Send("pbt", "fx", rest)
    elseif cmd == "trace" then AcoreLib.Send("pbt", "trace", "")
    elseif cmd == "bad" then AcoreLib.Send("pbt", "bad", (rest or ""):sub(1, 120))   -- flags the last abilities that looked wrong (logs/pb_bad.tsv); the comment is optional
    else AcoreLib.Send("pbt", "start", (cmd or "") .. " " .. (rest or "")) end
end
