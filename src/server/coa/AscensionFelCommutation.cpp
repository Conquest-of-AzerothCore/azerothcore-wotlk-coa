#include "AscensionFelCommutation.h"
#include "AscensionClientLua.h"
#include "AscensionCompatOpcodes.h"
#include "AscensionFelCommutationPolicy.h"
#include "Chat.h"
#include "CommandScript.h"
#include "AscensionHighRiskPolicy.h"
#include "Config.h"
#include "Creature.h"
#include "GameObject.h"
#include "Item.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "Opcodes.h"
#include "Player.h"
#include "PlayerScript.h"
#include "ScriptMgr.h"
#include "StringConvert.h"
#include "StringFormat.h"
#include "WorldPacket.h"
#include "WorldScript.h"
#include "WorldSession.h"
#include <algorithm>
#include <atomic>
#include <mutex>
#include <string>
#include <unordered_set>

using namespace Acore::ChatCommands;

namespace FelCommutation
{
namespace
{
std::atomic<bool> enabled{false};
std::atomic<bool> toggleAnywhere{false};
std::atomic<bool> clickToggle{false};
std::atomic<float> altarRange{20.0f};
std::atomic<double> feeMultiplier{DefaultFeeMultiplier};
std::atomic<uint32> maxSlots{DefaultMaxSlots};

std::mutex windowMutex;
std::unordered_set<ObjectGuid::LowType> windowShown;
std::unordered_set<ObjectGuid::LowType> windowCodeSent;

void ForgetWindow(Player const* player)
{
    std::lock_guard<std::mutex> lock(windowMutex);
    windowShown.erase(player->GetGUID().GetCounter());
    windowCodeSent.erase(player->GetGUID().GetCounter());
}

constexpr char AddonPrefix[] = "FELCOMM";
constexpr uint32 InsuredSlotsIndex = 1;
constexpr std::size_t AddonChunkLength = 200;

uint32 InsuredSlots(Player const* player)
{
    PlayerSettingVector const* settings = player->FindPlayerSettings(Setting);
    return settings && settings->size() > InsuredSlotsIndex ? (*settings)[InsuredSlotsIndex].value : 0;
}

bool SlotInsured(uint32 mask, unsigned key)
{
    return Insurable(key) && (mask & (1u << key)) != 0;
}

void SendAddon(Player* player, std::string const& message)
{
    WorldPacket packet;
    ChatHandler::BuildChatPacket(packet, CHAT_MSG_WHISPER, LANG_ADDON, player, player,
        std::string(AddonPrefix) + "\t" + message);
    player->SendDirectMessage(&packet);
}

uint64 Fee(Item const* item)
{
    return ItemFee(item->GetTemplate()->ItemLevel, feeMultiplier);
}

void SendSlots(Player* player)
{
    uint32 const mask = InsuredSlots(player);
    std::string flags;
    for (unsigned key = 1; key <= SlotCount; ++key)
        flags += SlotInsured(mask, key) ? '1' : '0';
    SendAddon(player, "SLOTS " + flags + " " + std::to_string(maxSlots.load()));

    uint64 total = 0;
    std::vector<std::string> chunks(1);
    for (unsigned key = 1; key <= SlotCount; ++key)
    {
        Item const* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, uint8(key - 1));
        if (!item || !Insurable(key))
            continue;

        uint64 const fee = Fee(item);
        if (SlotInsured(mask, key))
            total += fee;
        std::string const entry = std::to_string(item->GetEntry()) + ":" + std::to_string(fee) + ",";
        if (chunks.back().size() + entry.size() > AddonChunkLength)
            chunks.emplace_back();
        chunks.back() += entry;
    }
    SendAddon(player, "COST " + std::to_string(total));
    for (std::string const& chunk : chunks)
        if (!chunk.empty())
            SendAddon(player, "ITEMS " + chunk);
}

void HandleWindowMessage(Player* player, std::string const& body)
{
    std::size_t const space = body.find(' ');
    std::string const action = body.substr(0, space);
    unsigned key = 0;
    if (space != std::string::npos)
        key = Acore::StringTo<unsigned>(body.substr(space + 1)).value_or(0);

    uint32 const mask = InsuredSlots(player);
    if (action == "INSURE" && Insurable(key))
    {
        if (!player->GetItemByPos(INVENTORY_SLOT_BAG_0, uint8(key - 1)))
        {
            SendAddon(player, "ERROR Equip an item in this slot before commuting it.");
            return;
        }

        unsigned insured = 0;
        for (unsigned slot = 1; slot <= SlotCount; ++slot)
            insured += SlotInsured(mask, slot) ? 1 : 0;
        if (maxSlots && !SlotInsured(mask, key) && insured >= maxSlots)
        {
            SendAddon(player, Acore::StringFormat("ERROR You can only commute {} {}.", maxSlots.load(),
                maxSlots == 1 ? "slot" : "slots"));
            return;
        }

        player->UpdatePlayerSetting(Setting, InsuredSlotsIndex, mask | (1u << key));
    }
    else if (action == "UNINSURE" && Insurable(key))
        player->UpdatePlayerSetting(Setting, InsuredSlotsIndex, mask & ~(1u << key));
    else if (action != "LIST")
        return;

    SendSlots(player);
}

constexpr Milliseconds LoginCodeDelay = 5s;
constexpr uint32 WindowBootstrapRow = 23;
constexpr uint32 WindowRequirementRow = 16263;
constexpr char WindowBootstrapToken[] = "FEL_COMMUTATION_WINDOW";

constexpr char WindowLua[] = R"lua(
local WINDOW_EVENT = "ASCENSION_FEL_COMMUTATION_WINDOW_VISIBILITY_CHANGED"
if FelCommutationFrame then
  FelCommutationFrame:UnregisterAllEvents()
  FelCommutationFrame:Hide()
end
local w = FelCommutationWindow
if not w then
  local PREFIX = "FELCOMM"
  local ART = "Interface\\AddOns\\AwAddons\\Textures\\SafeSlots\\"
  local EMPTY = "Interface\\PaperDoll\\UI-Backpack-EmptySlot"
  local NO_DROP_TEXT = "This item doesn't \ndrop on death. You can remove\nFel Commutation from it"
  local noDrop = {[4] = true, [19] = true}
  local slots = {
    [1] = {"Head", 1}, [2] = {"Neck", 2}, [3] = {"Shoulders", 3}, [4] = {"Shirt", 6}, [5] = {"Chest", 5},
    [6] = {"Waist", 10}, [7] = {"Legs", 11}, [8] = {"Feet", 12}, [9] = {"Wrist", 8}, [10] = {"Hands", 9},
    [11] = {"Finger", 13}, [12] = {"Finger", 14}, [13] = {"Trinket", 15}, [14] = {"Trinket", 16},
    [15] = {"Back", 4}, [16] = {"Main Hand", 17}, [17] = {"Off Hand", 18}, [18] = {"Ranged", 19},
    [19] = {"Tabard", 7},
  }
  local positions = {
    {-100, 144}, {-121, 106}, {-134, 64}, {-140, 22}, {-140, -22}, {-134, -64}, {-121, -106}, {-100, -144},
    {103, 144}, {124, 106}, {137, 64}, {143, 22}, {143, -22}, {137, -64}, {124, -106}, {103, -144},
    {-43, -161}, {3, -161}, {46, -161},
  }
  local insured, costs = {}, {}
  local total, count, cap = 0, 0, 0

