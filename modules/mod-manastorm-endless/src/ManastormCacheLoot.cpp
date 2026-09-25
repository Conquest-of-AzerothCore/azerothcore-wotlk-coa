#include "ManastormModuleConfig.h"
#include "ManastormRewards.h"

#include "GlobalScript.h"
#include "Item.h"
#include "ItemTemplate.h"
#include "LootMgr.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Util.h"

#include <array>
#include <cstdint>
#include <limits>
#include <vector>

namespace
{
    enum class ManastormPreferredPrimaryStat : uint8
    {
        None = 0,
        Strength,
        Agility,
        Intellect,
        Spirit
    };

    struct PrimaryStatCandidate
    {
        ManastormPreferredPrimaryStat Preference;
        Stats Stat;
    };

    constexpr std::array<PrimaryStatCandidate, 4> PrimaryStats =
    {{
        { ManastormPreferredPrimaryStat::Strength, STAT_STRENGTH },
        { ManastormPreferredPrimaryStat::Agility, STAT_AGILITY },
        { ManastormPreferredPrimaryStat::Intellect, STAT_INTELLECT },
        { ManastormPreferredPrimaryStat::Spirit, STAT_SPIRIT }
    }};

    ManastormPreferredPrimaryStat ResolvePreferredPrimaryStat(
        Player const* player)
    {
        if (!player)
            return ManastormPreferredPrimaryStat::None;

        uint32 bestValue = 0;
        ManastormPreferredPrimaryStat best =
            ManastormPreferredPrimaryStat::None;
        bool tied = false;

        for (PrimaryStatCandidate const& candidate :
            PrimaryStats)
        {
            uint32 const value =
                uint32(player->GetStat(candidate.Stat));

            if (value > bestValue)
            {
                bestValue = value;
                best = candidate.Preference;
                tied = false;
            }
            else if (value == bestValue &&
                value != 0)
            {
                tied = true;
            }
        }

        if (!bestValue ||
            tied)
        {
            return ManastormPreferredPrimaryStat::None;
        }

        return best;
    }

    ItemModType ToItemMod(
        ManastormPreferredPrimaryStat preference)
    {
        switch (preference)
        {
        case ManastormPreferredPrimaryStat::Strength:
            return ITEM_MOD_STRENGTH;
        case ManastormPreferredPrimaryStat::Agility:
            return ITEM_MOD_AGILITY;
        case ManastormPreferredPrimaryStat::Intellect:
            return ITEM_MOD_INTELLECT;
        case ManastormPreferredPrimaryStat::Spirit:
            return ITEM_MOD_SPIRIT;
        case ManastormPreferredPrimaryStat::None:
        default:
            return ITEM_MOD_STAMINA;
        }
    }

    uint32 GetItemPrimaryStatAmount(
        ItemTemplate const* item,
        ItemModType stat)
    {
        if (!item)
            return 0;

        uint32 amount = 0;

        for (uint32 index = 0;
            index < item->StatsCount &&
            index < MAX_ITEM_PROTO_STATS;
            ++index)
        {
            if (item->ItemStat[index].ItemStatType !=
                uint32(stat))
            {
                continue;
            }

            int32 const value =
                item->ItemStat[index].ItemStatValue;

            if (value > 0)
                amount += uint32(value);
        }

        return amount;
    }

