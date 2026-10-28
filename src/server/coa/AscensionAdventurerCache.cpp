/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionAdventurerCachePolicy.h"
#include "AscensionCacheRewards.h"
#include "AscensionSpecLoot.h"
#include "AscensionSpecialization.h"
#include "Chat.h"
#include "DBCStores.h"
#include "Item.h"
#include "ItemEnchantmentMgr.h"
#include "ItemScript.h"
#include "Log.h"
#include "LootMgr.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include <algorithm>
#include <array>
#include <vector>

namespace
{
enum CacheItems : uint32
{
    AdventurerSatchel = 1397884,
    AdventurerCache = 1397885,
    AdventurerRareCache = 1397886
};

bool IsAdventurerReward(uint32 entry)
{
    return entry == AdventurerSatchel || entry == AdventurerCache || entry == AdventurerRareCache;
}

bool IsGearCache(uint32 entry)
{
    return entry == AdventurerCache || entry == AdventurerRareCache;
}

constexpr uint32 FirstHelpfulGoodsSatchel = 51999;
constexpr uint32 LastHelpfulGoodsSatchel = 52002;

bool IsHelpfulGoodsSatchel(uint32 entry)
{
    return entry >= FirstHelpfulGoodsSatchel && entry <= LastHelpfulGoodsSatchel;
}

LootStoreItem* BestWearableEntry(Player const* player, std::list<LootStoreItem*> const& entries)
{
    LootStoreItem* best = nullptr;
    uint32 bestArmorClass = 0;
    for (LootStoreItem* entry : entries)
    {
        ItemTemplate const* item = sObjectMgr->GetItemTemplate(entry->itemid);
        if (!item || entry->reference || item->RequiredLevel > player->GetLevel() ||
            player->CanUseItem(item) != EQUIP_ERR_OK || (item->GetSkill() && !player->GetSkillValue(item->GetSkill())))
            continue;
        if (!best || item->SubClass > bestArmorClass)
        {
            best = entry;
            bestArmorClass = item->SubClass;
        }
    }
    return best;
}

enum RewardKind : uint8
{
    Food,
    Potion,
    Material,
    Armor,
    RewardKindCount
};

using RewardPools = std::array<std::vector<LootStoreItem*>, RewardKindCount>;

bool HasWearableStats(ItemTemplate const* item)
{
    return item->StatsCount > 0 || item->ScalingStatDistribution != 0 ||
        item->RandomProperty != 0 || item->RandomSuffix != 0;
}

bool IsGear(ItemTemplate const* item)
{
    return item->Class == ITEM_CLASS_WEAPON || item->Class == ITEM_CLASS_ARMOR;
}

uint32 BodyArmorClass(ItemTemplate const* item)
{
    if (item->Class != ITEM_CLASS_ARMOR || item->InventoryType == INVTYPE_CLOAK ||
        item->SubClass < ITEM_SUBCLASS_ARMOR_CLOTH || item->SubClass > ITEM_SUBCLASS_ARMOR_PLATE)
        return 0;
    return item->SubClass;
}

std::vector<int32> AffixChoices(ItemTemplate const* item)
{
    std::vector<int32> affixes;
    if (item->RandomProperty)
    {
        if (!HasItemEnchantTemplate(item->RandomProperty))
        {
            if (sItemRandomPropertiesStore.LookupEntry(item->RandomProperty))
                affixes.push_back(int32(item->RandomProperty));
            return affixes;
        }
        for (uint32 property : GetItemEnchantModChoices(item->RandomProperty))
            if (sItemRandomPropertiesStore.LookupEntry(property))
                affixes.push_back(int32(property));
    }
    else if (item->RandomSuffix)
        for (uint32 suffix : GetItemEnchantModChoices(item->RandomSuffix))
            if (sItemRandomSuffixStore.LookupEntry(suffix))
                affixes.push_back(-int32(suffix));
    return affixes;
}

AscensionSpecLoot::StatList AffixStats(int32 affix)
{
    std::array<uint32, MAX_ITEM_ENCHANTMENT_EFFECTS> enchantments{};
    std::array<uint32, MAX_ITEM_ENCHANTMENT_EFFECTS> allocations{};
    if (affix > 0)
    {
        if (ItemRandomPropertiesEntry const* property = sItemRandomPropertiesStore.LookupEntry(affix))
            enchantments = property->Enchantment;
    }
    else if (ItemRandomSuffixEntry const* suffix = sItemRandomSuffixStore.LookupEntry(-affix))
    {
        enchantments = suffix->Enchantment;
        allocations = suffix->AllocationPct;
    }

    AscensionSpecLoot::StatList stats;
    for (uint32 index = 0; index < MAX_ITEM_ENCHANTMENT_EFFECTS; ++index)
        if (SpellItemEnchantmentEntry const* enchantment = sSpellItemEnchantmentStore.LookupEntry(enchantments[index]))
            for (uint32 effect = 0; effect < MAX_SPELL_ITEM_ENCHANTMENT_EFFECTS; ++effect)
                if (enchantment->type[effect] == ITEM_ENCHANTMENT_TYPE_STAT)
                    stats.emplace_back(enchantment->spellid[effect],
                        int32(allocations[index] ? allocations[index] : enchantment->amount[effect]));
    return stats;
}

AscensionSpecLoot::Fit AffixFit(AscensionSpecLoot::PrimaryStats const& stats, ItemTemplate const* item, int32 affix)
{
    AscensionSpecLoot::StatList itemStats = AscensionSpecLoot::TemplateStats(item);
    AscensionSpecLoot::StatList const affixStats = AffixStats(affix);
    itemStats.insert(itemStats.end(), affixStats.begin(), affixStats.end());
    return AscensionSpecLoot::StatsFit(stats, itemStats);
}

AscensionSpecLoot::Fit GearFit(AscensionSpecLoot::PrimaryStats const& stats, ItemTemplate const* item)
{
    std::vector<int32> const affixes = AffixChoices(item);
    if (affixes.empty())
        return AscensionSpecLoot::ItemFit(stats, item);

    AscensionSpecLoot::Fit best = AscensionSpecLoot::Fit::None;
    for (int32 affix : affixes)
        best = std::max(best, AffixFit(stats, item, affix));
    return best;
}

int32 FittingAffix(AscensionSpecLoot::PrimaryStats const& stats, ItemTemplate const* item, int32 rolled)
{
    std::vector<int32> const affixes = AffixChoices(item);
    std::vector<int32> const fitting = AscensionSpecLoot::PreferFit(affixes, [&stats, item](int32 affix)
    {
        return AffixFit(stats, item, affix);
    });
    if (fitting.size() == affixes.size())
        return rolled;
    return fitting[urand(0, uint32(fitting.size() - 1))];
}

RewardPools SortRewards(Player const* player, std::list<LootStoreItem*> const& entries)
{
    RewardPools rewards;
    std::array<uint32, RewardKindCount> bestLevel{};
    for (LootStoreItem* entry : entries)
    {
        ItemTemplate const* item = sObjectMgr->GetItemTemplate(entry->itemid);
        if (!item || entry->reference)
            continue;
        RewardKind kind;
        if (item->Class == ITEM_CLASS_TRADE_GOODS)
            kind = Material;
        else if (item->Class == ITEM_CLASS_ARMOR)
            kind = Armor;
        else if (item->Class == ITEM_CLASS_CONSUMABLE && item->SubClass == ITEM_SUBCLASS_FOOD)
            kind = Food;
        else if (item->IsPotion())
            kind = Potion;
        else
            continue;

        uint32 level = kind == Material ? item->ItemLevel : item->RequiredLevel;
        uint32 ceiling = player->GetLevel() + (kind == Material ? 5 : 0);
        if (level > ceiling || (kind != Material && player->CanUseItem(item) != EQUIP_ERR_OK) ||
            (kind == Armor && item->GetSkill() && !player->GetSkillValue(item->GetSkill())) ||
            (kind == Armor && !HasWearableStats(item)))
            continue;
        rewards[kind].push_back(entry);
        bestLevel[kind] = std::max(bestLevel[kind], level);
    }

    for (uint8 kind = 0; kind < RewardKindCount; ++kind)
        std::erase_if(rewards[kind], [kind, &bestLevel](LootStoreItem const* entry)
        {
            ItemTemplate const* item = sObjectMgr->GetItemTemplate(entry->itemid);
            uint32 level = kind == Material ? item->ItemLevel : item->RequiredLevel;
            return level + 10 < bestLevel[kind];
        });
    return rewards;
}

void AddSatchelReward(Player const* player, std::list<LootStoreItem*> const& entries, Loot& loot)
{
    RewardPools const rewards = SortRewards(player, entries);
    std::vector<uint8> kinds;
    for (uint8 kind = 0; kind < RewardKindCount; ++kind)
        if (!rewards[kind].empty())
            kinds.push_back(kind);
    if (kinds.empty())
        return;

    auto const& choices = rewards[kinds[urand(0, uint32(kinds.size() - 1))]];
    loot.AddItem(*choices[urand(0, uint32(choices.size() - 1))]);
}

void AddSupplies(Player const* player, std::list<LootStoreItem*> const& entries, uint32 count, Loot& loot)
{
    RewardPools const rewards = SortRewards(player, entries);
    std::vector<uint8> kinds;
    for (uint8 kind : { Food, Potion, Material })
        if (!rewards[kind].empty())
            kinds.push_back(kind);

    for (uint32 added = 0; added < count && !kinds.empty(); ++added)
    {
        auto const kind = kinds.begin() + urand(0, uint32(kinds.size() - 1));
        auto const& choices = rewards[*kind];
        loot.AddItem(*choices[urand(0, uint32(choices.size() - 1))]);
        kinds.erase(kind);
    }
}

void AddGear(Player const* player, std::list<LootStoreItem*> const& entries, uint32 cacheQuality, Loot& loot)
{
    std::vector<LootStoreItem*> candidates;
    std::vector<AdventurerCache::Gear> gear;
    for (LootStoreItem* entry : entries)
    {
        ItemTemplate const* item = sObjectMgr->GetItemTemplate(entry->itemid);
        if (!item || entry->reference || !IsGear(item) || player->CanUseItem(item) != EQUIP_ERR_OK ||
            (item->GetSkill() && !player->GetSkillValue(item->GetSkill())) ||
            (item->Class == ITEM_CLASS_ARMOR && !HasWearableStats(item)))
            continue;
        candidates.push_back(entry);
        gear.push_back({ item->Quality, item->RequiredLevel, BodyArmorClass(item) });
    }

    std::vector<LootStoreItem*> choices;
    for (std::size_t index : AdventurerCache::GearChoices(gear, player->GetLevel(), cacheQuality))
        choices.push_back(candidates[index]);
    if (choices.empty())
        return;

    AscensionSpecLoot::PrimaryStats const stats = AscensionSpecLoot::ActivePrimaryStats(player);
    choices = AscensionSpecLoot::PreferFit(choices, [&stats](LootStoreItem const* entry)
    {
        return GearFit(stats, sObjectMgr->GetItemTemplate(entry->itemid));
    });
    loot.AddItem(*choices[urand(0, uint32(choices.size() - 1))]);
}

void OpenCache(Player* player, Item* item)
{
    player->SendEquipError(EQUIP_ERR_NONE, item, nullptr);
    if (!player->IsAlive() || player->IsInCombat())
        return;

    Loot loot;
    loot.containerGUID = item->GetGUID();
    loot.FillLoot(item->GetEntry(), LootTemplates_Item, player, true, true);

    bool const fitAffixes = IsGearCache(item->GetEntry());
    AscensionSpecLoot::PrimaryStats const stats = AscensionSpecLoot::ActivePrimaryStats(player);
    std::vector<AscensionCacheRewards::Reward> rewards;
    uint32 const slots = loot.GetMaxSlotInLootFor(player);
    for (uint32 slot = 0; slot < slots; ++slot)
    {
        LootItem const* reward = loot.LootItemInSlot(slot, player);
        if (!reward)
            continue;
        ItemTemplate const* proto = sObjectMgr->GetItemTemplate(reward->itemid);
        if (!proto)
            continue;
        int32 const randomPropertyId = fitAffixes && IsGear(proto) ?
            FittingAffix(stats, proto, reward->randomPropertyId) : reward->randomPropertyId;
        rewards.push_back({ reward->itemid, uint16(proto->ItemLevel), uint8(5), uint8(proto->SubClass),
            uint32(reward->count ? reward->count : 1), randomPropertyId });
    }

    if (rewards.empty())
        return;

    AscensionCacheRewards::Deliver(player, rewards, item);
}

class item_ascension_adventurer_cache : public ItemScript
{
public:
    item_ascension_adventurer_cache() : ItemScript("item_ascension_adventurer_cache") { }

