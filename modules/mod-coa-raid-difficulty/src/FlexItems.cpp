/*
 * Flex items: on every scheduled Molten Core boss kill, besides the guaranteed set tokens
 * (FlexLoot.cpp), the kill drops N random items drawn from a pool specific to that boss plus a
 * pool common to every boss. N follows the same flex raid-size band FlexHealth.cpp/FlexLoot.cpp
 * already use (coa_flex::CountPlayers, clamped 10..25): 10-14 players -> 2 items, 15-19 -> 3,
 * 20-25 -> 4 (coa_mc_item_count).
 *
 * coa_mc_item_pool holds one row per (RaidDifficulty, CreatureEntry, ItemEntry): CreatureEntry 0
 * is the common pool, read by every boss; any other value is that boss's own base entry. Both
 * pools are weighted (coa_mc_item_pool.Weight), drawn without replacement; a pool smaller than N
 * gives every item it has.
 *
 * Same GetEntry()-stays-base-entry caveat as FlexLoot.cpp: the lookup key is rebuilt from the
 * base entry plus the map's own spawn mode rather than trusting GetEntry() to already carry the
 * difficulty.
 *
 * Majordomo Executus's own kill carries no set token and no own-pool rows (he draws only the
 * common pool, FLEX_ITEM_BOSS_ENTRIES below), but his real loot vector is the Cache of the
 * Firelord gameobject (179703, instance_molten_core.cpp / go_cache_of_the_firelord_coa), not his
 * corpse. MISCHOOK_ON_AFTER_LOOT_TEMPLATE_PROCESS already fires for gameobject loot the same way
 * it does for creature loot (Loot::FillLoot -> LootTemplate::Process, store-agnostic); the chest
 * is one static spawn shared across every difficulty (its 279703/379703/479703 siblings are
 * unused template placeholders, never spawned), so its difficulty has to come from the looting
 * player's own map spawn mode rather than from the GO's entry at all.
 */

#include "FlexItems.h"

#include "Creature.h"
#include "DatabaseEnv.h"
#include "Field.h"
#include "GameObject.h"
#include "Log.h"
#include "LootMgr.h"
#include "Map.h"
#include "Player.h"
#include "QueryResult.h"
#include "Random.h"
#include "ScriptMgr.h"

#include "FlexHealth.h"

#include <algorithm>
#include <map>
#include <unordered_map>
#include <vector>

namespace
{
    struct WeightedItem
    {
        uint32 item;
        float weight;
    };

    std::map<uint32, uint32> g_itemCountByMinPlayers;
    std::unordered_map<uint32, std::unordered_map<uint32, std::vector<WeightedItem>>> g_poolByDiffAndBoss;

    // The 10 scheduled-kill base entries this mechanism covers (8 T1-token bosses, Majordomo
    // Executus, Ragnaros). Majordomo carries no own-pool rows at all (coa_mc_item_pool has no
    // CreatureEntry = 12018 rows), so he is listed here explicitly to still draw from the common
    // pool rather than being silently skipped because he never appears as an "own" pool key.
    constexpr uint32 FLEX_ITEM_BOSS_ENTRIES[] = { 11502, 11982, 11988, 12056, 12057, 12098, 12118, 12259, 12264, 12018 };

    // Majordomo's own base entry, reused as the pool key for his Cache of the Firelord chest -
    // same common-pool-only entry his own (hypothetical) corpse loot would draw from above.
    constexpr uint32 FLEX_ITEM_MAJORDOMO_ENTRY = 12018;
    constexpr uint32 GO_CACHE_OF_THE_FIRELORD = 179703;

    uint32 ItemCountForPlayers(uint32 players)
    {
        uint32 count = 0;
        for (auto const& [minPlayers, itemCount] : g_itemCountByMinPlayers)
        {
            if (players >= minPlayers)
                count = itemCount;
        }
        return count;
    }

