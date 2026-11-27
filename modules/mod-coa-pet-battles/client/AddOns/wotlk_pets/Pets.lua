-- Pet Journal: owned battle pets (Pets tab) and team setup (Teams tab). Server module "pbj" (scripts/pb_store.lua).  /pets
local WHITE = "Interface\\Buttons\\WHITE8X8"
local BACKDROP = { bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
                   tile = true, tileSize = 32, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } }
-- the ten retail pet families (the server sends the family name with every pet)
local FAMILIES = { "Aquatic", "Beast", "Critter", "Dragonkin", "Elemental", "Flying", "Humanoid", "Magic", "Mechanical", "Undead" }
local FAMCOL = { Aquatic = { 0.35, 0.75, 1 }, Beast = { 0.85, 0.65, 0.35 }, Critter = { 0.8, 0.8, 0.8 }, Dragonkin = { 0.9, 0.35, 0.35 }, Elemental = { 1, 0.6, 0.2 },
              Flying = { 0.7, 0.85, 1 }, Humanoid = { 0.95, 0.9, 0.5 }, Magic = { 0.75, 0.5, 1 }, Mechanical = { 0.6, 0.7, 0.75 }, Undead = { 0.55, 0.85, 0.5 } }
local SLOTNAME = { "Basic", "Utility", "Major" }
local GOLD = { 1, 0.82, 0 }
local QCOL = { { 1, 1, 1 }, { 0.12, 1, 0 }, { 0, 0.44, 0.87 }, { 0.64, 0.21, 0.93 } }   -- common / uncommon / rare / epic: white, green, blue, purple
local QHEX = { "|cffffffff", "|cff1eff00", "|cff0070dd", "|cffa335ee" }
local BREED = { [3] = "B/B", [4] = "P/P", [5] = "S/S", [6] = "H/H", [7] = "H/P", [8] = "P/S", [9] = "H/S", [10] = "P/B", [11] = "S/B", [12] = "H/B" }
local function BreedName(p) return BREED[p.breed] or "Fixed" end
local QNAME = { "Common", "Uncommon", "Rare", "Epic" }
local QNAMECOL = {}; for q = 1, 4 do QNAMECOL[q] = QHEX[q] .. QNAME[q] .. "|r" end


local S = { pets = {}, abil = {}, teams = { { 0, 0, 0 }, { 0, 0, 0 }, { 0, 0, 0 } }, active = 1, follow = 0, sel = nil, tab = 1, primed = false, filter = "", asked = {}, family = {}, qual = {}, zone = nil, view = "collected", drag = nil }
local frame, rowsHolder, rows, scroll, search, tabs, paneP, paneT, model, modelFor
local Bind   -- fills the few row frames that are on screen (the list is VIRTUAL: 1,849 species never become 1,849 frames)
local ROW_H, ROW_FRAMES = 42, 20   -- the list area shows ~7.5 rows; 20 frames cover it with room to spare (still 90x fewer than the old one-frame-per-species list)
local function ShowIf(f, c) if c then f:Show() else f:Hide() end end
local function Num(x) return tonumber(x) or 0 end
local function Color(fs, a) local c = FAMCOL[a] or { 1, 1, 1 }; fs:SetTextColor(c[1], c[2], c[3]) end

-- the pets you have NOT collected: one pseudo pet per species from the generated PetDex.lua (flag dex), so they can be listed, searched and inspected like owned ones
local dexCache = {}
local function PetOf(sp)
    if not sp or sp == 0 then return nil end
    if sp > 0 then return S.pets[sp] end
    sp = -sp
    local d = WotlkPetDex and WotlkPetDex[sp]; if not d then return nil end
    local x = dexCache[sp]; if not x then x = { dex = true, species = sp, name = d[1], family = d[2], icon = d[3], level = 0, quality = 1 }; dexCache[sp] = x end
    return x
end
local function InTeam(sp) for n = 1, 3 do for i = 1, 3 do if S.teams[n][i] == sp then return true end end end return false end
-- one pet against the whole filter: search (space separated words, ALL must match the name or the family), family menu, quality toggles, "in a team"
local function PetPasses(p, sp, F)
    local name, fam = p.name:lower(), p.family:lower()
    local zs = WotlkPetSpeciesZones and WotlkPetSpeciesZones[p.species]   -- the zones this species lives in (generated data, ZoneLevels.lua)
    if F.zone then
        local here = false; for _, z in ipairs(zs or {}) do if z == F.zone then here = true end end
        if not here then return false end
    end
    local zl = zs and table.concat(zs, " "):lower() or ""
    for word in (F.filter or ""):lower():gmatch("%S+") do if not (name:find(word, 1, true) or fam:find(word, 1, true) or zl:find(word, 1, true)) then return false end end
    if next(F.family) and not F.family[p.family] then return false end
    if next(F.qual) and (p.dex or not F.qual[p.quality or 1]) then return false end   -- an uncollected pet has no quality
    local v = F.view
    if v == "collected" and p.dex then return false end
    if v == "missing" and not p.dex then return false end
    if v == "team" and not InTeam(sp) then return false end
    return true
