#include "ClientDBC.h"
#include <algorithm>
#include <array>
#include <cstdint>
#include <fstream>
#include <iostream>
#include <limits>
#include <map>
#include <memory>
#include <mutex>
#include <set>
#include <stdexcept>
#include <string>
#include <tuple>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <vector>

template<class... Args>
void LogSink(Args&&...) { }
#define LOG_INFO(...) LogSink(__VA_ARGS__)
#define LOG_WARN(...) LogSink(__VA_ARGS__)
#define LOG_ERROR(...) LogSink(__VA_ARGS__)

constexpr std::size_t HeaderSize = 20;
constexpr uint32 SKILL_WOODWORKING = 757;
std::string Directory;

namespace ItemScaling
{
uint32 BaseEntry(uint32 entry) { return entry; }
}

// ACTUAL_CONSTANTS
// ACTUAL_PATCH_CONSTANTS
// ACTUAL_ENUMS
// ACTUAL_RECORDS
// ACTUAL_CLIENT_DBC

std::string GetClientDBCPath(char const* file) { return Directory + '/' + file; }

struct WorldPacket
{
    uint16 Opcode;
    std::vector<uint8> Bytes;
    WorldPacket(uint16 opcode, std::size_t capacity) : Opcode(opcode) { Bytes.reserve(capacity); }
    WorldPacket& operator<<(uint32 value)
    {
        for (uint32 shift = 0; shift < 32; shift += 8)
            Bytes.push_back(uint8(value >> shift));
        return *this;
    }
    WorldPacket& operator<<(char const* value)
    {
        do { Bytes.push_back(uint8(*value)); } while (*value++);
        return *this;
    }
};

struct WorldSession
{
    std::vector<WorldPacket> Packets;
    void SendPacket(WorldPacket const* packet) { Packets.push_back(*packet); }
};

struct ObjectGuid
{
    uint32 GetCounter() const { return 42; }
};

struct Player
{
    WorldSession Session;
    std::vector<uint32> ItemPatchRequests;
    ObjectGuid GetGUID() const { return {}; }
    WorldSession* GetSession() { return &Session; }
    bool IsInWorld() const { return true; }
    char const* GetName() const { return "Woodworker"; }
};

struct Item
{
    uint32 Entry;
    uint32 GetEntry() const { return Entry; }
};

struct ItemTemplate
{
    uint32 Class;
    uint32 SubClass;
    uint32 DisplayInfoID;
    uint32 InventoryType;
};

struct ObjectMgr
{
    std::unordered_map<uint32, ItemTemplate> Items;
    ItemTemplate const* GetItemTemplate(uint32 id) const
    {
        auto item = Items.find(id);
        return item == Items.end() ? nullptr : &item->second;
    }
    auto const* GetItemTemplateStore() const { return &Items; }
} objectMgr;
auto sObjectMgr = &objectMgr;

// ACTUAL_APPEARANCE_ALIASES

struct SpellEffectInfo
{
    uint32 Effect;
    uint32 ItemType;
};

struct SpellInfo
{
    std::array<SpellEffectInfo, 3> Effects{};
};

struct SpellMgr
{
    std::map<uint32, SpellInfo> Spells;
    SpellInfo const* GetSpellInfo(uint32 id) const
    {
        auto spell = Spells.find(id);
        return spell == Spells.end() ? nullptr : &spell->second;
    }
} spellMgr;
auto sSpellMgr = &spellMgr;

struct SkillLineAbilityEntry { uint32 Spell; };
std::vector<SkillLineAbilityEntry> Abilities;
std::vector<SkillLineAbilityEntry const*> AbilityPointers;
std::vector<SkillLineAbilityEntry const*> const& GetSkillLineAbilitiesBySkillLine(uint32 skill)
{
    if (skill != SKILL_WOODWORKING)
        throw std::runtime_error("Catalog must be restricted to Woodworking");
    return AbilityPointers;
}

enum class AscensionCompatConfig { ENABLED, UNLOCK_ALL_VANITY };
struct Config
{
    template<class T>
    T GetConfigValue(AscensionCompatConfig key) const { return key == AscensionCompatConfig::ENABLED; }
} ascensionCompatConfig;

struct AscensionDisplayPatchService
{
    static AscensionDisplayPatchService& Instance()
    {
        static AscensionDisplayPatchService service;
        return service;
    }

