/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "Creature.h"
#include "DatabaseEnv.h"
#include "Field.h"
#include "QueryResult.h"
#include "Log.h"
#include "Map.h"
#include "SpellInfo.h"
#include "UnitScript.h"
#include "WorldScript.h"
#include <algorithm>
#include <unordered_map>
#include <unordered_set>

namespace
{
    std::unordered_map<uint32, float> Multipliers;
    std::unordered_set<uint32> Bosses;
    std::unordered_map<uint32, float> CreatureMultipliers;
    std::unordered_map<uint32, float> HealShares;

    constexpr int32 TrashCapHeroic = 460;
    constexpr int32 TrashCapMythic = 600;

    int32 TrashCap(Unit const* attacker, SpellInfo const* spellInfo)
    {
        if (!attacker || !spellInfo || Multipliers.count(spellInfo->Id))
            return 0;
        Creature const* creature = attacker->ToCreature();
        if (!creature || creature->GetCharmerOrOwnerPlayerOrPlayerItself() || creature->IsSummon() || Bosses.count(creature->GetEntry()))
            return 0;
        Map const* map = creature->GetMap();
        if (!map || !map->IsNonRaidDungeon() || map->GetDifficulty() == DUNGEON_DIFFICULTY_NORMAL)
            return 0;
        return map->GetDifficulty() == DUNGEON_DIFFICULTY_HEROIC ? TrashCapHeroic : TrashCapMythic;
    }

    float Multiplier(Unit const* attacker, SpellInfo const* spellInfo)
    {
        if (Multipliers.empty() || !attacker || !spellInfo)
            return 1.0f;
        Creature const* creature = attacker->ToCreature();
        if (!creature || creature->GetCharmerOrOwnerPlayerOrPlayerItself())
            return 1.0f;
        Map const* map = creature->GetMap();
        if (!map || !map->IsDungeon() || map->GetDifficulty() == DUNGEON_DIFFICULTY_NORMAL)
            return 1.0f;
        auto itr = Multipliers.find(spellInfo->Id);
        return itr == Multipliers.end() ? 1.0f : itr->second;
    }

    float CreatureMultiplier(Unit const* attacker)
    {
        if (CreatureMultipliers.empty() || !attacker)
            return 1.0f;
        Creature const* creature = attacker->ToCreature();
        if (!creature || creature->GetCharmerOrOwnerPlayerOrPlayerItself())
            return 1.0f;
        Map const* map = creature->GetMap();
        if (!map || !map->IsDungeon())
            return 1.0f;
        auto itr = CreatureMultipliers.find(creature->GetEntry());
        return itr == CreatureMultipliers.end() ? 1.0f : itr->second;
    }
}

class CoADungeonSpellDamageWorld final : public WorldScript
{
public:
    CoADungeonSpellDamageWorld() : WorldScript("CoADungeonSpellDamageWorld", { WORLDHOOK_ON_STARTUP }) { }

    void OnStartup() override
    {
        Multipliers.clear();
        if (QueryResult result = WorldDatabase.Query("SELECT spell_id, multiplier FROM coa_dungeon_spell_damage"))
        {
            do
            {
                Field* fields = result->Fetch();
                Multipliers[fields[0].Get<uint32>()] = fields[1].Get<float>();
            } while (result->NextRow());
        }
        LOG_INFO("server.loading", ">> Loaded {} CoA dungeon spell damage multipliers", Multipliers.size());
        Bosses.clear();
        if (QueryResult result = WorldDatabase.Query("SELECT entry FROM coa_dungeon_bosses"))
        {
            do
            {
                Bosses.insert(result->Fetch()[0].Get<uint32>());
            } while (result->NextRow());
        }
        LOG_INFO("server.loading", ">> Loaded {} CoA dungeon boss entries (trash spell cap exempt)", Bosses.size());
        CreatureMultipliers.clear();
        if (QueryResult result = WorldDatabase.Query("SELECT entry, multiplier FROM coa_dungeon_creature_damage"))
        {
            do
            {
                Field* fields = result->Fetch();
                CreatureMultipliers[fields[0].Get<uint32>()] = fields[1].Get<float>();
            } while (result->NextRow());
        }
        LOG_INFO("server.loading", ">> Loaded {} CoA dungeon creature damage multipliers", CreatureMultipliers.size());
        HealShares.clear();
        if (QueryResult result = WorldDatabase.Query("SELECT entry, heal_pct FROM coa_dungeon_creature_heal"))
        {
            do
            {
                Field* fields = result->Fetch();
                HealShares[fields[0].Get<uint32>()] = fields[1].Get<float>();
            } while (result->NextRow());
        }
        LOG_INFO("server.loading", ">> Loaded {} CoA dungeon creature heal shares", HealShares.size());
    }
};

class CoADungeonSpellDamage final : public UnitScript
{
public:
    CoADungeonSpellDamage() : UnitScript("CoADungeonSpellDamage", true,
        { UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN, UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK, UNITHOOK_MODIFY_MELEE_DAMAGE, UNITHOOK_MODIFY_HEAL_RECEIVED }) { }

    void ModifyHealReceived(Unit* healer, Unit* receiver, uint32& gain, SpellInfo const*) override
    {
        if (HealShares.empty() || !healer || !receiver)
            return;
        Creature const* creature = healer->ToCreature();
        if (!creature || creature->GetCharmerOrOwnerPlayerOrPlayerItself() || !creature->GetMap() || !creature->GetMap()->IsDungeon())
            return;
        auto itr = HealShares.find(creature->GetEntry());
        if (itr == HealShares.end())
            return;
        gain = uint32(receiver->GetMaxHealth() * itr->second);
    }

    void ModifyMeleeDamage(Unit*, Unit* attacker, uint32& damage) override
    {
        if (float multiplier = CreatureMultiplier(attacker); multiplier != 1.0f)
            damage = uint32(damage * multiplier);
    }

    void ModifySpellDamageTaken(Unit*, Unit* attacker, int32& damage, SpellInfo const* spellInfo) override
    {
        if (float multiplier = Multiplier(attacker, spellInfo) * CreatureMultiplier(attacker); multiplier != 1.0f)
            damage = int32(damage * multiplier);
        if (int32 cap = TrashCap(attacker, spellInfo); cap && damage > cap)
            damage = cap + (damage - cap) / 20;
    }

    void ModifyPeriodicDamageAurasTick(Unit*, Unit* attacker, uint32& damage, SpellInfo const* spellInfo) override
    {
        if (float multiplier = Multiplier(attacker, spellInfo) * CreatureMultiplier(attacker); multiplier != 1.0f)
            damage = uint32(damage * multiplier);
    }
};

void AddSC_CoADungeonSpellDamage()
{
    new CoADungeonSpellDamageWorld();
    new CoADungeonSpellDamage();
}