end
local function Sorted()
    local t, owned = {}, {}
    for id, p in pairs(S.pets) do
        owned[p.species] = true
        if PetPasses(p, id, S) then t[#t + 1] = id end
    end
    S.owned = owned
    if S.view ~= "collected" and S.view ~= "team" and WotlkPetDex then
        for sp in pairs(WotlkPetDex) do if not owned[sp] then local p = PetOf(-sp); if PetPasses(p, -sp, S) then t[#t + 1] = -sp end end end
    end
    table.sort(t, function(a, b)
        local x, y = PetOf(a), PetOf(b)
        if x.name ~= y.name then return x.name < y.name end
        if x.species ~= y.species then return x.species < y.species end
        return a < b
    end)
    return t
end

-- ONE icon per pet TYPE for the whole list / team slots / drag cursor (the per-creature icons were often wrong: a cow showed the boar). The real 3D model is in the detail pane.
local TYPE_ICON = { Humanoid = "INV_Misc_Head_Human_01", Dragonkin = "INV_Misc_Head_Dragon_01", Flying = "Ability_Druid_FlightForm", Undead = "Spell_Shadow_AnimateDead", Critter = "INV_Egg_01",
    Magic = "Spell_Arcane_Arcane01", Elemental = "Spell_Nature_EarthElemental_Totem", Mechanical = "INV_Gizmo_01", Aquatic = "Ability_Druid_AquaticForm", Beast = "Ability_Racial_BearForm" }
local function Icon(p) return "Interface\\Icons\\" .. (TYPE_ICON[p.family] or p.icon) end
-- Real creature portraits: a small head-zoomed 3D model (what the game itself draws for a mob) instead of the family icon (a cow showed the boar icon). The 2D icon stays as the
-- fallback while the client has no model for the creature yet (the server "primes" the records) or the model call fails.
local Refresh
local filterBtns = {}

---------------------------------------------------------------- left list
local function BuildList()
    search = CreateFrame("EditBox", "WotlkPetsSearch", frame, "InputBoxTemplate")
    search:SetSize(200, 20); search:SetPoint("TOPLEFT", 30, -62); search:SetAutoFocus(false)
    search:SetScript("OnTextChanged", function(self) local t = self:GetText() or ""; if t ~= S.filter then S.filter = t; Refresh() end end)
    search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end); search:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); hint:SetTextColor(0.75, 0.75, 0.75); hint:SetPoint("LEFT", search, "RIGHT", 6, 0); hint:SetText("Search")

    -- filters: two drop-down menus (tick several entries) + an "In a team" check box + Clear
    local function Summary(set, all, names)
        local n, last = 0, nil
        for k in pairs(set) do n = n + 1; last = names and names[k] or k end
        return n == 0 and all or (n == 1 and last or (n .. " selected"))
    end
    local function Multi(name, x, w, all, items, set, names)   -- items = list of keys, set = the table of ticked keys, names = optional key -> label
        local dd = CreateFrame("Frame", name, frame, "UIDropDownMenuTemplate"); dd:SetPoint("TOPLEFT", x, -90); UIDropDownMenu_SetWidth(dd, w)
        local function Text() UIDropDownMenu_SetText(dd, Summary(set(), all, names)) end
        UIDropDownMenu_Initialize(dd, function()
            local i = UIDropDownMenu_CreateInfo(); i.text = all; i.notCheckable = 1
            i.func = function() for k in pairs(set()) do set()[k] = nil end; Text(); Refresh() end; UIDropDownMenu_AddButton(i)
            for _, key in ipairs(items) do
                local e = UIDropDownMenu_CreateInfo(); e.text = names and names[key] or key; e.keepShownOnClick = 1; e.isNotRadio = true
                e.checked = set()[key] and true or false
                e.func = function() set()[key] = (not set()[key]) or nil; Text(); Refresh() end
                UIDropDownMenu_AddButton(e)
            end
        end)
        Text(); dd.Text = Text; filterBtns[#filterBtns + 1] = dd
    end
    Multi("WotlkPetsFamilyDD", 4, 80, "All families", FAMILIES, function() return S.family end)
    Multi("WotlkPetsQualityDD", 136, 80, "All qualities", { 1, 2, 3, 4 }, function() return S.qual end, QNAMECOL)
    -- zone: single choice, two levels (continent -> zone) because a drop-down list holds at most 32 entries
    local zdd = CreateFrame("Frame", "WotlkPetsZoneDD", frame, "UIDropDownMenuTemplate"); zdd:SetPoint("TOPLEFT", 4, -122); UIDropDownMenu_SetWidth(zdd, 190)
    local function ZText() UIDropDownMenu_SetText(zdd, S.zone or "All zones") end
    UIDropDownMenu_Initialize(zdd, function(_, level)
        level = level or 1
        if level == 1 then
            local i = UIDropDownMenu_CreateInfo(); i.text = "All zones"; i.notCheckable = 1; i.func = function() S.zone = nil; ZText(); CloseDropDownMenus(); Refresh() end; UIDropDownMenu_AddButton(i, 1)
            for _, g in ipairs(WotlkPetZoneGroups or {}) do
                local e = UIDropDownMenu_CreateInfo(); e.text = g[1]; e.hasArrow = 1; e.notCheckable = 1; e.value = g[1]; UIDropDownMenu_AddButton(e, 1)
            end
        else
            for _, g in ipairs(WotlkPetZoneGroups or {}) do
                if g[1] == UIDROPDOWNMENU_MENU_VALUE then
                    for _, z in ipairs(g[2]) do
                        local e = UIDropDownMenu_CreateInfo(); e.text = z; e.checked = (S.zone == z) and true or false
                        e.func = function() S.zone = z; ZText(); CloseDropDownMenus(); Refresh() end; UIDropDownMenu_AddButton(e, 2)
                    end
                end
            end
        end
    end)
    ZText(); zdd.Text = ZText; filterBtns[#filterBtns + 1] = zdd
    -- view: collected / not collected / in a team (single choice, like retail's collected checkboxes)
    local VIEWS = { { "all", "All pets" }, { "collected", "Collected" }, { "missing", "Not collected" }, { "team", "In a team" } }
    local vdd = CreateFrame("Frame", "WotlkPetsViewDD", frame, "UIDropDownMenuTemplate"); vdd:SetPoint("TOPLEFT", 4, -154); UIDropDownMenu_SetWidth(vdd, 90)
    local function VText() for _, v in ipairs(VIEWS) do if v[1] == S.view then UIDropDownMenu_SetText(vdd, v[2]) end end end
    UIDropDownMenu_Initialize(vdd, function()
        for _, v in ipairs(VIEWS) do
            local e = UIDropDownMenu_CreateInfo(); e.text = v[2]; e.checked = (S.view == v[1]) and true or false
            e.func = function() S.view = v[1]; VText(); CloseDropDownMenus(); Refresh() end; UIDropDownMenu_AddButton(e)
        end
    end)
    VText(); vdd.Text = VText; filterBtns[#filterBtns + 1] = vdd
    local clear = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate"); clear:SetSize(100, 20); clear:SetPoint("TOPLEFT", 176, -158); clear:SetText("Clear filters")
    clear:SetScript("OnClick", function() S.family, S.qual, S.zone, S.view = {}, {}, nil, "collected"; search:SetText(""); S.filter = ""; Refresh() end)
    local holder = CreateFrame("Frame", nil, frame); holder:SetPoint("TOPLEFT", 20, -184); holder:SetSize(262, 316)
    holder.empty = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); holder.empty:SetPoint("CENTER"); holder.empty:SetWidth(200); S.emptyTxt = holder.empty
    holder:SetBackdrop(BACKDROP)
    scroll = CreateFrame("ScrollFrame", "WotlkPetsScroll", holder, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 6, -6); scroll:SetPoint("BOTTOMRIGHT", -26, 6)
    rowsHolder = CreateFrame("Frame", nil, scroll); rowsHolder:SetSize(226, 10); scroll:SetScrollChild(rowsHolder)
    rows = {}
    local oldScroll = scroll:GetScript("OnVerticalScroll")   -- the template's handler moves the scroll bar; we also rebind the rows
    scroll:SetScript("OnVerticalScroll", function(self, off) if oldScroll then oldScroll(self, off) end if Bind then Bind(off) end end)
end

local function PetTip(owner, p, sp)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT"); GameTooltip:SetText(p.name, unpack(QCOL[p.quality or 1]))
    if p.dex then GameTooltip:AddLine("Not collected  -  " .. p.family, 0.6, 0.6, 0.6)
    else
        GameTooltip:AddLine(QNAME[p.quality or 1] .. " " .. p.family .. "  -  Level " .. p.level, 1, 1, 1)
        GameTooltip:AddLine("Health " .. (p.cur or p.hp) .. " / " .. p.hp .. "   Power " .. p.dmg .. "   Speed " .. p.speed, 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Breed " .. BreedName(p) .. "   Copy #" .. sp, 0.8, 0.8, 0.8)
    end
    local zs = WotlkPetSpeciesZones and WotlkPetSpeciesZones[p.species]
    if zs and #zs > 0 then GameTooltip:AddLine("Found in: " .. table.concat(zs, ", ", 1, math.min(3, #zs)) .. (#zs > 3 and (" +" .. (#zs - 3) .. " more") or ""), 0.6, 0.8, 1, 1) end
    GameTooltip:AddLine(p.dex and "Click: details" or "Click: details   Drag: put in a team", 0.6, 0.6, 0.6); GameTooltip:Show()
end
---------------------------------------------------------------- drag and drop (3.3.5 has no drag objects: a cursor icon follows the mouse, the drop target is found with MouseIsOver)
local dragFrame
local PlaceInTeam, EndDrag
local function CancelDrag() S.drag = nil; if dragFrame then dragFrame:Hide() end end
local function StartDrag(sp, fromTeam, fromSlot)
    local p = sp and sp ~= 0 and S.pets[sp]; if not p then return end
    GameTooltip:Hide(); S.drag = { sp = sp, fromTeam = fromTeam, fromSlot = fromSlot }
    if S.tab ~= 2 then S.tab = 2; Refresh() end   -- dragging a pet from the list opens the Teams tab so the slots can be reached
    if not dragFrame then
        dragFrame = CreateFrame("Frame", nil, UIParent); dragFrame:SetSize(36, 36); dragFrame:SetFrameStrata("TOOLTIP")
        dragFrame.tex = dragFrame:CreateTexture(nil, "OVERLAY"); dragFrame.tex:SetAllPoints()
        dragFrame:SetScript("OnUpdate", function(self)
            if not IsMouseButtonDown("LeftButton") then EndDrag(); return end   -- the source button can be hidden mid-drag and never send OnDragStop
            local x, y = GetCursorPosition(); local s = UIParent:GetEffectiveScale(); self:ClearAllPoints(); self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / s, y / s)
        end)
    end
    dragFrame.tex:SetTexture(Icon(p)); dragFrame:Show()
end
function EndDrag()
    local d = S.drag; CancelDrag(); if not d then return end
    local hit
    if paneT and paneT:IsShown() then
        for n = 1, 3 do for i = 1, 3 do if paneT.box[n].slot[i]:IsVisible() and MouseIsOver(paneT.box[n].slot[i]) then hit = { n, i } end end end
    end
    if hit then PlaceInTeam(hit[1], hit[2], d.sp, d.fromTeam, d.fromSlot)
    elseif d.fromTeam and not (frame and MouseIsOver(frame)) then PlaceInTeam(d.fromTeam, d.fromSlot, 0); DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[Pets]|r " .. (S.pets[d.sp] and S.pets[d.sp].name or "Pet") .. " removed from team " .. d.fromTeam .. ".") end   -- a pet dragged out of its slot and dropped away from the window: removed
end

local function Row(i)
    local r = rows[i]
    if r then return r end
    r = CreateFrame("Button", nil, rowsHolder)
    r:SetSize(226, 40)
    r.bg = r:CreateTexture(nil, "BACKGROUND"); r.bg:SetAllPoints(); r.bg:SetTexture(0.15, 0.12, 0.05, 0.6)
    r.sel = r:CreateTexture(nil, "BORDER"); r.sel:SetAllPoints(); r.sel:SetTexture(1, 0.82, 0, 0.25); r.sel:Hide()
    r.icon = r:CreateTexture(nil, "ARTWORK"); r.icon:SetSize(32, 32); r.icon:SetPoint("LEFT", 4, 0)
    r.name = r:CreateFontString(nil, "OVERLAY", "GameFontNormal"); r.name:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 8, -2); r.name:SetJustifyH("LEFT"); r.name:SetWidth(150); r.name:SetHeight(14)
    r.sub = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); r.sub:SetPoint("BOTTOMLEFT", r.icon, "BOTTOMRIGHT", 8, 2)
    r.lvl = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); r.lvl:SetPoint("RIGHT", -8, 0)
    r:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    r:SetScript("OnClick", function(self) S.sel = self.sp; S.tab = 1; S.asked[self.sp] = nil; Refresh() end)
    r:SetScript("OnEnter", function(self) local p = PetOf(self.sp); if p then PetTip(self, p, self.sp) end end)
    r:SetScript("OnLeave", function() GameTooltip:Hide() end)
    r:RegisterForDrag("LeftButton")
    r:SetScript("OnDragStart", function(self) StartDrag(self.sp) end)
    r:SetScript("OnDragStop", function() EndDrag() end)
    rows[i] = r
    return r