  pcall(function()
    C_HighRisk.GetInsuranceTotalCost = function() return total end
    C_HighRisk.GetInsuranceCostPerSlot = function() return total end
  end)

  local function updateSheet()
    if count == 0 then
      FEL_COMMUTATION_POTENTIAL_LOSS = "No slots insured in High-Risk"
    elseif cap > 0 then
      FEL_COMMUTATION_POTENTIAL_LOSS = format("%d of %d slots insured in High-Risk", count, cap)
    else
      FEL_COMMUTATION_POTENTIAL_LOSS = format("%d %s insured in High-Risk", count, count == 1 and "slot" or "slots")
    end
    local panel = AscensionPaperDollPanel
    if panel and panel:IsShown() and panel.UpdateFelCommutation then
      panel:UpdateFelCommutation()
    end
  end

  local function send(message)
    SendAddonMessage(PREFIX, message, "WHISPER", UnitName("player"))
  end

  local function money(copper)
    local g, s, c = GetGoldForMoney(copper)
    return "|cffFFFFFF" .. g .. " |TInterface\\MONEYFRAME\\UI-GoldIcon.blp:11:11:0:-1|t " .. s ..
      "|TInterface\\MONEYFRAME\\UI-SilverIcon.blp:11:11:0:-1|t " .. c ..
      "|TInterface\\MONEYFRAME\\UI-CopperIcon.blp:11:11:0:-1|t|r"
  end

