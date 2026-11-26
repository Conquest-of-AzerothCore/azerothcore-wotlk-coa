#include "AscensionEquippedGearLoot.h"
#include "AscensionBloodforging.h"
#include "AscensionCreaturePreset.h"
#include "ClientDBC.h"
#include "Config.h"
#include "Creature.h"
#include "DBCStores.h"
#include "ItemTemplate.h"
#include "Log.h"
#include "LootMgr.h"
#include "ObjectMgr.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "World.h"
#include <algorithm>
#include <array>
#include <atomic>
#include <cctype>
#include <cmath>
#include <filesystem>
#include <string>
#include <string_view>
#include <tuple>
#include <unordered_map>
#include <vector>

namespace AscensionEquippedGearLoot
{
namespace
{
enum class Role
{
    Physical,
    Caster,
    Defender
};

constexpr uint32 ITEM_DISPLAY_INFO_FIELDS = 25;

std::atomic_bool enabled{false};
std::atomic<float> chance{5.0f};
std::unordered_map<uint64, std::vector<uint32>> itemsByAppearance;
std::unordered_map<uint64, std::vector<uint32>> itemsByVisualGroup;
std::unordered_map<uint32, uint32> visualGroupByDisplay;

std::string DisplayVisualSignature(ClientDBC::Record const& record)
{
    constexpr std::array<uint32, 4> modelFields = {1, 2, 3, 4};
    constexpr std::array<uint32, 8> textureFields = {15, 16, 17, 18, 19, 20, 21, 22};
    constexpr std::array<uint32, 6> integerFields = {7, 8, 9, 13, 14, 23};

    bool hasVisual = false;
    std::string signature;
    for (uint32 field : modelFields)
    {
        std::string_view const value = record.GetString(field);
        if (!value.empty())
            hasVisual = true;
        signature.append(value);
        signature.push_back('\0');
    }
    for (uint32 field : textureFields)
    {
        std::string_view const value = record.GetString(field);
        if (!value.empty())
            hasVisual = true;
        signature.append(value);
        signature.push_back('\0');
    }
    if (!hasVisual)
        return {};
    for (uint32 field : integerFields)
    {
        signature.append(std::to_string(record.GetUInt32(field)));
        signature.push_back('\0');
    }
    return signature;
}

void LoadVisualGroups()
{
    visualGroupByDisplay.clear();
    ClientDBC displays;
    std::filesystem::path const path = std::filesystem::path(sWorld->GetDataPath()) / "dbc" / "ItemDisplayInfo.dbc";
    if (!displays.Load(path.string(), ITEM_DISPLAY_INFO_FIELDS))
        return;

    std::unordered_map<std::string, uint32> canonicalBySignature;
    for (uint32 row = 0; row < displays.GetRecordCount(); ++row)
    {
        ClientDBC::Record const record = displays.GetRecord(row);
        uint32 const displayId = record.GetUInt32(0);
        if (!displayId)
            continue;
        std::string signature = DisplayVisualSignature(record);
        if (signature.empty())
            continue;
        auto const found = canonicalBySignature.emplace(std::move(signature), displayId).first;
        visualGroupByDisplay.emplace(displayId, found->second);
    }
}

bool SameVisualDisplay(uint32 leftDisplay, uint32 rightDisplay)
{
    if (!leftDisplay || !rightDisplay)
        return false;
    if (leftDisplay == rightDisplay)
        return true;
    auto const left = visualGroupByDisplay.find(leftDisplay);
    auto const right = visualGroupByDisplay.find(rightDisplay);
    return left != visualGroupByDisplay.end() && right != visualGroupByDisplay.end() && left->second == right->second;
}

uint32 SlotType(uint32 inventoryType)
{
    switch (inventoryType)
    {
        case INVTYPE_ROBE:
            return INVTYPE_CHEST;
        case INVTYPE_WEAPONMAINHAND:
        case INVTYPE_WEAPONOFFHAND:
            return INVTYPE_WEAPON;
        case INVTYPE_RANGEDRIGHT:
            return INVTYPE_RANGED;
        default:
            return inventoryType;
    }
}

uint64 AppearanceKey(uint32 display, uint32 inventoryType)
{
    return (uint64(display) << 32) | SlotType(inventoryType);
}

bool PlaceholderName(std::string_view name)
{
    constexpr std::array<std::string_view, 6> prefixes = {"Monster -", "***", "zzOLD", "zzDEPRECATED", "RPGITEM",
        "NPC Equipment"};
    if (std::any_of(prefixes.begin(), prefixes.end(),
            [name](std::string_view prefix) { return name.starts_with(prefix); }) ||
        name.find("[MISSING ITEM NAME]") != std::string_view::npos)
        return true;

    std::string lowered(name);
    std::transform(lowered.begin(), lowered.end(), lowered.begin(),
        [](char character) { return char(std::tolower(static_cast<unsigned char>(character))); });

    auto const isWordChar = [](char character)
    {
        return character == '_' || std::isalnum(static_cast<unsigned char>(character)) != 0;
    };
    constexpr std::array<std::string_view, 4> words = {"unused", "test", "ph", "deprecated"};
    for (std::string_view word : words)
        for (std::size_t at = lowered.find(word); at != std::string::npos; at = lowered.find(word, at + 1))
            if ((at == 0 || !isWordChar(lowered[at - 1])) &&
                (at + word.size() == lowered.size() || !isWordChar(lowered[at + word.size()])))
                return true;
    return false;
}

bool TaggedCopy(ItemTemplate const& item)
{
    return item.Description.starts_with('@');
}

bool Wearable(ItemTemplate const& item)
{
    return item.DisplayInfoID && item.ItemLevel && item.InventoryType != INVTYPE_NON_EQUIP
        && (item.Class == ITEM_CLASS_ARMOR || item.Class == ITEM_CLASS_WEAPON)
        && item.Quality <= ITEM_QUALITY_UNCOMMON
        && (item.Bonding == NO_BIND || item.Bonding == BIND_WHEN_EQUIPPED)
        && !item.HasFlag(ITEM_FLAG_DEPRECATED) && !item.HasFlag(ITEM_FLAG_CONJURED)
        && !item.StartQuest && !item.RequiredSkill && !item.RequiredSpell && !item.RandomProperty && !item.RandomSuffix
        && !item.RequiredHonorRank && !item.RequiredReputationFaction
        && !PlaceholderName(item.Name1) && !Bloodforging::IsBloodforged(item) && !TaggedCopy(item);
}

uint32 GearLevel(ItemTemplate const& item)
{
    return item.RequiredLevel ? item.RequiredLevel : item.ItemLevel > 5 ? item.ItemLevel - 5 : 0;
}

uint32 Stat(ItemTemplate const& item, uint32 type)
{
    uint32 value = 0;
    for (auto const& stat : item.ItemStat)
        if (stat.ItemStatType == type && stat.ItemStatValue > 0)
            value += stat.ItemStatValue;
    return value;
}

uint32 RoleScore(ItemTemplate const& item, Role role)
{
    bool const intellect = Stat(item, ITEM_MOD_INTELLECT) || Stat(item, ITEM_MOD_SPELL_POWER);
    bool const physical = Stat(item, ITEM_MOD_STRENGTH) || Stat(item, ITEM_MOD_AGILITY)
        || Stat(item, ITEM_MOD_ATTACK_POWER) || Stat(item, ITEM_MOD_RANGED_ATTACK_POWER);
    bool const stamina = Stat(item, ITEM_MOD_STAMINA);
    bool const defense = Stat(item, ITEM_MOD_DEFENSE_SKILL_RATING) || Stat(item, ITEM_MOD_DODGE_RATING)
        || Stat(item, ITEM_MOD_PARRY_RATING) || Stat(item, ITEM_MOD_BLOCK_RATING) || Stat(item, ITEM_MOD_BLOCK_VALUE);

    if (role == Role::Caster)
    {
        if (Stat(item, ITEM_MOD_INTELLECT))
            return 4;
        if (intellect)
            return 3;
        return physical || defense ? 0 : 1;
    }

    if (role == Role::Defender && defense)
        return 4;
    if (intellect && !physical)
        return 0;
    if (role == Role::Defender && stamina)
        return 3;
    return physical ? 2 : 1;
}

Role CreatureRole(Creature const& creature)
{
    for (uint32 slot = 0; slot < MAX_EQUIPMENT_ITEMS; ++slot)
        if (ItemTemplate const* item = sObjectMgr->GetItemTemplate(creature.GetVirtualItemId(slot)))
            if (item->InventoryType == INVTYPE_SHIELD)
                return Role::Defender;
    return creature.GetCreatureTemplate()->unit_class == CLASS_MAGE ? Role::Caster : Role::Physical;
}

uint32 BestCandidate(std::vector<uint32> const& entries, uint32 display, uint32 slot, uint32 level, Role role,
    Loot const& loot, ItemTemplate const* weapon)
{
    uint32 best = 0;
    std::tuple<uint32, uint32, uint32> bestScore{};
    for (uint32 entry : entries)
    {
        ItemTemplate const* item = sObjectMgr->GetItemTemplate(entry);
        if (!item || !Wearable(*item) || !SameVisualDisplay(item->DisplayInfoID, display)
            || SlotType(item->InventoryType) != SlotType(slot) || GearLevel(*item) > level
            || (weapon && (item->Class != weapon->Class || item->SubClass != weapon->SubClass))
            || std::any_of(loot.items.begin(), loot.items.end(),
                [entry](LootItem const& existing) { return existing.itemid == entry; }))
            continue;

        uint32 const roleScore = RoleScore(*item, role);
        if (!roleScore)
            continue;
        auto const score = std::make_tuple(roleScore, GearLevel(*item), item->Quality);
        if (!best || score > bestScore || (score == bestScore && entry < best))
        {
            best = entry;
            bestScore = score;
        }
    }
    return best;
}

uint32 MatchingItem(uint32 display, uint32 slot, uint32 level, Role role, Loot const& loot,
    ItemTemplate const* weapon = nullptr)
{
    if (auto const found = itemsByAppearance.find(AppearanceKey(display, slot)); found != itemsByAppearance.end())
        if (uint32 const exact = BestCandidate(found->second, display, slot, level, role, loot, weapon))
            return exact;

    auto const group = visualGroupByDisplay.find(display);
    if (group == visualGroupByDisplay.end())
        return 0;
    auto const found = itemsByVisualGroup.find(AppearanceKey(group->second, slot));
    if (found == itemsByVisualGroup.end())
        return 0;
    return BestCandidate(found->second, display, slot, level, role, loot, weapon);
}

class Configuration : public WorldScript
{
public:
    Configuration() : WorldScript("AscensionEquippedGearLootConfiguration",
        {WORLDHOOK_ON_AFTER_CONFIG_LOAD, WORLDHOOK_ON_STARTUP}) { }