end

---------------------------------------------------------------- Pets tab (details)
-- FEEDING: the food in the bags (the server decides what is real food and checks its level; the client only lists Food & Drink items)
local function BagFoods()
    local found, order = {}, {}
    for bag = 0, 4 do for slot = 1, (GetContainerNumSlots(bag) or 0) do
        local link = GetContainerItemLink(bag, slot)
        if link then
            local id = tonumber(link:match("item:(%d+)"))
            local name, _, _, _, minLevel, itype, subtype, _, _, tex = GetItemInfo(link)
            if id and itype == "Consumable" and subtype == "Food & Drink" then
                local _, count = GetContainerItemInfo(bag, slot)
                local f = found[id]
                if not f then f = { id = id, name = name, level = math.max(1, minLevel or 0), count = 0, icon = tex }; found[id] = f; order[#order + 1] = f end
                f.count = f.count + (count or 1)
            end
        end
    end end
    return order
end
local function FoodMenu(dd)
    local p = S.sel and S.pets[S.sel]; if not p then return end
    local list = BagFoods()
    table.sort(list, function(x, y)
        local gx, gy = x.level >= p.level, y.level >= p.level
        if gx ~= gy then return gx end
        if x.level ~= y.level then return x.level < y.level end
        return (x.name or "") < (y.name or "")
    end)
    if #list == 0 then
        local i = UIDropDownMenu_CreateInfo(); i.text = "No food in your bags"; i.notCheckable = 1; i.disabled = 1; UIDropDownMenu_AddButton(i); return
    end
    for n, f in ipairs(list) do
        if n > 28 then break end   -- a drop-down list holds at most 32 entries
        local good = f.level >= p.level
        local i = UIDropDownMenu_CreateInfo(); i.notCheckable = 1
        i.text = (f.icon and ("|T" .. f.icon .. ":14|t ") or "") .. (good and "" or "|cff888888") .. (f.name or "?") .. " x" .. f.count .. "  (level " .. f.level .. (good and ")" or ": too weak)|r")
        i.disabled = (not good) and 1 or nil
        i.func = function() AcoreLib.Send("pbj", "feed2", S.sel .. "," .. f.id); CloseDropDownMenus() end
        UIDropDownMenu_AddButton(i)
    end
end

local RELEASE_DIALOG = "WOTLK_PETS_RELEASE"
StaticPopupDialogs[RELEASE_DIALOG] = {
    text = "Release %s permanently?%s",
    button1 = "Release",
    button2 = CANCEL,
    OnAccept = function(self, id)
        id = id or self.data
        local pet = S.pets[id]
        if pet and pet.source == 1 then AcoreLib.Send("pbj", "release2", id) end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

local function ConfirmRelease(id)
    local pet = S.pets[id]
    if not pet or pet.source ~= 1 then return end
    local effects = ""
    if InTeam(id) then effects = effects .. "\nThis copy will be removed from its teams." end
    if S.follow == id then effects = effects .. "\nThis follower will be dismissed." end
    local label = string.format("%s (Level %d %s, %s, Copy #%d)",
        pet.name, pet.level, QNAME[pet.quality], BreedName(pet), id)
    local popup = StaticPopup_Show(RELEASE_DIALOG, label, effects, id)
    if popup then popup.data = id end
end

local function BuildPets()
    paneP = CreateFrame("Frame", nil, frame); paneP:SetPoint("TOPLEFT", 296, -62); paneP:SetPoint("BOTTOMRIGHT", -20, 16)
    paneP.empty = paneP:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); paneP.empty:SetPoint("CENTER"); paneP.empty:SetText("Select a pet to inspect it.\nDrag a pet from the list into a Teams slot to build a team.")
    local d = CreateFrame("Frame", nil, paneP); d:SetAllPoints(); paneP.d = d
    d.name = d:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge"); d.name:SetPoint("TOPLEFT", 4, -2)
    d.sub = d:CreateFontString(nil, "OVERLAY", "GameFontNormal"); d.sub:SetPoint("TOPLEFT", d.name, "BOTTOMLEFT", 0, -4)
    local mf = CreateFrame("Frame", nil, d); mf:SetSize(250, 250); mf:SetPoint("TOPLEFT", 0, -50); mf:SetBackdrop(BACKDROP)
    model = CreateFrame("DressUpModel", nil, mf); model:SetPoint("TOPLEFT", 6, -6); model:SetPoint("BOTTOMRIGHT", -6, 6)   -- DressUpModel, not PlayerModel: humanoid appearance records (Frostmane, Defias...) draw white on a plain PlayerModel (same fix as wotlk_garrison Preview.lua)
    d.loading = mf:CreateFontString(nil, "OVERLAY", "GameFontDisable"); d.loading:SetPoint("CENTER"); d.loading:SetText("Loading preview...")
    d.stats = d:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); d.stats:SetPoint("TOPLEFT", mf, "TOPRIGHT", 16, -4); d.stats:SetJustifyH("LEFT")
    d.sum = CreateFrame("Button", nil, d, "UIPanelButtonTemplate"); d.sum:SetSize(130, 24); d.sum:SetPoint("TOPLEFT", d.stats, "BOTTOMLEFT", 0, -22)
    d.sum:SetScript("OnClick", function()
        if not S.sel then return end
        if S.follow == S.sel then AcoreLib.Send("pbj", "dismiss", "") else AcoreLib.Send("pbj", "summon2", S.sel) end
    end)
    d.feed = CreateFrame("Button", nil, d, "UIPanelButtonTemplate"); d.feed:SetSize(130, 24); d.feed:SetPoint("TOPLEFT", d.sum, "BOTTOMLEFT", 0, -4); d.feed:SetText("Feed")
    d.feedDD = CreateFrame("Frame", "WotlkPetsFeedDD", d, "UIDropDownMenuTemplate"); UIDropDownMenu_Initialize(d.feedDD, FoodMenu, "MENU")
    d.feed:SetScript("OnClick", function() if S.sel then ToggleDropDownMenu(1, nil, d.feedDD, d.feed, 0, 0) end end)
    d.feed:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:AddLine("Feed", 1, 0.82, 0)
        GameTooltip:AddLine("Food from your bags makes the pet well fed: it recovers 10% of its health every 2 seconds for 20 seconds.", 0.8, 0.8, 0.8, 1)
        GameTooltip:AddLine("The food must be of the pet's level or higher. Not during a battle.", 0.8, 0.8, 0.8, 1); GameTooltip:Show()
    end)
    d.feed:SetScript("OnLeave", function() GameTooltip:Hide() end)
    d.release = CreateFrame("Button", nil, d, "UIPanelButtonTemplate")
    d.release:SetSize(130, 24); d.release:SetPoint("TOPLEFT", d.feed, "BOTTOMLEFT", 0, -4)
    d.release:SetText("Release")
    d.release:SetScript("OnClick", function() ConfirmRelease(S.sel) end)
    d.where = d:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); d.where:SetJustifyH("LEFT"); d.where:SetWidth(228)
    d.hint = d:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); d.hint:SetJustifyH("LEFT"); d.hint:SetWidth(228); d.hint:SetTextColor(0.65, 0.65, 0.65)
    d.hint:SetPoint("TOPLEFT", d.where, "BOTTOMLEFT", 0, -8); d.hint:SetText("Wild pets appear near the creatures they live with: up to 3 different kinds around you at a time. One you fought comes back after about 90 seconds.")
    d.xp = CreateFrame("StatusBar", nil, d); d.xp:SetSize(196, 12); d.xp:SetPoint("TOPLEFT", d.stats, "BOTTOMLEFT", 0, -122)
    d.xp:SetStatusBarTexture(WHITE); d.xp:SetStatusBarColor(0.6, 0.3, 0.9); d.xp:SetMinMaxValues(0, 100)
    d.xp.bg = d.xp:CreateTexture(nil, "BACKGROUND"); d.xp.bg:SetAllPoints(); d.xp.bg:SetTexture(0, 0, 0, 0.6)
    d.xp.t = d.xp:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); d.xp.t:SetPoint("CENTER")

    d.ab = {}; d.abLabels = {}
    for slot = 1, 3 do
        local lab = d:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); lab:SetPoint("TOPLEFT", mf, "BOTTOMLEFT", 2, -12 - (slot - 1) * 50); lab:SetText(SLOTNAME[slot]); d.abLabels[#d.abLabels + 1] = lab
        for opt = 1, 2 do
            local b = CreateFrame("Button", nil, d); b:SetSize(208, 38)
            b:SetPoint("TOPLEFT", mf, "BOTTOMLEFT", 56 + (opt - 1) * 216, -2 - (slot - 1) * 50)   -- 2 x 208 + gap = fits the 484 wide pane
            b:SetBackdrop(BACKDROP)
            b.icon = b:CreateTexture(nil, "ARTWORK"); b.icon:SetSize(28, 28); b.icon:SetPoint("LEFT", 6, 0)
            b.name = b:CreateFontString(nil, "OVERLAY", "GameFontNormal"); b.name:SetPoint("LEFT", b.icon, "RIGHT", 8, 0)
            b.cd = b:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall"); b.cd:SetPoint("RIGHT", -28, 0)
            b.check = b:CreateTexture(nil, "OVERLAY"); b.check:SetSize(22, 22); b.check:SetPoint("RIGHT", -4, 0); b.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
            b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
            b:SetScript("OnEnter", function(self)
                local a = self.a; if not a then return end
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(a.name, 1, 0.82, 0); GameTooltip:AddLine(a.tip, 1, 1, 1, 1)
                if a.cd > 0 then GameTooltip:AddLine("Cooldown: " .. a.cd .. " rounds", 0.7, 0.7, 0.7) end
                GameTooltip:Show()
            end)
            b:SetScript("OnLeave", function() GameTooltip:Hide() end)
            b:SetScript("OnClick", function()
                local p = S.sel and S.pets[S.sel]; if not p then return end
                p.a[slot] = opt; AcoreLib.Send("pbj", "setabil2", S.sel .. "," .. slot .. "," .. opt); Refresh()
            end)
            d.ab[slot .. "," .. opt] = b
        end
    end
end

local function RefreshPets()
    local p = S.sel and PetOf(S.sel)
    ShowIf(paneP.empty, not p); ShowIf(paneP.d, p ~= nil)
    if not p then return end
    local d = paneP.d
    local zs = WotlkPetSpeciesZones and WotlkPetSpeciesZones[p.species]
    local where = zs and ("Found in: " .. table.concat(zs, ", ", 1, math.min(6, #zs)) .. (#zs > 6 and (" +" .. (#zs - 6) .. " more") or "")) or "Found in: companion pet"
    d.where:ClearAllPoints()
    if p.dex then   -- not collected: name, family and where to find it; no stats / abilities / buttons
        d.name:SetText(p.name); d.name:SetTextColor(0.65, 0.65, 0.65); d.sub:SetText("Not collected  -  " .. p.family .. (S.hidden and "  |cff999999(hidden by filter)|r" or "")); Color(d.sub, p.family)
        d.stats:SetText("Family   |cffffffff" .. p.family .. "|r"); d.where:SetPoint("TOPLEFT", d.stats, "BOTTOMLEFT", 0, -14); d.where:SetText(where)
        ShowIf(d.sum, false); ShowIf(d.feed, false); ShowIf(d.release, false); ShowIf(d.xp, false)
        for _, b in pairs(d.ab) do b:Hide() end
        for _, l in ipairs(d.abLabels) do l:Hide() end
        if modelFor ~= S.sel then modelFor = S.sel; if S.primed then model:SetCreature(p.species); model:SetRotation(0.61); d.loading:Hide() else d.loading:Show() end end
        return
    end
    ShowIf(d.sum, true); ShowIf(d.feed, true); ShowIf(d.release, p.source == 1); ShowIf(d.xp, true)
    for _, l in ipairs(d.abLabels) do l:Show() end
    d.where:SetPoint("TOPLEFT", d.xp, "BOTTOMLEFT", 0, -12); d.where:SetText(where)
    d.name:SetText(p.name); d.name:SetTextColor(unpack(QCOL[p.quality or 1])); d.sub:SetText(QNAME[p.quality or 1] .. " " .. p.family .. "  -  Level " .. p.level .. (S.hidden and "  |cff999999(hidden by filter)|r" or "")); Color(d.sub, p.family)
    d.stats:SetText("Health   |cffffffff" .. (p.cur or p.hp) .. " / " .. p.hp .. "|r\nPower   |cffffffff" .. p.dmg .. "|r\nSpeed   |cffffffff" .. p.speed .. "|r\nBreed   |cffffffff" .. BreedName(p) .. "|r")
    d.sum:SetText(S.follow == S.sel and "Dismiss" or "Summon Pet")
    local need = math.max(1, p.need or 100); d.xp:SetMinMaxValues(0, need); d.xp:SetValue(math.min(need, p.xp)); d.xp.t:SetText("Experience " .. p.xp .. " / " .. need)
    if modelFor ~= S.sel then
        modelFor = S.sel
        if S.primed then model:SetCreature(p.species); model:SetRotation(0.61); d.loading:Hide() else d.loading:Show() end
    end
    if not S.abil[S.sel] and not S.asked[S.sel] then S.asked[S.sel] = true; AcoreLib.Send("pbj", "abil2", S.sel) end
    for slot = 1, 3 do for opt = 1, 2 do
        local b = d.ab[slot .. "," .. opt]
        local a = S.abil[S.sel] and S.abil[S.sel][slot .. "," .. opt]
        b:Show(); b.a = a
        if a then
            b.icon:SetTexture("Interface\\Icons\\" .. a.icon); b.name:SetText(a.name); b.cd:SetText(p.level < (a.unlock or 1) and ("Lv " .. a.unlock) or (a.cd > 0 and ("CD " .. a.cd) or ""))
            local on = p.a[slot] == opt and p.level >= (a.unlock or 1)
            ShowIf(b.check, on)
            if on then b:SetBackdropBorderColor(1, 0.82, 0) else b:SetBackdropBorderColor(0.5, 0.5, 0.5) end
            b.icon:SetDesaturated(not on)
        else b.name:SetText("..."); b.icon:SetTexture(nil); b.cd:SetText(""); b.check:Hide() end
    end end
end

---------------------------------------------------------------- Teams tab
local function SendTeam(n) local t = S.teams[n]; AcoreLib.Send("pbj", "setteam2", n .. "," .. t[1] .. "," .. t[2] .. "," .. t[3]) end

-- put pet sp into slot i of team n (sp = 0 empties it). From another slot: the two pets swap; from the list: a pet already in this team swaps places.
function PlaceInTeam(n, i, sp, fromTeam, fromSlot)
    local t = S.teams[n]; local old = t[i]
    if fromTeam and fromSlot then S.teams[fromTeam][fromSlot] = old end
    if not fromTeam then for k = 1, 3 do if t[k] == sp and sp ~= 0 then t[k] = old end end end
    t[i] = sp
    if sp ~= 0 then for k = 1, 3 do if k ~= i and t[k] == sp then t[k] = 0 end end end   -- never the same pet twice in one team (the server refuses it)
    SendTeam(n); if fromTeam and fromTeam ~= n then SendTeam(fromTeam) end
    Refresh()
end

local function BuildTeams()
    paneT = CreateFrame("Frame", nil, frame); paneT:SetPoint("TOPLEFT", 296, -62); paneT:SetPoint("BOTTOMRIGHT", -20, 16)
    paneT.hint = paneT:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); paneT.hint:SetPoint("TOPLEFT", 4, 0); paneT.hint:SetWidth(470); paneT.hint:SetJustifyH("LEFT")
    paneT.hint:SetText("Drag a pet from the list into a slot. Drag between slots to swap or move pets, or drag a pet out of the window to remove it. Right-click a slot to empty it.")
    paneT.box = {}
    for n = 1, 3 do
        local box = CreateFrame("Frame", nil, paneT); box:SetSize(474, 108); box:SetPoint("TOPLEFT", 0, -48 - (n - 1) * 116); box:SetBackdrop(BACKDROP)
        box.title = box:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); box.title:SetPoint("TOPLEFT", 14, -10); box.title:SetText("Team " .. n)
        box.act = CreateFrame("Button", nil, box, "UIPanelButtonTemplate"); box.act:SetSize(110, 22); box.act:SetPoint("TOPRIGHT", -12, -8)
        box.act:SetScript("OnClick", function() S.active = n; AcoreLib.Send("pbj", "active2", n); Refresh() end)
        box.slot = {}
        for i = 1, 3 do
            local b = CreateFrame("Button", nil, box); b:SetSize(140, 52); b:SetPoint("TOPLEFT", 14 + (i - 1) * 150, -42); b:SetBackdrop(BACKDROP)
            b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            b.icon = b:CreateTexture(nil, "ARTWORK"); b.icon:SetSize(36, 36); b.icon:SetPoint("LEFT", 8, 0)
            b.name = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); b.name:SetPoint("TOPLEFT", b.icon, "TOPRIGHT", 6, -1); b.name:SetWidth(86); b.name:SetHeight(22); b.name:SetJustifyH("LEFT")
            b.sub = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); b.sub:SetPoint("BOTTOMLEFT", b.icon, "BOTTOMRIGHT", 6, 1)
            b.empty = b:CreateFontString(nil, "OVERLAY", "GameFontDisable"); b.empty:SetPoint("CENTER"); b.empty:SetText("Empty")
            b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
            b:SetScript("OnClick", function(_, button)   -- pets move by drag and drop only; a plain click does nothing, right-click empties the slot
                if button == "RightButton" and S.teams[n][i] ~= 0 then PlaceInTeam(n, i, 0) end
            end)
            b:SetScript("OnEnter", function() local sp = S.teams[n][i]; local p = sp ~= 0 and S.pets[sp]; if p then PetTip(b, p, sp) end end)
            b:SetScript("OnLeave", function() GameTooltip:Hide() end)
            b:RegisterForDrag("LeftButton")
            b:SetScript("OnDragStart", function() StartDrag(S.teams[n][i], n, i) end)
            b:SetScript("OnDragStop", function() EndDrag() end)
            box.slot[i] = b
        end
        paneT.box[n] = box
    end