  w = CreateFrame("Frame", "FelCommutationWindow", UIParent)
  w:SetSize(512, 512)
  w:SetPoint("CENTER")
  w:SetFrameStrata("HIGH")
  w:SetClampedToScreen(true)
  w:SetMovable(true)
  w:EnableMouse(true)
  w:RegisterForDrag("LeftButton")
  w:SetScript("OnDragStart", w.StartMoving)
  w:SetScript("OnDragStop", w.StopMovingOrSizing)
  w:SetBackdrop({bgFile = ART .. "SafeSlots"})

  local close = CreateFrame("Button", nil, w, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -82, -45)
  local title = w:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOP", 0, -55)
  title:SetShadowOffset(1, -1)
  title:SetText("Fel Commutation")
  local maxText = w:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  maxText:SetPoint("TOP", 0, -80)
  maxText:SetShadowOffset(1, -1)
  maxText:Hide()

  local model = CreateFrame("PlayerModel", nil, w)
  model:SetSize(192, 256)
  model:SetPoint("CENTER", 0, -22)
  model:SetUnit("player")
  model:SetCamera(1)

  local flash = w:CreateTexture(nil, "ARTWORK")
  flash:SetAllPoints()
  flash:SetTexture(ART .. "SafeSlotsHighlight")
  flash:SetBlendMode("ADD")
  flash:Hide()

  local confirm = CreateFrame("Frame", nil, w)
  confirm:SetSize(512, 512)
  confirm:SetPoint("CENTER")
  confirm:SetFrameStrata("DIALOG")
  confirm:SetBackdrop({bgFile = ART .. "SafeSlots_Window"})
  confirm:Hide()
  local confirmFlash = confirm:CreateTexture(nil, "OVERLAY")
  confirmFlash:SetAllPoints()
  confirmFlash:SetTexture(ART .. "SafeSlots_confirmH")
  confirmFlash:SetBlendMode("ADD")
  confirmFlash:Hide()
  local icon = CreateFrame("Button", nil, confirm)
  icon:SetSize(34, 34)
  icon:SetPoint("CENTER", -80, -23)
  icon:SetNormalTexture(EMPTY)
  icon:SetHighlightTexture("Interface\\BUTTONS\\ButtonHilight-Square")
  local costText = confirm:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  costText:SetPoint("CENTER", 0, -15)
  costText:SetShadowOffset(1, -1)
  local insure = CreateFrame("Button", nil, confirm, "UIPanelButtonTemplate")
  insure:SetSize(141, 21)
  insure:SetPoint("CENTER", 0, -54)
  insure:SetText("Commute slot")
  local remove = CreateFrame("Button", nil, confirm, "UIPanelButtonTemplate")
  remove:SetSize(141, 21)
  remove:SetPoint("CENTER", 0, -54)
  remove:SetText("Remove Commutation")

  local buttons = {}
  for i = 1, 19 do
    local size = i > 16 and 60 or 54
    local b = CreateFrame("Button", nil, w)
    b:SetSize(size, size)
    b:SetPoint("CENTER", positions[i][1], positions[i][2])
    b:SetNormalTexture(ART .. "SlotBorder")
    b:SetHighlightTexture(ART .. "SlotBorder_H")
    b.back = b:CreateTexture(nil, "BACKGROUND")
    b.back:SetSize(33, 33)
    b.back:SetPoint("CENTER")
    b.back:Hide()
    b.glow = b:CreateTexture(nil, "OVERLAY")
    b.glow:SetTexture(ART .. "SlotBorder_active")
    b.glow:SetSize(size, size)
    b.glow:SetPoint("CENTER")
    b.glow:SetBlendMode("ADD")
    b.glow:Hide()
    buttons[i] = b
  end
  for key, info in pairs(slots) do
    buttons[info[2]].slot = key
  end

