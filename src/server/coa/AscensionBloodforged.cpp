/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionBloodforgedPolicy.h"
#include "ConditionMgr.h"
#include "Config.h"
#include "Creature.h"
#include "Formulas.h"
#include "Group.h"
#include "DatabaseEnv.h"
#include "Log.h"
#include "LootMgr.h"
#include "Map.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "World.h"
#include "WorldSession.h"
#include <algorithm>
#include <atomic>
#include <cmath>
#include <memory>
#include <set>
#include <sstream>
#include <vector>

namespace Bloodforged
{
constexpr uint32 HighRiskAura = 1004019;
using Pools = std::array<std::array<std::vector<uint32>, 3>, 61>;

struct Settings
{
    std::array<Rates, 5> rates = DefaultRates;
    std::array<std::unique_ptr<LootTemplate>, 61> templates;
    bool enabled = false;
};

std::shared_ptr<Settings const> settings;

Condition riskCondition = []
{
    Condition condition;
    condition.ConditionType = CONDITION_AURA;
    condition.ConditionValue1 = HighRiskAura;
    return condition;
}();

Condition levelCondition = []
{
    Condition condition;
    condition.ConditionType = CONDITION_LEVEL;
    condition.ConditionValue1 = 15;
    condition.ConditionValue2 = COMP_TYPE_HIGH_EQ;
    return condition;
}();

bool EligiblePlayer(Player const* player, Creature const* creature)
{
    return player && player->GetSession() && !player->GetSession()->IsBot()
        && player->GetLevel() >= 15 && player->HasAura(HighRiskAura)
        && player->IsAtLootRewardDistance(creature)
        && creature->GetLevel() > Acore::XP::GetGrayLevel(player->GetLevel());
}

class Configuration : public WorldScript
{
public:
    Configuration() : WorldScript("BloodforgedConfiguration") { }

    void OnStartup() override { Load(); }

    void OnAfterConfigLoad(bool reload) override
    {
        if (reload)
            Load();
    }

private:
    static void Load()
    {
        auto next = std::make_shared<Settings>();
        std::atomic_store(&settings, std::make_shared<Settings const>());
        if (!sConfigMgr->GetOption<bool>("Bloodforged.Enable", false))
            return;
        if (!sConfigMgr->GetOption<bool>("PvpPower.Enable", true))
        {
            LOG_ERROR("server.loading", "Bloodforged disabled: PvP Power support must be enabled first");
            return;
        }

        for (unsigned band = 0; band < next->rates.size(); ++band)
        {
            std::string key = "Bloodforged.Rates" + std::to_string(15 + band * 10);
            std::string value = sConfigMgr->GetOption<std::string>(key, "");
            if (value.empty())
                continue;
            std::istringstream input(value);
            double green, blue, purple;
            std::string extra;
            if (!(input >> green >> blue >> purple) || input >> extra
                || !std::isfinite(green) || !std::isfinite(blue) || !std::isfinite(purple)
                || green < 0 || green > 100 || blue < 0 || blue > 100 || purple < 0 || purple > 100)
            {
                LOG_ERROR("server.loading", "Bloodforged disabled: invalid rates in {}", key);
                return;
            }
            next->rates[band] = {unsigned(std::lround(green * 100)), unsigned(std::lround(blue * 100)),
                unsigned(std::lround(purple * 100))};
            if (!ValidRates(next->rates[band]))
            {
                LOG_ERROR("server.loading", "Bloodforged disabled: invalid rarity order in {}", key);
                return;
            }
        }

        Pools pools;
        std::set<uint32> entries;
        QueryResult catalogue = WorldDatabase.Query(
            "SELECT entry,quality,required_level,item_level FROM coa_bloodforged_catalogue");
        if (!catalogue)
        {
            LOG_ERROR("server.loading", "Bloodforged disabled: coa_bloodforged_catalogue is empty or missing");
            return;
        }
        do
        {
            Field* fields = catalogue->Fetch();
            uint32 entry = fields[0].Get<uint32>();
            uint32 quality = fields[1].Get<uint32>();
            uint32 requiredLevel = fields[2].Get<uint32>();
            uint32 itemLevel = fields[3].Get<uint32>();
            auto const* item = sObjectMgr->GetItemTemplate(entry);
            if (!item || !entries.insert(entry).second || quality < 2 || quality > 4
                || item->Quality != quality || item->RequiredLevel != requiredLevel
                || item->ItemLevel != itemLevel || requiredLevel > 60
                || (item->Class != ITEM_CLASS_WEAPON && item->Class != ITEM_CLASS_ARMOR)
                || item->HasFlag(ITEM_FLAG_MULTI_DROP) || item->StartQuest)
            {
                LOG_ERROR("server.loading", "Bloodforged disabled: template mismatch for {}", entry);
                return;
            }
            for (unsigned level = 15; level <= 60; ++level)
                if (EligibleItem(requiredLevel, itemLevel, level))
                    pools[level][quality - 2].push_back(entry);
        } while (catalogue->NextRow());
        if (entries.empty())
        {
            LOG_ERROR("server.loading", "Bloodforged disabled: empty or incomplete catalogue");
            return;
        }
        for (unsigned level = 15; level <= 60; ++level)
            for (auto& pool : pools[level])
            {
                uint32 highest = 0;
                for (uint32 entry : pool)
                    highest = std::max(highest, sObjectMgr->GetItemTemplate(entry)->ItemLevel);
                std::erase_if(pool, [highest, level](uint32 entry)
                {
                    return !InGearTier(sObjectMgr->GetItemTemplate(entry)->ItemLevel, level, highest);
                });
            }
        for (unsigned level = 15; level <= 60; ++level)
            if (pools[level][0].empty() || pools[level][1].empty())
            {
                LOG_ERROR("server.loading", "Bloodforged disabled: green/blue pool missing at level {}", level);
                return;
            }
        for (unsigned level = 15; level <= 60; ++level)
        {
            auto entriesForLevel = std::make_unique<LootTemplate>();
            for (unsigned index = 0; index < 3; ++index)
            {
                unsigned rate = next->rates[Band(level)][index];
                auto const& pool = pools[level][index];
                if (!rate || pool.empty())
                    continue;
                for (uint32 entry : pool)
                {
                    auto* item = new LootStoreItem(entry, 0, EntryChance(rate, pool.size()), false,
                        LOOT_MODE_DEFAULT, index + 1, 1, 1);
                    item->conditions = { &riskCondition, &levelCondition };
                    entriesForLevel->AddEntry(item);
                }
            }
            next->templates[level] = std::move(entriesForLevel);
        }
        next->enabled = true;
        std::atomic_store(&settings, std::shared_ptr<Settings const>(next));
        LOG_INFO("server.loading", "Bloodforged world drops ready: {} verified catalogue entries", entries.size());
    }
};

class WorldDrops : public MiscScript
{
public:
    WorldDrops() : MiscScript("BloodforgedWorldDrops", { MISCHOOK_ON_AFTER_LOOT_TEMPLATE_PROCESS }) { }