    void SendItemRowOnDemand(Player* player, uint32 entry) { player->ItemPatchRequests.push_back(entry); }
};

struct Database
{
    std::vector<std::array<uint32, 3>> Writes;
    template<class... Args>
    void Execute(char const*, Args... values)
    {
        std::array<uint32, sizeof...(Args)> row{uint32(values)...};
        if constexpr (sizeof...(Args) == 3)
            Writes.push_back(row);
        else
            throw std::runtime_error("Crafting cannot persist vanity items");
    }
} CharacterDatabase;

struct PlayerScript
{
    std::vector<uint16> Hooks;
    PlayerScript(char const*, std::vector<uint16> hooks) : Hooks(std::move(hooks)) { }
    virtual ~PlayerScript() = default;
    virtual void OnPlayerCreateItem(Player*, Item*, uint32) { }
    bool Enabled(PlayerHook hook) const
    {
        return std::find(Hooks.begin(), Hooks.end(), hook) != Hooks.end();
    }
};

struct ScriptMgr
{
    std::vector<PlayerScript*> Scripts;
    std::set<uint32> Progress;
    void OnPlayerCreateItem(Player*, Item*, uint32);
    void OnPlayerCoAProgress(Player*, CoAProgressEvent event, uint32 value)
    {
        if (event != CoAProgressEvent::AppearanceCollected)
            throw std::runtime_error("Crafting gear cannot unlock vanity progress");
        Progress.insert(value);
    }
} scripts;
auto sScriptMgr = &scripts;

#define CALL_ENABLED_HOOKS(Type, Hook, Call) \
    for (PlayerScript* script : Scripts) \
        if (script->Enabled(Hook)) \
            Call

// ACTUAL_DISPATCH_CREATE

class AscensionCollectionService
{
public:
    std::unordered_map<uint32, AppearanceInfo> _appearances;
    std::unordered_map<uint32, uint32> _itemAppearances;
    std::unordered_map<uint32, std::vector<uint32>> _itemSetItems;
    std::unordered_map<uint32, VanityInfo> _vanityItems;
    std::vector<uint32> _allAppearanceIds;
    std::vector<uint32> _allVanityItemIds;
    std::vector<std::array<uint32, 17>> _woodworkingAppearancePatches;
    std::vector<std::array<uint32, 3>> _woodworkingItemAppearancePatches;
    std::unordered_map<uint32, std::shared_ptr<PlayerCollectionState>> _playerStates;
    std::mutex _stateMutex;
    bool _clientDataLoaded = false;
    static bool IsCosmeticCategory(uint32) { return false; }
    static uint32 ResolveCosmeticSpell(uint32, uint32, uint32) { return 0; }
    static uint32 ResolveShadowhoundDisplay(uint32) { return 0; }
    bool IsBankVanityItem(uint32) const { return false; }
    void LearnOwnedBankSpells(Player*, PlayerCollectionState&, bool) { }
    // ACTUAL_INSTANCE
    // ACTUAL_LOAD
    // ACTUAL_LOAD_WOODWORKING
    // ACTUAL_SEND_CATALOG
    // ACTUAL_GET_STATE
    // ACTUAL_OBTAINED
    // ACTUAL_IS_EQUIPMENT
    // ACTUAL_COLLECT_APPEARANCE
    // ACTUAL_COLLECT_ITEM
    // ACTUAL_SEND_ADDED
};

struct AscensionCompatPlayerScript : PlayerScript
{
    // ACTUAL_SCRIPT_CONSTRUCTOR
    // ACTUAL_SCRIPT_CREATE
    // ACTUAL_SCRIPT_PATCH
};

void Require(bool condition, std::string const& message)
{
    if (!condition)
        throw std::runtime_error(message);
}

uint32 DWord(WorldPacket const& packet, uint32 index)
{
    Require((index + 1) * 4 <= packet.Bytes.size(), "packet DWORD within bounds");
    uint32 value = 0;
    for (uint32 byte = 0; byte < 4; ++byte)
        value |= uint32(packet.Bytes[index * 4 + byte]) << (byte * 8);
    return value;
}