  local function refresh()
    for key, info in pairs(slots) do
      local b = buttons[info[2]]
      local texture = GetInventoryItemTexture("player", key)
      if insured[key] then
        b.glow:Show()
        if texture then
          SetPortraitToTexture(b.back, texture)
          b.back:Show()
        else
          b.back:Hide()
        end
      else
        b.glow:Hide()
        b.back:Hide()
      end
    end
  end

  local function pulse(texture)
    texture:Show()
    UIFrameFadeOut(texture, 0.6, 1, 0)
  end

  local pending = false
  local function commit(action)
    if not icon.slot then return end
    pending = true
    send(action .. " " .. icon.slot)
  end
  insure:SetScript("OnClick", function() commit("INSURE") end)
  remove:SetScript("OnClick", function() commit("UNINSURE") end)

  for _, b in ipairs(buttons) do
    b:SetScript("OnClick", function(self)
      PlaySound("igMainMenuOptionCheckBoxOn")
      if confirm:IsShown() and icon.slot == self.slot then
        confirm:Hide()
      else
        icon.slot = self.slot
        confirm:Show()
      end
    end)
    b:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText("|cffFFFFFF" .. slots[self.slot][1])
      if not insured[self.slot] then
        GameTooltip:AddLine("Click on this slot to insure it")
      end
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  end

  icon:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if GetInventoryItemLink("player", self.slot) then
      GameTooltip:SetInventoryItem("player", self.slot)
    elseif insured[self.slot] then
      GameTooltip:AddLine("Slot is empty")
    end
    GameTooltip:Show()
  end)
  icon:SetScript("OnLeave", function() GameTooltip:Hide() end)

  confirm:SetScript("OnUpdate", function()
    local key = icon.slot
    if not key then return end
    local texture = GetInventoryItemTexture("player", key)
    if insured[key] then
      remove:Show()
      insure:Hide()
      icon:SetNormalTexture(texture or EMPTY)
      local id = GetInventoryItemID("player", key)
      if not texture then
        costText:SetText(noDrop[key] and NO_DROP_TEXT or "Equip an Item.\nThis saves it\nwhen you die.")
      elseif id and costs[id] and not noDrop[key] then
        costText:SetText("Saving this item\nwill cost you\n" .. money(costs[id]) .. "\neach death")
      else
        costText:SetText(NO_DROP_TEXT)
      end
    else
      remove:Hide()
      insure:Show()
      if noDrop[key] then
        insure:Disable()
        icon:SetNormalTexture("Interface\\icons\\World_Marker_Cross")
        costText:SetText("This item doesn't \ndrop on death.")
      else
        insure:Enable()
        local id = GetInventoryItemID("player", key)
        if texture and id and costs[id] then
          icon:SetNormalTexture(texture)
          costText:SetText("Saving this item\nwill cost you\n" .. money(costs[id]) .. "\neach death")
        else
          icon:SetNormalTexture("Interface\\icons\\inv_custom_demonstears")
          costText:SetText("Commutation Cost\neach Death: |cffFFFFFFGold|r")
        end
      end
    end
  end)

  GameTooltip:HookScript("OnTooltipSetItem", function(tip)
    local _, link = tip:GetItem()
    if not link then return end
    for key = 1, 19 do
      if insured[key] and GetInventoryItemLink("player", key) == link then
        local id = GetInventoryItemID("player", key)
        if id and costs[id] then
          tip:AddDoubleLine("|cffFFFFFFPotential drop cost:\n" .. money(costs[id]), "|cffFFFFFFEach death|r")
          tip:Show()
        end
        return
      end
    end
  end)

  w:SetScript("OnShow", function()
    model:SetUnit("player")
    model:SetCamera(1)
    send("LIST")
  end)
  w:SetScript("OnHide", function() confirm:Hide() end)
  w:RegisterEvent("CHAT_MSG_ADDON")
  w:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
  w:SetScript("OnEvent", function(self, event, a1, a2, a3, a4)
    if event == WINDOW_EVENT then
      if a1 then self:Show() else self:Hide() end
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
      refresh()
      send("LIST")
    elseif event == "CHAT_MSG_ADDON" and a1 == PREFIX and a4 == UnitName("player") then
      local kind, rest = a2:match("^(%S+)%s*(.*)$")
      if kind == "SLOTS" then
        count = 0
        for key = 1, 19 do
          insured[key] = rest:sub(key, key) == "1"
          if insured[key] then count = count + 1 end
        end
        cap = tonumber(rest:match("%s(%d+)$")) or 0
        if pending then
          pending = false
          PlaySound("Glyph_MajorCreate")
          pulse(flash)
          confirm:Hide()
        end
        refresh()
      elseif kind == "ERROR" then
        pending = false
        UIErrorsFrame:AddMessage(rest, 1.0, 0.1, 0.1, 1.0)
      elseif kind == "COST" then
        wipe(costs)
        total = tonumber(rest) or 0
        updateSheet()
        if total > 0 then
          maxText:SetText("Maximum gold lost on death\n" .. money(total) .. " each death")
          maxText:Show()
        else
          maxText:Hide()
        end
      elseif kind == "ITEMS" then
        for id, copper in rest:gmatch("(%d+):(%d+)") do
          costs[tonumber(id)] = tonumber(copper)
        end
      end
    end
  end)
  tinsert(UISpecialFrames, "FelCommutationWindow")
  w:Hide()
  send("LIST")
