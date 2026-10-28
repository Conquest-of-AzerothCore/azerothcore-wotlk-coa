#include "ManastormModuleConfig.h"
#include "ManastormRewards.h"

#include "GlobalScript.h"
#include "Item.h"
#include "ItemScript.h"
#include "ItemTemplate.h"
#include "LootMgr.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Spell.h"
#include "Util.h"
#include "WorldScript.h"
#include "PlayerScript.h"
#include "WorldSession.h"
#include "WorldPacket.h"
#include "Opcodes.h"
#include "DatabaseEnv.h"
#include "Field.h"
#include "Log.h"
#include "Random.h"

#include <array>
#include <cstdint>
#include <limits>
#include <memory>
#include <atomic>
#include <string>
#include <utility>
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

    // SharedConstants.lua and C_PrimaryStat:GetActivePrimaryStat use these
    // learned allocations on both CoA and Hero realms. Live stat totals are
    // affected by gear/buffs and are not the player's selection.
    ManastormPreferredPrimaryStat ResolvePreferredPrimaryStat(
        Player const* player)
    {
        if (!player)
            return ManastormPreferredPrimaryStat::None;

        // Duality's original loot weighting has not been recovered. Use the
        // neutral pool rather than silently substituting its largest live stat.
        if (player->HasSpell(129243))
            return ManastormPreferredPrimaryStat::None;

        constexpr std::array<std::pair<uint32, ManastormPreferredPrimaryStat>, 4> Allocations =
        {{
            { 84864, ManastormPreferredPrimaryStat::Strength },
            { 84865, ManastormPreferredPrimaryStat::Agility },
            { 84866, ManastormPreferredPrimaryStat::Intellect },
            { 84867, ManastormPreferredPrimaryStat::Spirit }
        }};

        ManastormPreferredPrimaryStat selected = ManastormPreferredPrimaryStat::None;
        for (auto const& allocation : Allocations)
        {
            if (!player->HasSpell(allocation.first))
                continue;

            // Conflicting allocations cannot identify a unique preference.
            if (selected != ManastormPreferredPrimaryStat::None)
                return ManastormPreferredPrimaryStat::None;

            selected = allocation.second;
        }

        return selected;
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

    class item_manastorm_cache final :
        public ItemScript
    {
    public:
        item_manastorm_cache()
            : ItemScript(
                "item_manastorm_cache")
        {
        }

        bool OnUse(
            Player* player,
            Item* item,
            SpellCastTargets const&) override
        {
            if (player &&
                item &&
                player->IsAlive() &&
                !player->IsInCombat())
            {
                player->SendLoot(
                    item->GetGUID(),
                    LOOT_CORPSE);
            }

            return true;
        }
    };

    class manastorm_cache_loot_selector final :
        public GlobalScript
    {
    public:
        manastorm_cache_loot_selector()
            : GlobalScript(
                "manastorm_cache_loot_selector",
                {
                    GLOBALHOOK_ON_BEFORE_LOOT_EQUAL_CHANCED,
                    GLOBALHOOK_ON_AFTER_REF_COUNT
                })
        {
        }

        void OnAfterRefCount(Player const* player, LootStoreItem* entry, Loot& loot,
            bool /*canRate*/, uint16 /*lootMode*/, uint32& maxcount, LootStore const& store) override
        {
            if (!ManastormModuleConfig::Enabled() || !player || !entry || &store != &LootTemplates_Item)
                return;

            Item const* container = player->GetItemByGuid(loot.containerGUID);
            if (!container)
                return;

            bool const heroicTier = container->GetEntry() == 1278051 &&
                (entry->reference == 9003001 || entry->reference == 9003002);
            bool const mythicTier = container->GetEntry() == 1278054 &&
                (entry->reference == 9003101 || entry->reference == 9003102 || entry->reference == 9003103);
            bool const zulGurubFamily = (container->GetEntry() == 1278052 || container->GetEntry() == 1278053 ||
                container->GetEntry() == 1278055) && entry->reference >= 9003201 && entry->reference <= 9003205;
            bool const moltenCoreFamily =
                (container->GetEntry() == 1278056 && (entry->reference == 9002022 || entry->reference == 9002001 ||
                    entry->reference == 9002030)) ||
                (container->GetEntry() == 1278058 && (entry->reference == 9002001 || entry->reference == 9002002 ||
                    entry->reference == 9002030)) ||
                (container->GetEntry() == 1278060 && (entry->reference == 9002002 || entry->reference == 9002003 ||
                    entry->reference == 9002010 || entry->reference == 9002031));
            bool const laterMoltenCoreFamily =
                (container->GetEntry() == 1278061 && entry->reference == 9002040) ||
                (container->GetEntry() == 1278062 && entry->reference == 9002004) ||
                (container->GetEntry() == 1278063 && entry->reference == 9002041) ||
                (container->GetEntry() == 1278065 && entry->reference == 9002042) ||
                (container->GetEntry() == 1278067 && entry->reference == 9002043);
            bool const blackwingLairFamily = (container->GetEntry() == 1278066 || container->GetEntry() == 1278068 ||
                container->GetEntry() == 1278069) && entry->reference >= 9003401 && entry->reference <= 9003407;
            bool const ruinsOfAhnQirajFamily = (container->GetEntry() == 1278070 || container->GetEntry() == 1278072 ||
                container->GetEntry() == 1278074) && entry->reference >= 9003501 && entry->reference <= 9003506;
            bool const templeOfAhnQirajFamily = (container->GetEntry() == 1278075 || container->GetEntry() == 1278077 ||
                container->GetEntry() == 1278078) && entry->reference >= 9003601 && entry->reference <= 9003605;
            bool const naxxramasFamily = (container->GetEntry() == 1278079 || container->GetEntry() == 1278081 ||
                container->GetEntry() == 1278083) && entry->reference >= 9003701 && entry->reference <= 9003706;
            bool const rankedDungeonFamily = (container->GetEntry() == 1278059 || container->GetEntry() == 1278064 ||
                container->GetEntry() == 1278073 || container->GetEntry() == 1278082) &&
                entry->reference >= 9003801 && entry->reference <= 9003804;
            bool const ascendedRaidFamily = (container->GetEntry() == 1278057 || container->GetEntry() == 1278071 ||
                container->GetEntry() == 1278076 || container->GetEntry() == 1278080 ||
                container->GetEntry() == 1278084) && entry->reference >= 9003901 && entry->reference <= 9003905;
            if (heroicTier || mythicTier || zulGurubFamily || moltenCoreFamily || blackwingLairFamily ||
                ruinsOfAhnQirajFamily || templeOfAhnQirajFamily || naxxramasFamily || rankedDungeonFamily ||
                laterMoltenCoreFamily || ascendedRaidFamily)
                maxcount = 1; // One tier reward regardless of global reference amount rates.
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
                (&store != &LootTemplates_Item &&
                 &store != &LootTemplates_Reference))
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
    struct MaterialCandidate
    {
        uint32 ItemEntry = 0;
        uint32 Weight = 0;
        uint8 MinCount = 1;
        uint8 MaxCount = 5;
    };

    struct MaterialCategory
    {
        std::string Name;
        uint32 TotalWeight = 0;
        std::vector<MaterialCandidate> Items;
    };

    using MaterialPools = std::vector<MaterialCategory>;
    std::shared_ptr<MaterialPools const> MaterialCachePools;

    void LoadMaterialCachePools()
    {
        auto pools = std::make_shared<MaterialPools>();
        QueryResult result = WorldDatabase.Query(
            "SELECT category, item_entry, weight, min_count, max_count "
            "FROM manastorm_material_cache_pool WHERE enabled = 1 ORDER BY category, item_entry");
        bool valid = bool(result);
        if (result)
        {
            do
            {
                Field* fields = result->Fetch();
                std::string const category = fields[0].Get<std::string>();
                uint32 const entry = fields[1].Get<uint32>();
                uint32 const weight = fields[2].Get<uint32>();
                uint8 const minimum = fields[3].Get<uint8>();
                uint8 const maximum = fields[4].Get<uint8>();
                if (category.empty() || !weight || !minimum || minimum > maximum ||
                    !sObjectMgr->GetItemTemplate(entry))
                {
                    valid = false;
                    break;
                }

                if (pools->empty() || pools->back().Name != category)
                    pools->push_back({category, 0, {}});

                MaterialCategory& pool = pools->back();
                if (uint64(pool.TotalWeight) + weight > std::numeric_limits<uint32>::max())
                {
                    valid = false;
                    break;
                }

                pool.TotalWeight += weight;
                pool.Items.push_back({entry, weight, minimum, maximum});
            }
            while (result->NextRow());
        }

        std::shared_ptr<MaterialPools const> loaded;
        if (valid && pools->size() >= 3)
            loaded = pools;
        else
            LOG_ERROR("module.manastorm.endless.rewards",
                "Material cache 1478051 disabled: apply SQL 42 and configure at least three valid categories.");

        std::atomic_store(&MaterialCachePools, loaded);
    }

    class manastorm_material_cache_loader final : public WorldScript
    {
    public:
        manastorm_material_cache_loader() : WorldScript("manastorm_material_cache_loader",
            {WORLDHOOK_ON_STARTUP, WORLDHOOK_ON_AFTER_CONFIG_LOAD}) { }

        void OnStartup() override { LoadMaterialCachePools(); }

        void OnAfterConfigLoad(bool reload) override
        {
            if (reload)
                LoadMaterialCachePools();
        }
    };

    class manastorm_material_cache_selector final : public GlobalScript
    {
    public:
        manastorm_material_cache_selector() : GlobalScript("manastorm_material_cache_selector",
            {GLOBALHOOK_ON_BEFORE_LOOT_EQUAL_CHANCED}) { }

        bool OnBeforeLootEqualChanced(Player const* player, std::list<LootStoreItem*> /*entries*/,
            Loot& loot, LootStore const& store) override
        {
            if (!player || &store != &LootTemplates_Item)
                return true;

            Item const* container = player->GetItemByGuid(loot.containerGUID);
            if (!container || container->GetEntry() != 1478051)
                return true;

            auto pools = std::atomic_load(&MaterialCachePools);
            if (!ManastormModuleConfig::Enabled() || !pools || pools->size() < 3)
                return false;

            // Sample category indices without replacement; all categories are
            // equally likely. Item weights are relative within each category.
            std::vector<uint32> available;
            available.reserve(pools->size());
            for (uint32 index = 0; index < pools->size(); ++index)
                available.push_back(index);

            for (uint32 draw = 0; draw < 3; ++draw)
            {
                uint32 const index = urand(0, uint32(available.size() - 1));
                MaterialCategory const& category = (*pools)[available[index]];
                available[index] = available.back();
                available.pop_back();

                uint32 roll = urand(1, category.TotalWeight);
                for (MaterialCandidate const& candidate : category.Items)
                {
                    if (roll > candidate.Weight)
                    {
                        roll -= candidate.Weight;
                        continue;
                    }

                    LootStoreItem selected(candidate.ItemEntry, 0, 100.0f, false,
                        LOOT_MODE_DEFAULT, 0, candidate.MinCount, candidate.MaxCount);
                    loot.AddItem(selected);
                    break;
                }
            }

            return false;
        }
    };

    class item_manastorm_bonus_cache final : public ItemScript
    {
    public:
        item_manastorm_bonus_cache() : ItemScript("item_manastorm_bonus_cache") { }

        bool OnUse(Player* player, Item* item, SpellCastTargets const&) override
        {
            return OpenCache(player, item);
        }

        static bool OpenCache(Player* player, Item* item)
        {
            if (!player || !item || (item->GetEntry() != 1478051 && item->GetEntry() != 1478052) ||
                !player->GetSession() || !player->IsAlive() || player->IsInCombat())
                return true;

            if (!ManastormModuleConfig::Enabled() ||
                (item->GetEntry() == 1478051 && !std::atomic_load(&MaterialCachePools)))
            {
                player->SendSystemMessage("This cache's rewards are unavailable. The cache was not consumed.");
                return true;
            }

            ObjectGuid const guid = item->GetGUID();
            WorldSession* session = player->GetSession();
            player->SendLoot(guid, LOOT_CORPSE);
            if (player->GetLootGUID() != guid)
                return true;

            // Use normal loot handlers for persistence, capacity checks and
            // item-push notifications. The scoped core fallback mails full-bag
            // Bonus Cache rewards through its existing item-retrieval path.
            uint8 const slotCount = uint8(item->loot.items.size());
            for (uint8 slot = 0; slot < slotCount && player->GetLootGUID() == guid; ++slot)
            {
                WorldPacket take(CMSG_AUTOSTORE_LOOT_ITEM, 1);
                take << slot;
                session->HandleAutostoreLootItemOpcode(take);
            }

            WorldPacket money(CMSG_LOOT_MONEY, 0);
            session->HandleLootMoneyOpcode(money);
            WorldPacket release(CMSG_LOOT_RELEASE, 8);
            release << guid;
            session->HandleLootReleaseOpcode(release);
            return true;
        }
    };

    class manastorm_bonus_cache_open final : public PlayerScript
    {
    public:
        manastorm_bonus_cache_open() : PlayerScript("manastorm_bonus_cache_open",
            {PLAYERHOOK_ON_BEFORE_OPEN_ITEM}) { }

        bool OnPlayerBeforeOpenItem(Player* player, Item* item) override
        {
            if (!item || (item->GetEntry() != 1478051 && item->GetEntry() != 1478052))
                return true;

            // Container opens bypass ItemScript::OnUse in the native core.
            // Reuse the same delivery path and prevent a second SendLoot call.
            item_manastorm_bonus_cache::OpenCache(player, item);
            return false;
        }
    };

}

void AddSC_manastorm_cache_loot()
{
    new item_manastorm_cache();
    new manastorm_material_cache_loader();
    new manastorm_material_cache_selector();
    new item_manastorm_bonus_cache();
    new manastorm_bonus_cache_open();
    new manastorm_cache_loot_selector();
}