int main(int argc, char** argv)
{
    try
    {
        Require(argc == 2, "DBC fixture directory required");
        Directory = argv[1];
        ClientDBC items;
        Require(items.Load(GetClientDBCPath("Item.dbc"), 8), "native Item DBC fixture");
        for (uint32 row = 0; row < items.GetRecordCount(); ++row)
        {
            auto record = items.GetRecord(row);
            objectMgr.Items[record.GetUInt32(0)] = {record.GetUInt32(1), record.GetUInt32(2),
                record.GetUInt32(5), record.GetUInt32(6)};
        }
        std::ifstream recipes(Directory + "/recipes.txt");
        uint32 spellId;
        std::set<uint32> gear;
        std::set<uint32> nonvisual;
        while (recipes >> spellId)
        {
            auto& info = spellMgr.Spells[spellId];
            for (auto& effect : info.Effects)
            {
                recipes >> effect.Effect >> effect.ItemType;
                auto item = objectMgr.GetItemTemplate(effect.ItemType);
                if (!item || effect.Effect != SPELL_EFFECT_CREATE_ITEM)
                    continue;
                if ((item->Class == ITEM_CLASS_WEAPON || item->Class == ITEM_CLASS_ARMOR) &&
                    item->InventoryType && item->InventoryType != INVTYPE_TRINKET)
                    gear.insert(effect.ItemType);
                else
                    nonvisual.insert(effect.ItemType);
            }
            Abilities.push_back({spellId});
        }
        for (auto const& ability : Abilities)
            AbilityPointers.push_back(&ability);
        Require(gear.size() == 78, "selected Woodworking recipes must produce 78 visible gear items");
        ClientDBC nativeMappings;
        Require(nativeMappings.Load(GetClientDBCPath("ItemAppearances.dbc"), 3), "native item mappings");
        uint32 lastNativeMappingId = 0;
        for (uint32 row = 0; row < nativeMappings.GetRecordCount(); ++row)
            lastNativeMappingId = std::max(lastNativeMappingId, nativeMappings.GetRecord(row).GetUInt32(0));
        auto& service = AscensionCollectionService::Instance();
        Require(service.LoadClientData(), "native collection DBC loading");
        Player player;
        auto state = std::make_shared<PlayerCollectionState>();
        state->AccountId = 123;
        service._playerStates[42] = state;
        service.SendWoodworkingAppearanceCatalog(&player);
        Require(state->CollectedAppearances.empty() && CharacterDatabase.Writes.empty(),
            "catalog publication precedes appearance ownership");
        auto patches = player.Session.Packets;
        player.Session.Packets.clear();
        AscensionCompatPlayerScript script;
        scripts.Scripts.push_back(&script);
        Item bow{1061535};
        scripts.OnPlayerCreateItem(&player, &bow, 1);
        Require(player.ItemPatchRequests == std::vector<uint32>{1061535},
            "the original crafted-item helper requests the obtained bow's display patch");
        Require(state->CollectedAppearances.contains(24272),
            "expected crafted Malachite-Infused Bow to unlock appearance 24272");
        Require(service._woodworkingItemAppearancePatches.size() == 78, "every visible crafted item needs a mapping");
        Require(service._woodworkingAppearancePatches.size() == 2,
            "Green Gembound Pages and Wildclaw need new compatible entries");
        Require(patches.size() == 80 && patches.front().Opcode == SMSG_PATCH_APPEARANCES,
            "new appearance definition precedes all item mappings");
        auto const& appearance = patches.front();
        Require(appearance.Bytes.size() == 68 + sizeof("APPEARANCE_DISPLAY_TYPE_ITEM"),
            "appearance packet has a 17-DWORD image and one terminated display-type string");
        Require(DWord(appearance, 0) == 1061571 && DWord(appearance, 1) == 1061571 &&
            DWord(appearance, 3) == 1061571 && DWord(appearance, 5) == 14 &&
            DWord(appearance, 8) == 1061571, "Green Gembound Pages is an off-hand item appearance");
        Require(std::string(appearance.Bytes.begin() + 68, appearance.Bytes.end() - 1) ==
            "APPEARANCE_DISPLAY_TYPE_ITEM" && appearance.Bytes.back() == 0, "native appearance display-type payload");
        for (uint32 field = 12; field < 17; ++field)
            Require(DWord(appearance, field) == 1, "appearance available to all existing realm types");
        Require(patches[1].Opcode == SMSG_PATCH_APPEARANCES && DWord(patches[1], 0) == 1061629 &&
            DWord(patches[1], 3) == 1061629 && DWord(patches[1], 5) == 13 && DWord(patches[1], 6) == 14,
            "crafted Wildclaw supports both hands through its own compatible item template");
        std::set<uint32> patchItems;
        std::set<uint32> patchRows;
        for (std::size_t index = 2; index < patches.size(); ++index)
        {
            auto const& patch = patches[index];
            Require(patch.Opcode == SMSG_PATCH_ITEM_APPEARANCES && patch.Bytes.size() == 12, "item mapping wire image");
            Require(DWord(patch, 0) > lastNativeMappingId, "new mapping rows cannot overwrite client records");
            Require(patchRows.insert(DWord(patch, 0)).second, "unique mapping row IDs");
            Require(patchItems.insert(DWord(patch, 1)).second && gear.contains(DWord(patch, 1)),
                "unique crafted sources");
            Require(service._itemAppearances.at(DWord(patch, 1)) == DWord(patch, 2),
                "client and server mapping parity");
        }
        Require(patchItems == gear, "catalog packets cover every visible recipe output");
        std::set<uint32> expected;
        for (uint32 itemId : gear)
        {
            auto id = service._itemAppearances.at(itemId);
            expected.insert(id);
            auto item = objectMgr.GetItemTemplate(itemId);
            auto source = objectMgr.GetItemTemplate(service._appearances.at(id).SourceItem);
            Require(source && item->DisplayInfoID == source->DisplayInfoID && item->Class == source->Class &&
                item->SubClass == source->SubClass && item->InventoryType == source->InventoryType,
                "appearance must match the crafted visual and equipment type");
            Item crafted{itemId};
            scripts.OnPlayerCreateItem(&player, &crafted, 1);
            Require(player.ItemPatchRequests.back() == itemId,
                "each ordinary crafting callback forwards its actual source item to the patch service");
        }
        Require(player.ItemPatchRequests.size() == gear.size() + 1,
            "one demand-patch request per actual crafting callback");
        scripts.OnPlayerCreateItem(&player, nullptr, 1);
        Require(player.ItemPatchRequests.size() == gear.size() + 1,
            "an absent crafted item does not request a display patch");
        Require(state->CollectedAppearances.size() == expected.size() &&
            CharacterDatabase.Writes.size() == expected.size(),
            "crafted appearances persist once per distinct visual");
        for (auto const& row : CharacterDatabase.Writes)
            Require(row[0] == 123 && service._itemAppearances.at(row[2]) == row[1],
                "account and crafted source persistence");
        Require(player.Session.Packets.size() == expected.size(), "one unlock notification per distinct visual");
        for (auto const& packet : player.Session.Packets)
            Require(packet.Opcode == SMSG_APPEARANCE_ADDED && packet.Bytes.size() == 8 &&
                expected.contains(DWord(packet, 0)) &&
                service._itemAppearances.at(DWord(packet, 1)) == DWord(packet, 0),
                "appearance-added packet carries the crafted source item");
        for (uint32 itemId : nonvisual)
            Require(!service._itemAppearances.contains(itemId),
                "materials, utilities, ammunition and trinkets stay unmapped");
        auto count = service._itemAppearances.size();
        Require(service.LoadClientData() && service._itemAppearances.size() == count &&
            service._woodworkingItemAppearancePatches.size() == 78, "catalog reload is idempotent");
        service._woodworkingItemAppearancePatches.clear();
        service._woodworkingAppearancePatches.clear();
        service._itemAppearances[1061535] = 24267;
        service.LoadWoodworkingAppearances(lastNativeMappingId);
        Require(service._woodworkingItemAppearancePatches.empty() && service._woodworkingAppearancePatches.empty(),
            "existing catalog mappings remain authoritative");
        Require(service._itemAppearances.at(1061535) == 24267,
            "native mappings cannot be replaced by visual inference");
        std::cout << "PASS: native crafting hook collects all 78 Woodworking gear appearances; "
            "client catalog patch format/order, saved source ownership, duplicates, visual parity and reload\n";
    }
    catch (std::exception const& error)
    {
        std::cerr << "FAIL: " << error.what() << '\n';
        return 1;
    }
}