end
local function hookWindowEvent()
  RegisterInterfaceEvent(WINDOW_EVENT)
  w:RegisterEvent(WINDOW_EVENT)
  return w:IsEventRegistered(WINDOW_EVENT)
end
if not hookWindowEvent() and not w.retry then
  w.retry = CreateFrame("Frame")
  w.retry:RegisterEvent("PLAYER_ENTERING_WORLD")
  w.retry:SetScript("OnEvent", function(self)
    if hookWindowEvent() then
      self:UnregisterAllEvents()
    end
  end)
end
if showToggle and not w.Toggle then
  local b = CreateFrame("Button", nil, w, "UIPanelButtonTemplate")
  b:SetSize(220, 24)
  b:SetPoint("CENTER", 0, -212)
  local function refresh()
    b:SetText(C_HighRisk.IsFelCommutationActive() and FEL_COMMUTATION_DISABLE or FEL_COMMUTATION_ENABLE)
  end
  b:SetScript("OnClick", function()
    C_HighRisk.ToggleFelCommutation(not C_HighRisk.IsFelCommutationActive())
  end)
  b:SetScript("OnShow", refresh)
  b:SetScript("OnEvent", refresh)
  b:RegisterEvent("TOGGLE_FEL_COMMUTATION_STATUS_RESULT")
  refresh()
  w.Toggle = b
end
if w.Toggle then
  if showToggle then w.Toggle:Show() else w.Toggle:Hide() end
end
)lua";

std::string WindowBootstrapLua()
{
    return std::string("local showToggle = ") + (clickToggle ? "true" : "false") + WindowLua;
}

void RunWindowLua(Player* player)
{
    RunAscensionClientLua(player, {WindowBootstrapRow, WindowRequirementRow, WindowBootstrapToken, WindowBootstrapLua()});
}

void EnsureWindowCode(Player* player)
{
    bool sendCode = false;
    {
        std::lock_guard<std::mutex> lock(windowMutex);
        sendCode = windowCodeSent.insert(player->GetGUID().GetCounter()).second;
    }
    if (sendCode)
        RunWindowLua(player);
}

bool OwnGreedyDemon(Player const* player, Creature const* creature)
{
    return creature && creature->GetEntry() == GreedyDemonEntry &&
        (creature->GetOwnerGUID() == player->GetGUID() || creature->GetCreatorGUID() == player->GetGUID());
}

bool NearAltar(Player* player)
{
    if (player->FindNearestGameObject(PortalEntry, altarRange))
        return true;
    Creature* demon = ObjectAccessor::GetCreature(*player, player->GetCritterGUID());
    return OwnGreedyDemon(player, demon) && demon->IsWithinDistInMap(player, altarRange);
}

