#include "AscensionClientLua.h"
#include "AscensionClientSpellPatches.h"
#include "Creature.h"
#include "PassiveAI.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "ScriptedGossip.h"
#include <array>

namespace
{
    constexpr uint32 PlatterItem = 9707200;
    constexpr std::array<uint32, 11> ClientSpells = {
        9978100, 9978101, 9978102, 9978103, 9978104, 9978105, 9978106, 9978107, 9978108, 9978109, 9978110};
    constexpr uint32 PlatterGossipText = 9990600;
    constexpr uint32 DessertsSpell = 9978101;
    constexpr uint32 SnowInAConeOption = 4;
    constexpr uint32 WindowRequirementType = 27;
    constexpr uint32 WindowRequirementRow = 16267;
    constexpr char WindowToken[] = "COA_PORTABLE_PARTY_PLATTER_WINDOW";

    struct Treat
    {
        char const* Name;
        uint32 Spell;
    };

    constexpr std::array<Treat, 6> Treats = {{
        {"Slice of Cake", 9978102},
        {"Blubbery Muffin", 9978103},
        {"Rocks on the Rocks", 9978104},
        {"Sugarfree Firewater Sorbet", 9978105},
        {"Snow in a Cone", 9978107},
        {"Party Peripherals", 9978106},
    }};

    constexpr std::array<uint32, 4> Cones = {9978107, 9978108, 9978109, 9978110};

    constexpr char PlatterWindowLua[] = R"lua(
if not CoAPartyPlatterFrame then
    local PLATTER_ENTRY = 11000400

    local frame = CreateFrame("Frame", "CoAPartyPlatterFrame", UIParent)
    frame:SetSize(430, 260)
    frame:SetPoint("CENTER", 0, 40)
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetBackdrop({
        bgFile = "Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal",
        edgeFile = "Interface\\AchievementFrame\\UI-Achievement-WoodBorder",
        tile = false, edgeSize = 64,
        insets = { left = 18, right = 18, top = 18, bottom = 18 },
    })
    frame:Hide()
    tinsert(UISpecialFrames, "CoAPartyPlatterFrame")

    local header = frame:CreateTexture(nil, "ARTWORK")
    header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    header:SetSize(380, 64)
    header:SetPoint("TOP", 0, 14)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", header, "TOP", 0, -14)

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -8, -8)

    local text = frame:CreateFontString(nil, "OVERLAY", "QuestFont")
    text:SetPoint("TOPLEFT", frame, "TOPLEFT", 36, -52)
    text:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -36, -52)
    text:SetHeight(48)
    text:SetJustifyV("TOP")
    text:SetJustifyH("LEFT")
    text:SetTextColor(0.18, 0.12, 0.06)

    local buttons = {}
    for index = 1, 6 do
        local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        button:SetSize(170, 24)
        local column, row = (index - 1) % 2, math.floor((index - 1) / 2)
        button:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 36 + column * 190, 108 - row * 32)
        button:SetScript("OnClick", function(self)
            SelectGossipOption(self.option)
        end)
        buttons[index] = button
    end

    local function SetGossipFrameHidden(hidden)
        GossipFrame:SetAlpha(hidden and 0 or 1)
        GossipFrame:EnableMouse(not hidden)
        for index = 1, NUMGOSSIPBUTTONS do
            local button = _G["GossipTitleButton" .. index]
            if button then
                button:EnableMouse(not hidden)
            end
        end
    end

    local function NpcEntry()
        local guid = UnitGUID("npc")
        if not guid or strlen(guid) < 18 then
            return nil
        end
        return tonumber(strsub(guid, 7, 12), 16)
    end

    local function Show()
        title:SetText(UnitName("npc") or "Portable Party Platter")
        text:SetText(GetGossipText())
        local options = { GetGossipOptions() }
        for index, button in ipairs(buttons) do
            local label = options[index * 2 - 1]
            button.option = index
            button:SetText(label or "")
            if label then
                button:Show()
            else
                button:Hide()
            end
        end
        SetGossipFrameHidden(true)
        frame:Show()
    end

    frame:SetScript("OnHide", function()
        SetGossipFrameHidden(false)
        if GossipFrame:IsShown() then
            CloseGossip()
        end
    end)

    local events = CreateFrame("Frame")
    events:RegisterEvent("GOSSIP_SHOW")
    events:RegisterEvent("GOSSIP_CLOSED")
    events:SetScript("OnEvent", function(_, event)
        if event == "GOSSIP_SHOW" and NpcEntry() == PLATTER_ENTRY then
            Show()
        elseif frame:IsShown() then
            frame:Hide()
        end
    end)
end
)lua";

    uint32 TreatSpell(uint32 option)
    {
        if (option == SnowInAConeOption)
            return Cones[urand(0, Cones.size() - 1)];

        return Treats[option].Spell;
    }
}

class npc_coa_portable_party_platter_ai : public PassiveAI
{
public:
    explicit npc_coa_portable_party_platter_ai(Creature* creature) : PassiveAI(creature) { }

    void IsSummonedBy(WorldObject*) override
    {
        ServeDesserts();
    }

    void Reset() override
    {
        ServeDesserts();
    }

private:
    void ServeDesserts()
    {
        if (!me->HasAura(DessertsSpell))
            me->CastSpell(me, DessertsSpell, true);
    }
};

class npc_coa_portable_party_platter : public CreatureScript
{
public:
    npc_coa_portable_party_platter() : CreatureScript("npc_coa_portable_party_platter") { }

    CreatureAI* GetAI(Creature* creature) const override
    {
        return new npc_coa_portable_party_platter_ai(creature);
    }

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        ClearGossipMenuFor(player);
        for (uint32 option = 0; option < Treats.size(); ++option)
            AddGossipItemFor(player, GOSSIP_ICON_CHAT, Treats[option].Name, GOSSIP_SENDER_MAIN, option);

        RunAscensionClientLua(player, {WindowRequirementType, WindowRequirementRow, WindowToken, PlatterWindowLua});
        SendGossipMenuFor(player, PlatterGossipText, creature->GetGUID());
        return true;
    }

    bool OnGossipSelect(Player* player, Creature*, uint32 sender, uint32 action) override
    {
        CloseGossipMenuFor(player);
        if (sender != GOSSIP_SENDER_MAIN || action >= Treats.size())
            return true;

        player->CastSpell(player, TreatSpell(action), true);
        return true;
    }
};

void AddSC_CoAPortablePartyPlatter()
{
    for (uint32 spell : ClientSpells)
        Ascension::ClientSpellPatches::Instance().Register(spell);
    Ascension::ClientItemPatches::Instance().Register(PlatterItem);
    new npc_coa_portable_party_platter();
}