    bool OnUse(Player* player, Item* item, SpellCastTargets const&) override
    {
        if (!IsAdventurerReward(item->GetEntry()))
            return false;
        OpenCache(player, item);
        return true;
    }
};

class adventurer_cache_open : public ServerScript
{
public:
    adventurer_cache_open() : ServerScript("adventurer_cache_open", {SERVERHOOK_CAN_PACKET_RECEIVE}) { }

    bool CanPacketReceive(WorldSession* session, WorldPacket const& packet) override
    {
        if (packet.GetOpcode() != CMSG_OPEN_ITEM || packet.size() < 2)
            return true;
        Player* player = session ? session->GetPlayer() : nullptr;
        if (!player || player->m_mover != player)
            return true;
        Item* item = player->GetItemByPos(packet.read<uint8>(0), packet.read<uint8>(1));
        if (!item || !IsAdventurerReward(item->GetEntry()))
            return true;

        ObjectGuid const cache = item->GetGUID();
        OpenCache(player, item);
        player->SendLootRelease(cache);
        return false;
    }
};

class adventurer_cache_loot : public GlobalScript
{
public:
    adventurer_cache_loot() : GlobalScript("adventurer_cache_loot",
        {GLOBALHOOK_ON_BEFORE_LOOT_EQUAL_CHANCED}) { }

    bool OnBeforeLootEqualChanced(Player const* player, std::list<LootStoreItem*> entries,
        Loot& loot, LootStore const& store) override
    {
        if (!player || &store != &LootTemplates_Item)
            return true;
        Item const* container = player->GetItemByGuid(loot.containerGUID);
        if (container && IsHelpfulGoodsSatchel(container->GetEntry()) && IsAscensionCustomClassId(player->getClass()))
        {
            if (LootStoreItem* wearable = BestWearableEntry(player, entries))
                loot.AddItem(*wearable);
            return false;
        }
        if (!container || !IsAdventurerReward(container->GetEntry()))
            return true;

        if (!IsGearCache(container->GetEntry()))
        {
            AddSatchelReward(player, entries, loot);
            return false;
        }

        uint32 const cacheQuality = container->GetTemplate()->Quality;
        AddGear(player, entries, cacheQuality, loot);
        AddSupplies(player, entries, AdventurerCache::SupplyCount(cacheQuality), loot);
        return false;
    }
};
}

void AddSC_AscensionAdventurerCache()
{
    new item_ascension_adventurer_cache();
    new adventurer_cache_open();
    new adventurer_cache_loot();
}