void ToggleWindow(Player* player)
{
    bool visible = false;
    {
        std::lock_guard<std::mutex> lock(windowMutex);
        ObjectGuid::LowType const guid = player->GetGUID().GetCounter();
        visible = windowShown.insert(guid).second;
        if (!visible)
            windowShown.erase(guid);
    }

    if (visible)
        EnsureWindowCode(player);

    WorldPacket data(WindowOpcode, 2 * sizeof(uint8));
    data << uint8(WindowId) << uint8(visible ? 1 : 0);
    player->SendDirectMessage(&data);
}

void SendResult(Player* player, ToggleResult result)
{
    std::string const name = ToggleResultName(result);
    WorldPacket data(ResultOpcode, name.size() + 1);
    data << name;
    player->SendDirectMessage(&data);
}

void SendState(Player* player)
{
    WorldPacket data(UpdateOpcode, sizeof(uint8));
    data << uint8(enabled && Active(player) ? 1 : 0);
    player->SendDirectMessage(&data);
}

void ApplyToggle(Player* player, bool want, bool nearAltar)
{
    if (!enabled)
    {
        SendResult(player, ToggleResult::Unknown);
        return;
    }

    ToggleResult const result = DecideToggle(Active(player), want, nearAltar, toggleAnywhere);
    if (result == ToggleResult::Ok)
    {
        player->UpdatePlayerSetting(Setting, 0, want ? 1 : 0);
        SendState(player);
    }

    SendResult(player, result);
    if (result == ToggleResult::Ok && want)
        player->KilledMonsterCredit(CreditEntry);
}

bool HandleToggle(WorldSession* session, WorldPacket const& received)
{
    Player* player = session ? session->GetPlayer() : nullptr;
    if (!player || !player->IsInWorld())
        return true;

    WorldPacket packet(received);
    packet.rpos(0);
    uint8 want = 0;
    try
    {
        packet >> want;
    }
    catch (ByteBufferException const&)
    {
        return true;
    }

    ApplyToggle(player, want != 0, NearAltar(player));
    return true;
}

std::string ItemLink(Item const* item)
{
    ItemTemplate const* proto = item->GetTemplate();
    return Acore::StringFormat("|c{:08x}|Hitem:{}:0:0:0:0:0:0:0:{}|h[{}]|h|r", ItemQualityColors[proto->Quality],
        proto->ItemId, item->GetOwner() ? item->GetOwner()->GetLevel() : 0, proto->Name1);
}

class FelCommutationWorld final : public WorldScript
{
public:
    FelCommutationWorld() : WorldScript("coa_fel_commutation_world", {WORLDHOOK_ON_AFTER_CONFIG_LOAD}) { }

    void OnAfterConfigLoad(bool) override
    {
        enabled = sConfigMgr->GetOption<bool>("HighRisk.FelCommutation.Enable", false);
        toggleAnywhere = sConfigMgr->GetOption<bool>("HighRisk.FelCommutation.ToggleAnywhere", false);
        clickToggle = sConfigMgr->GetOption<bool>("HighRisk.FelCommutation.ClickToggle", false);
        altarRange = std::max(1.0f, sConfigMgr->GetOption<float>("HighRisk.FelCommutation.AltarRange", 20.0f));
        feeMultiplier = std::max(0.0, double(sConfigMgr->GetOption<float>("HighRisk.FelCommutation.FeeMultiplier",
            float(DefaultFeeMultiplier))));
        maxSlots = sConfigMgr->GetOption<uint32>("HighRisk.FelCommutation.MaxSlots", DefaultMaxSlots);
    }
};

class FelCommutationPackets final : public ServerScript
{
public:
    FelCommutationPackets() : ServerScript("coa_fel_commutation_packets", {SERVERHOOK_CAN_PACKET_RECEIVE}) { }

    bool CanPacketReceive(WorldSession* session, WorldPacket const& packet) override
    {
        if (!enabled || packet.GetOpcode() != CMSG_GAMEOBJ_USE || packet.size() < sizeof(uint64) || !session)
            return true;

        Player* player = session->GetPlayer();
        if (!player || !player->IsInWorld())
            return true;

        ObjectGuid const guid(packet.read<uint64>(0));
        if (!guid.IsGameObject())
            return true;

        GameObject* object = player->GetMap()->GetGameObject(guid);
        if (!object || object->GetEntry() != PortalEntry || !object->IsWithinDistInMap(player, altarRange))
            return true;

        ToggleWindow(player);
        return true;
    }
};