    void OnAfterConfigLoad(bool) override
    {
        enabled.store(sConfigMgr->GetOption<bool>("CoA.Enable", true)
            && sConfigMgr->GetOption<bool>("CoA.EquippedGearLoot", true));
        float const configured = sConfigMgr->GetOption<float>("CoA.EquippedGearLootChance", 5.0f);
        chance.store(std::isfinite(configured) ? std::clamp(configured, 0.0f, 100.0f) : 0.0f);
    }

    void OnStartup() override
    {
        LoadVisualGroups();
        itemsByAppearance.clear();
        itemsByVisualGroup.clear();
        for (auto const& [entry, item] : *sObjectMgr->GetItemTemplateStore())
        {
            if (!Wearable(item))
                continue;
            itemsByAppearance[AppearanceKey(item.DisplayInfoID, item.InventoryType)].push_back(entry);
            if (auto const group = visualGroupByDisplay.find(item.DisplayInfoID); group != visualGroupByDisplay.end())
                itemsByVisualGroup[AppearanceKey(group->second, item.InventoryType)].push_back(entry);
        }
        LOG_INFO("coa", "Equipped gear loot ready: {} wearable appearances", itemsByAppearance.size());
    }
};
}

bool SameAppearance(uint32 leftDisplay, uint32 rightDisplay)
{
    return SameVisualDisplay(leftDisplay, rightDisplay);
}

bool AddLoot(Creature const* creature, Loot& loot, uint16 lootMode)
{
    if (!enabled.load() || !creature || !(lootMode & LOOT_MODE_DEFAULT)
        || creature->IsPet() || creature->IsSummon() || creature->GetCharmerOrOwnerGUID()
        || creature->IsLootRewardDisabled() || creature->IsDungeonBoss()
        || loot.items.size() >= MAX_NR_LOOT_ITEMS || !roll_chance_f(chance.load()))
        return false;

    Role const role = CreatureRole(*creature);
    uint32 const level = creature->GetLevel();
    std::vector<uint32> candidates;
    auto add = [&candidates](uint32 entry)
    {
        if (entry && std::find(candidates.begin(), candidates.end(), entry) == candidates.end())
            candidates.push_back(entry);
    };

    for (uint32 slot = 0; slot < MAX_EQUIPMENT_ITEMS; ++slot)
        if (ItemTemplate const* weapon = sObjectMgr->GetItemTemplate(creature->GetVirtualItemId(slot)))
            add(MatchingItem(weapon->DisplayInfoID, weapon->InventoryType, level, role, loot, weapon));

    std::array<uint32, 11> displays{};
    CreatureDisplayPreset const* preset = sAscensionPresets->GetPreset(creature->GetEntry(), creature->GetDisplayId());
    if (!preset)
        preset = sAscensionPresets->GetActivePresetOverride(creature->GetGUID());
    if (preset)
        displays = preset->items;
    else if (CreatureDisplayInfoEntry const* display = sCreatureDisplayInfoStore.LookupEntry(creature->GetDisplayId()))
        if (CreatureDisplayInfoExtraEntry const* extra = sCreatureDisplayInfoExtraStore.LookupEntry(
            display->ExtendedDisplayInfoID))
            std::copy(std::begin(extra->NPCItemDisplay), std::end(extra->NPCItemDisplay), displays.begin());

    constexpr std::array<uint32, 11> slots = {INVTYPE_HEAD, INVTYPE_SHOULDERS, INVTYPE_BODY, INVTYPE_CHEST,
        INVTYPE_WAIST, INVTYPE_LEGS, INVTYPE_FEET, INVTYPE_WRISTS, INVTYPE_HANDS, INVTYPE_CLOAK, INVTYPE_TABARD};
    for (std::size_t slot = 0; slot < displays.size(); ++slot)
        if (displays[slot])
            add(MatchingItem(displays[slot], slots[slot], level, role, loot));

    if (candidates.empty())
        return false;
    std::size_t const before = loot.items.size();
    loot.AddItem(LootStoreItem(candidates[urand(0, uint32(candidates.size() - 1))], 0, 100.0f, false,
        LOOT_MODE_DEFAULT, 0, 1, 1));
    return loot.items.size() > before;
}
}

void AddAscensionEquippedGearLootScripts()
{
    new AscensionEquippedGearLoot::Configuration();
}