end

local function RefreshTeams()
    for n = 1, 3 do
        local box = paneT.box[n]
        box.act:SetText(S.active == n and "ACTIVE" or "Make active")
        if S.active == n then box.act:Disable(); box.title:SetTextColor(0.4, 1, 0.4) else box.act:Enable(); box.title:SetTextColor(1, 0.82, 0) end
        for i = 1, 3 do
            local b, sp = box.slot[i], S.teams[n][i]
            local p = sp ~= 0 and S.pets[sp]
            ShowIf(b.icon, p ~= false and p ~= nil and p ~= 0); ShowIf(b.name, p and true or false); ShowIf(b.sub, p and true or false); ShowIf(b.empty, not p)
            if p then
                b.icon:SetTexture(Icon(p)); b.icon:Show(); b.name:SetText(p.name); b.name:SetTextColor(unpack(QCOL[p.quality or 1])); b.sub:SetText("Lv " .. p.level .. " " .. BreedName(p)); Color(b.sub, p.family)
                b:SetBackdropBorderColor(0.9, 0.75, 0.2)
            else b:SetBackdropBorderColor(0.4, 0.4, 0.4) end
        end
    end
end

---------------------------------------------------------------- shell
function Bind(offset)
    local list = S.list or {}
    offset = offset or (scroll and scroll:GetVerticalScroll()) or 0
    local first = math.max(1, math.floor(offset / ROW_H) + 1)
    for i = 1, ROW_FRAMES do
        local idx, sp = first + i - 1, list[first + i - 1]
        if sp then
            local r, p = Row(i), PetOf(sp)
            r:ClearAllPoints(); r:SetPoint("TOPLEFT", 0, -(idx - 1) * ROW_H)
            r.sp = sp; r:Show(); r.icon:SetTexture(Icon(p)); r.icon:SetDesaturated(p.dex and true or false);             r.name:SetText(p.name)
            if p.dex then r.name:SetTextColor(0.6, 0.6, 0.6); r.lvl:SetText("") else r.name:SetTextColor(unpack(QCOL[p.quality or 1])); r.lvl:SetText(p.level) end
            r.sub:SetText(p.family .. (p.dex and "  |cff999999not collected|r" or "  " .. BreedName(p)) .. (S.follow == sp and "  |cff66ff66(following)|r" or "")); Color(r.sub, p.family); ShowIf(r.sel, S.sel == sp)
        elseif rows[i] then rows[i]:Hide() end
    end