class FelCommutationCommands final : public CommandScript
{
public:
    FelCommutationCommands() : CommandScript("coa_fel_commutation_commands") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable clientPushTable = {
            {"string", HandlePushString, SEC_ADMINISTRATOR, Console::No},
            {"reqtype", HandlePushRequirementType, SEC_ADMINISTRATOR, Console::No},
            {"felcommwindow", HandlePushWindow, SEC_ADMINISTRATOR, Console::No},
        };
        static ChatCommandTable commandTable = {
            {"felcommwindow", HandleWindow, SEC_ADMINISTRATOR, Console::No},
            {"clientpush", clientPushTable},
        };
        return commandTable;
    }

    static bool HandlePushString(ChatHandler* handler, uint32 id, std::string key, Tail text)
    {
        Player* player = handler->GetPlayer();
        if (!player)
            return false;

        std::string const value(text);
        WorldPacket data(PatchGlobalStringsOpcode, 18 + key.size() + value.size());
        data << uint32(id) << uint32(0x1 | 0x2) << uint32(0) << uint32(0) << key << value;
        player->SendDirectMessage(&data);
        handler->PSendSysMessage("Sent SMSG 0x0676 row {}: {} = \"{}\". Check with /run print({})", id, key, value, key);
        return true;
    }

    static bool HandlePushRequirementType(ChatHandler* handler, uint32 id, std::string token, Tail lua)
    {
        Player* player = handler->GetPlayer();
        if (!player)
            return false;

        SendAscensionClientLuaFormatter(player, id, token, std::string(lua));
        handler->PSendSysMessage(
            "Sent SMSG 0x05BC row {} token {}. Run it with /run ChallengeUtil.GetRequirementLocalization(\"{}\")", id,
            token, token);
        return true;
    }

    static bool HandlePushWindow(ChatHandler* handler)
    {
        Player* player = handler->GetPlayer();
        if (!player)
            return false;

        RunWindowLua(player);
        handler->PSendSysMessage(
            "Sent the Fel Commutation window (SMSG 0x05BC row {}, 0x05B6 row {}). If "
            "/dump FelCommutationFrame is nil, run /run ChallengeUtil.GetRequirementLocalization(\"{}\")",
            WindowBootstrapRow, WindowRequirementRow, WindowBootstrapToken);
        return true;
    }

    static bool HandleWindow(ChatHandler* handler, uint8 windowId, Optional<uint8> visible)
    {
        Player* player = handler->GetPlayer();
        if (!player)
            return false;

        WorldPacket data(WindowOpcode, 2 * sizeof(uint8));
        data << uint8(windowId) << uint8(visible.value_or(1) != 0 ? 1 : 0);
        player->SendDirectMessage(&data);
        handler->PSendSysMessage("Sent SMSG 0x0906 window {} visible {}.", windowId, visible.value_or(1) != 0 ? 1 : 0);
        return true;
    }
};

class FelCommutationPlayer final : public PlayerScript
{
public:
    FelCommutationPlayer()
        : PlayerScript("coa_fel_commutation_player", {PLAYERHOOK_ON_LOGIN, PLAYERHOOK_CAN_PLAYER_USE_PRIVATE_CHAT})
    {
    }

    void OnPlayerLogin(Player* player) override
    {
        ForgetWindow(player);
        if (player->GetSession()->IsBot())
            return;

        SendState(player);
        if (!enabled)
            return;

        ObjectGuid const guid = player->GetGUID();
        player->m_Events.AddEventAtOffset([guid]()
        {
            Player* player = ObjectAccessor::FindPlayer(guid);
            if (player && player->IsInWorld() && player->HasAura(HighRisk::HighRiskAura))
                EnsureWindowCode(player);
        }, LoginCodeDelay);
    }