    void OnAfterLootTemplateProcess(Loot* loot, LootTemplate const*, LootStore const& store,
        Player* owner, bool personal, bool, uint16 lootMode) override
    {
        auto current = std::atomic_load(&settings);
        if (!current || !current->enabled || !owner || !loot || personal
            || &store != &LootTemplates_Creature || !(lootMode & LOOT_MODE_DEFAULT)
            || !owner->GetMap() || owner->GetMap()->Instanceable())
            return;

        auto* creature = owner->GetMap()->GetCreature(loot->sourceWorldObjectGUID);
        if (!creature || !creature->GetSpawnId() || creature->IsPet()
            || creature->IsSummon() || creature->GetCharmerOrOwnerGUID()
            || creature->GetCreatureType() == CREATURE_TYPE_CRITTER)
            return;

        Player* eligibleOwner = EligiblePlayer(owner, creature) ? owner : nullptr;
        if (!eligibleOwner)
            if (Group* group = owner->GetGroup())
                for (auto* reference = group->GetFirstMember(); reference; reference = reference->next())
                    if (EligiblePlayer(reference->GetSource(), creature))
                    {
                        eligibleOwner = reference->GetSource();
                        break;
                    }
        if (!eligibleOwner)
            return;

        unsigned targetLevel = std::clamp<unsigned>(eligibleOwner->GetLevel(), 15, 60);
        current->templates[targetLevel]->Process(*loot, store, lootMode, eligibleOwner);
    }
};

class NativeRates : public GlobalScript
{
public:
    NativeRates() : GlobalScript("BloodforgedNativeRates", { GLOBALHOOK_ON_ITEM_ROLL }) { }

    bool OnItemRoll(Player const*, LootStoreItem const* item, float& chance, Loot&, LootStore const& store) override
    {
        if (&store != &LootTemplates_Creature || item->conditions.empty() || item->conditions.front() != &riskCondition)
            return true;
        auto const* proto = sObjectMgr->GetItemTemplate(item->itemid);
        if (proto && proto->Quality >= ITEM_QUALITY_UNCOMMON && proto->Quality <= ITEM_QUALITY_EPIC)
            chance *= sWorld->getRate(QualityRates[proto->Quality - ITEM_QUALITY_UNCOMMON]);
        return true;
    }

private:
    static constexpr std::array<ServerConfigs, 3> QualityRates =
        { RATE_DROP_ITEM_UNCOMMON, RATE_DROP_ITEM_RARE, RATE_DROP_ITEM_EPIC };
};
}

void AddSC_AscensionBloodforged()
{
    new Bloodforged::Configuration();
    new Bloodforged::WorldDrops();
    new Bloodforged::NativeRates();
}