    uint32 GetCandidateWeight(
        ItemTemplate const* item,
        ManastormPreferredPrimaryStat preference)
    {
        constexpr uint32 NeutralWeight = 100;
        constexpr uint32 OffStatWeight = 25;
        constexpr uint32 MatchingBonus = 400;

        if (!item ||
            preference ==
                ManastormPreferredPrimaryStat::None)
        {
            return NeutralWeight;
        }

        uint32 const strength =
            GetItemPrimaryStatAmount(
                item,
                ITEM_MOD_STRENGTH);

        uint32 const agility =
            GetItemPrimaryStatAmount(
                item,
                ITEM_MOD_AGILITY);

        uint32 const intellect =
            GetItemPrimaryStatAmount(
                item,
                ITEM_MOD_INTELLECT);

        uint32 const spirit =
            GetItemPrimaryStatAmount(
                item,
                ITEM_MOD_SPIRIT);

        uint32 const totalPrimary =
            strength +
            agility +
            intellect +
            spirit;

        if (!totalPrimary)
            return NeutralWeight;

        uint32 desired = 0;

        switch (preference)
        {
        case ManastormPreferredPrimaryStat::Strength:
            desired = strength;
            break;
        case ManastormPreferredPrimaryStat::Agility:
            desired = agility;
            break;
        case ManastormPreferredPrimaryStat::Intellect:
            desired = intellect;
            break;
        case ManastormPreferredPrimaryStat::Spirit:
            desired = spirit;
            break;
        case ManastormPreferredPrimaryStat::None:
        default:
            break;
        }

        if (!desired)
            return OffStatWeight;

        return NeutralWeight +
            uint32(
                (uint64(desired) *
                    MatchingBonus) /
                totalPrimary);
    }

    bool IsPersonalizedGearCandidate(
        ItemTemplate const* item)
    {
        if (!item ||
            !item->InventoryType)
        {
            return false;
        }

        return
            item->Class == ITEM_CLASS_WEAPON ||
            item->Class == ITEM_CLASS_ARMOR;
    }

    struct WeightedLootCandidate
    {
        LootStoreItem* Entry = nullptr;
        uint32 Weight = 0;
    };

    class manastorm_cache_loot_selector final :
        public GlobalScript
    {
    public:
        manastorm_cache_loot_selector()
            : GlobalScript(
                "manastorm_cache_loot_selector",
                {
                    GLOBALHOOK_ON_BEFORE_LOOT_EQUAL_CHANCED
                })
        {
        }

        bool OnBeforeLootEqualChanced(
            Player const* player,
            std::list<LootStoreItem*> entries,
            Loot& loot,
            LootStore const& store) override
        {
            if (!ManastormModuleConfig::Enabled() ||
                !player ||
                entries.empty() ||
                &store != &LootTemplates_Reference)
            {
                return true;
            }

            Item const* container =
                player->GetItemByGuid(
                    loot.containerGUID);

            if (!container ||
                !ManastormRewards::Instance()
                    .IsCacheItemEntry(
                        container->GetEntry()))
            {
                return true;
            }

            ManastormPreferredPrimaryStat const preference =
                ResolvePreferredPrimaryStat(
                    player);

            std::vector<WeightedLootCandidate>
                candidates;

            uint64 totalWeight = 0;

            for (LootStoreItem* entry :
                entries)
            {
                if (!entry ||
                    entry->reference ||
                    !entry->conditions.empty())
                {
                    return true;
                }

                ItemTemplate const* item =
                    sObjectMgr->GetItemTemplate(
                        entry->itemid);

                //
                // Only take ownership of pure equippable-gear leaf pools.
                // Non-gear references remain ordinary AzerothCore loot.
                //
                if (!IsPersonalizedGearCandidate(
                    item))
                {
                    return true;
                }

                uint32 const weight =
                    GetCandidateWeight(
                        item,
                        preference);

                candidates.push_back(
                    {
                        entry,
                        weight
                    });

                totalWeight += weight;
            }

            if (candidates.empty() ||
                !totalWeight ||
                totalWeight >
                    std::numeric_limits<uint32>::max())
            {
                return true;
            }

            uint32 roll =
                urand(
                    1,
                    uint32(totalWeight));

            LootStoreItem* selected = nullptr;

            for (WeightedLootCandidate const& candidate :
                candidates)
            {
                if (roll <= candidate.Weight)
                {
                    selected =
                        candidate.Entry;

                    break;
                }

                roll -=
                    candidate.Weight;
            }

            if (!selected)
                selected = candidates.back().Entry;

            loot.AddItem(
                *selected);

            //
            // We have supplied the personalized winner. Returning false stops
            // the core from blindly selecting another equal-chance candidate.
            //
            return false;
        }
    };
}

void AddSC_manastorm_cache_loot()
{
    new manastorm_cache_loot_selector();
}