    bool OnPlayerCanUseChat(Player* player, uint32 type, uint32 language, std::string& message, Player* receiver) override
    {
        std::string const prefix = std::string(AddonPrefix) + "\t";
        if (!enabled || type != CHAT_MSG_WHISPER || language != LANG_ADDON || receiver != player ||
            message.compare(0, prefix.size(), prefix) != 0)
            return true;

        HandleWindowMessage(player, message.substr(prefix.size()));
        return false;
    }
};
}

class FelCommutationGreedyDemon final : public AllCreatureScript
{
public:
    FelCommutationGreedyDemon() : AllCreatureScript("coa_fel_commutation_greedy_demon") { }

    void OnAllCreatureUpdate(Creature* creature, uint32) override
    {
        if (!enabled || creature->GetEntry() != GreedyDemonEntry)
            return;

        if (creature->HasUnitFlag(UNIT_FLAG_PLAYER_CONTROLLED))
            creature->RemoveUnitFlag(UNIT_FLAG_PLAYER_CONTROLLED);
        if (!creature->HasUnitFlag(UNIT_FLAG_IMMUNE_TO_PC))
            creature->SetUnitFlag(UNIT_FLAG_IMMUNE_TO_PC);
        if (!creature->HasNpcFlag(UNIT_NPC_FLAG_GOSSIP))
            creature->SetNpcFlag(UNIT_NPC_FLAG_GOSSIP);
    }

    bool CanCreatureGossipHello(Player* player, Creature* creature) override
    {
        if (!enabled || creature->GetEntry() != GreedyDemonEntry)
            return false;

        if (OwnGreedyDemon(player, creature))
            ToggleWindow(player);
        return true;
    }
};

bool Enabled()
{
    return enabled;
}

bool Active(Player const* player)
{
    PlayerSettingVector const* settings = player->FindPlayerSettings(Setting);
    return settings && !settings->empty() && settings->front().value != 0;
}

uint32 Shield(Player* player, std::vector<Item*> const& insurable, std::vector<Item*>& losses)
{
    if (!enabled || insurable.empty() || !Active(player))
        return 0;

    uint32 const mask = InsuredSlots(player);
    std::vector<Item*> hit;
    std::vector<uint64> fees;
    for (Item* item : losses)
        if (std::find(insurable.begin(), insurable.end(), item) != insurable.end() &&
            SlotInsured(mask, unsigned(item->GetSlot()) + 1))
        {
            hit.push_back(item);
            fees.push_back(Fee(item));
        }
    if (hit.empty())
        return 0;

    uint64 fee = 0;
    for (uint64 share : fees)
        fee += share;

    ChatHandler chat(player->GetSession());
    if (fee > player->GetMoney())
    {
        chat.SendSysMessage(Acore::StringFormat(
            "Fel Commutation could not protect your items: it needs {} and you carry {}.", FormatMoney(fee),
            FormatMoney(player->GetMoney())));
        return 0;
    }

    for (std::size_t i = 0; i < hit.size(); ++i)
    {
        chat.SendSysMessage(Acore::StringFormat("Item {} kept safe for {}", ItemLink(hit[i]), FormatMoney(fees[i])));
        losses.erase(std::remove(losses.begin(), losses.end(), hit[i]), losses.end());
    }
    return uint32(fee);
}

void ReportLoss(Player* player, uint32 insuranceFee, uint32 droppedGold)
{
    if (!insuranceFee)
        return;

    std::string const detail = droppedGold
        ? Acore::StringFormat("{} insurance and {} dropped gold", FormatMoney(insuranceFee), FormatMoney(droppedGold))
        : Acore::StringFormat("{} insurance", FormatMoney(insuranceFee));
    ChatHandler(player->GetSession()).SendSysMessage(Acore::StringFormat(
        "You lost {} but some of your items were kept safe by Fel Commutation: {}.",
        FormatMoney(uint64(insuranceFee) + droppedGold), detail));
}
}

void AddSC_AscensionFelCommutation()
{
    AscensionCompatOpcodes::Claim(FelCommutation::ToggleOpcode, &FelCommutation::HandleToggle);
    new FelCommutation::FelCommutationWorld();
    new FelCommutation::FelCommutationPlayer();
    new FelCommutation::FelCommutationPackets();
    new FelCommutation::FelCommutationCommands();
    new FelCommutation::FelCommutationGreedyDemon();
}