    void LoadFlexItems()
    {
        g_itemCountByMinPlayers.clear();
        g_poolByDiffAndBoss.clear();

        if (QueryResult result = WorldDatabase.Query("SELECT MinPlayers, ItemCount FROM coa_mc_item_count"))
        {
            do
            {
                Field* f = result->Fetch();
                g_itemCountByMinPlayers[f[0].Get<uint32>()] = f[1].Get<uint32>();
            } while (result->NextRow());
        }

        std::unordered_map<uint32, std::vector<WeightedItem>> commonByDiff;
        std::unordered_map<uint32, std::unordered_map<uint32, std::vector<WeightedItem>>> ownByDiffAndBoss;

        if (QueryResult result = WorldDatabase.Query(
                "SELECT RaidDifficulty, CreatureEntry, ItemEntry, Weight FROM coa_mc_item_pool"))
        {
            do
            {
                Field* f = result->Fetch();
                uint32 const difficulty = f[0].Get<uint8>();
                uint32 const creatureEntry = f[1].Get<uint32>();
                uint32 const item = f[2].Get<uint32>();
                float const weight = f[3].Get<float>();

                if (creatureEntry == 0)
                    commonByDiff[difficulty].push_back({item, weight});
                else
                    ownByDiffAndBoss[difficulty][creatureEntry].push_back({item, weight});
            } while (result->NextRow());
        }

        for (auto const& [difficulty, commonItems] : commonByDiff)
        {
            for (uint32 bossEntry : FLEX_ITEM_BOSS_ENTRIES)
            {
                std::vector<WeightedItem> combined = commonItems;

                auto ownByBossIt = ownByDiffAndBoss.find(difficulty);
                if (ownByBossIt != ownByDiffAndBoss.end())
                {
                    auto ownIt = ownByBossIt->second.find(bossEntry);
                    if (ownIt != ownByBossIt->second.end())
                        combined.insert(combined.end(), ownIt->second.begin(), ownIt->second.end());
                }

                g_poolByDiffAndBoss[difficulty][bossEntry] = std::move(combined);
            }
        }

        LOG_INFO("server.loading", ">> Loaded {} Molten Core item pool entries", uint32(g_itemCountByMinPlayers.size()));
    }

    std::vector<uint32> DrawWithoutReplacement(std::vector<WeightedItem> pool, uint32 count)
    {
        std::vector<uint32> drawn;
        count = std::min<uint32>(count, uint32(pool.size()));

        for (uint32 i = 0; i < count; ++i)
        {
            float total = 0.0f;
            for (WeightedItem const& entry : pool)
                total += entry.weight;

            float roll = frand(0.0f, total);
            size_t pickIndex = 0;
            float cumulative = 0.0f;
            for (size_t j = 0; j < pool.size(); ++j)
            {
                cumulative += pool[j].weight;
                if (roll < cumulative)
                {
                    pickIndex = j;
                    break;
                }
            }

            drawn.push_back(pool[pickIndex].item);
            pool.erase(pool.begin() + pickIndex);
        }

        return drawn;
    }
}

namespace
{
    class coa_flex_items : public MiscScript
    {
    public:
        coa_flex_items() : MiscScript("coa_flex_items", { MISCHOOK_ON_AFTER_LOOT_TEMPLATE_PROCESS }) { }

        void OnAfterLootTemplateProcess(Loot* loot, LootTemplate const* /*tab*/, LootStore const& store,
            Player* lootOwner, bool /*personal*/, bool /*noEmptyError*/, uint16 /*lootMode*/) override
        {
            if (!loot || !lootOwner || !lootOwner->FindMap())
                return;

            uint32 baseEntry;
            if (&store == &LootTemplates_Creature)
            {
                Creature const* creature = lootOwner->GetMap()->GetCreature(loot->sourceWorldObjectGUID);
                if (!creature)
                    return;
                baseEntry = creature->GetEntry() % 100000;
            }
            else if (&store == &LootTemplates_Gameobject)
            {
                // GO_CACHE_OF_THE_FIRELORD (179703) is itself > 100000 - unlike the creature
                // offset scheme above, this is not a difficulty-encoded id, it is the one real
                // entry that ever spawns (279703/379703/479703 are unused template placeholders
                // with no gameobject spawn row at all), so compare it directly, not modulo'd.
                GameObject const* go = lootOwner->GetMap()->GetGameObject(loot->sourceWorldObjectGUID);
                if (!go || go->GetEntry() != GO_CACHE_OF_THE_FIRELORD)
                    return;
                baseEntry = FLEX_ITEM_MAJORDOMO_ENTRY;
            }
            else
                return;

            uint32 const mode = uint32(lootOwner->GetMap()->GetSpawnMode());

            auto diffIt = g_poolByDiffAndBoss.find(mode);
            if (diffIt == g_poolByDiffAndBoss.end())
                return;

            auto poolIt = diffIt->second.find(baseEntry);
            if (poolIt == diffIt->second.end() || poolIt->second.empty())
                return;

            uint32 const itemCount = ItemCountForPlayers(coa_flex::CountPlayers(lootOwner->GetMap()));
            if (!itemCount)
                return;

            for (uint32 itemId : DrawWithoutReplacement(poolIt->second, itemCount))
            {
                if (loot->items.size() >= MAX_NR_LOOT_ITEMS)
                    break;
                loot->AddItem(LootStoreItem(itemId, 0, 100.0f, false, LOOT_MODE_DEFAULT, 0, 1, 1));
            }
        }
    };

    class coa_flex_items_loader : public WorldScript
    {
    public:
        coa_flex_items_loader() : WorldScript("coa_flex_items_loader") { }

        void OnAfterConfigLoad(bool /*reload*/) override
        {
            LoadFlexItems();
        }
    };
}

void AddCoaFlexItemsScripts()
{
    new coa_flex_items();
    new coa_flex_items_loader();
}