end

function Refresh()
    if not frame or not frame:IsShown() then return end
    if S.drag and not S.pets[S.drag.sp] then CancelDrag() end
    local list = Sorted()
    S.shown = {}; for _, sp in ipairs(list) do S.shown[sp] = true end
    S.list = list
    rowsHolder:SetHeight(math.max(10, #list * ROW_H))
    Bind()
    S.hidden = S.sel ~= nil and not S.shown[S.sel]
    local total = 0; for _ in pairs(S.pets) do total = total + 1 end
    if S.view ~= "collected" and S.view ~= "team" and WotlkPetDex then for sp in pairs(WotlkPetDex) do if not S.owned[sp] then total = total + 1 end end end
    frame.count:SetText(#list == total and (total .. " pets") or (#list .. " of " .. total .. " pets"))
    S.emptyTxt:SetText(#list > 0 and "" or (total == 0 and "You have no battle pets yet. Capture wild pets in battle." or "No pet matches the filters. Use Clear filters."))
    for _, dd in ipairs(filterBtns) do dd.Text() end
    ShowIf(paneP, S.tab == 1); ShowIf(paneT, S.tab == 2)
    for i, t in ipairs(tabs) do if i == S.tab then t:LockHighlight() else t:UnlockHighlight() end end
    if S.tab == 1 then RefreshPets() else RefreshTeams() end
end

local function Build()
    frame = CreateFrame("Frame", "WotlkPetsFrame", UIParent)
    frame:SetSize(800, 560); frame:SetPoint("CENTER"); frame:SetFrameStrata("DIALOG"); frame:SetBackdrop(BACKDROP)
    frame:SetMovable(true); frame:EnableMouse(true); frame:SetScript("OnMouseDown", function() if search then search:ClearFocus() end end); frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving); frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    AcoreLib.Solid(frame, 4, 0.07, 0.06, 0.05)
    frame:Hide(); tinsert(UISpecialFrames, "WotlkPetsFrame"); frame:SetScript("OnHide", CancelDrag)
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); title:SetPoint("TOPLEFT", 22, -18); title:SetText("Pet Journal")
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton"); close:SetPoint("TOPRIGHT", -4, -4)
    frame.count = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); frame.count:SetTextColor(0.75, 0.75, 0.75); frame.count:SetPoint("BOTTOMLEFT", 26, 20)
    tabs = {}
    for i, name in ipairs({ "Pets", "Teams" }) do
        local t = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate"); t:SetSize(100, 24); t:SetPoint("TOPRIGHT", -40 - (2 - i) * 106, -16); t:SetText(name)
        t:SetScript("OnClick", function() S.tab = i; Refresh() end); tabs[i] = t
    end
    BuildList(); BuildPets(); BuildTeams()
end

-- The server answers "list" with ONE message per pet (1,500 pets = 1,500 messages): redraw once at "done", not once per message (that froze the client for seconds).
local function Soon() if not (S.syncing and GetTime() - (S.syncAt or 0) < 15) then Refresh() end end
AcoreLib.On("pbj", "begin2", function()
    S.pets, S.abil, S.asked = {}, {}, {}
    S.syncing = true; S.syncAt = GetTime()
end)
AcoreLib.On("pbj", "pet2", function(p)
    local id, breed, speed, source, fields = p:match("^(%d+),(%d+),(%d+),(%d+),(.+)$")
    if not id then return end
    p = fields
    local sp, lv, xp, a1, a2, a3, family, icon, hp, dmg, q, cur, need, name = p:match("^(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%a+),([^,]+),(%d+),(%d+),(%d+),(%d+),(%d+),(.+)$")
    if not sp then return end
    id = Num(id)
    local old = S.pets[id]
    if old and old.level ~= Num(lv) then S.abil[id], S.asked[id] = nil, nil end
    S.pets[id] = { species = Num(sp), breed = Num(breed), speed = Num(speed), source = Num(source), level = Num(lv), xp = Num(xp), a = { Num(a1), Num(a2), Num(a3) }, family = family, icon = icon, hp = Num(hp), dmg = Num(dmg), quality = Num(q), cur = Num(cur), need = Num(need), name = name }
    Soon()
end)
AcoreLib.On("pbj", "team2", function(p) local n, a, b, c = p:match("^(%d),(%d+),(%d+),(%d+)$"); if n then S.teams[Num(n)] = { Num(a), Num(b), Num(c) }; Soon() end end)
AcoreLib.On("pbj", "follow2", function(p) S.follow = Num(p); Soon() end)
AcoreLib.On("pbj", "active2", function(p) S.active = Num(p); Soon() end)
AcoreLib.On("pbj", "done2", function()
    S.syncing = false
    if S.sel and not PetOf(S.sel) then S.sel = nil end
    Refresh()
end)
AcoreLib.On("pbj", "abl2", function(p)
    local sp, slot, opt, icon, name, tip, cd, unlock = p:match("^(%d+),(%d),(%d)|([^#]*)#([^#]*)#([^#]*)#(%d+)#(%d+)$")
    if not sp then return end
    sp = Num(sp); S.abil[sp] = S.abil[sp] or {}
    S.abil[sp][slot .. "," .. opt] = { icon = icon, name = name, tip = tip, cd = Num(cd), unlock = Num(unlock) }
    Refresh()
end)
AcoreLib.On("pbj", "removed2", function(payload)
    local id = Num(payload)
    S.pets[id], S.abil[id], S.asked[id] = nil, nil, nil
    if S.sel == id then S.sel = nil end
    if S.follow == id then S.follow = 0 end
    Soon()
end)
AcoreLib.On("pbj", "releaseerror2", function(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[Pets]|r " .. message)
end)
AcoreLib.On("pbj", "primed", function() S.primed = true; modelFor = nil; Refresh() end)

WotlkPets = { S = S, PetPasses = PetPasses, StartDrag = StartDrag, EndDrag = EndDrag, CancelDrag = CancelDrag, PlaceInTeam = function(...) return PlaceInTeam(...) end }   -- the one global (tests)

SLASH_PETS1 = "/pets"; SLASH_PETS2 = "/petjournal"
SlashCmdList["PETS"] = function()
    if not frame then Build() end
    if frame:IsShown() then frame:Hide() return end
    frame:Show(); Refresh()
    S.syncing = true; S.syncAt = GetTime()
    AcoreLib.Send("pbj", "list2", "")
    if not S.primed then AcoreLib.Send("pbj", "prime", "") end
end
