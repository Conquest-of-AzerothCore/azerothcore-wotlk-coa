/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "AllCreatureScript.h"
#include "Creature.h"
#include "CreatureAI.h"
#include "DatabaseEnv.h"
#include "DataMap.h"
#include "Field.h"
#include "Log.h"
#include "Map.h"
#include "QueryResult.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "WorldScript.h"
#include <unordered_map>
#include <vector>

namespace
{
    enum KitEvent : uint8
    {
        KIT_TIMER = 0,
        KIT_HEALTH = 2,
        KIT_PULL = 4,
    };

    enum KitTarget : uint8
    {
        KIT_TARGET_SELF = 1,
        KIT_TARGET_VICTIM = 2,
        KIT_TARGET_RANDOM = 5,
        KIT_TARGET_RANDOM_NOT_TANK = 6,
        KIT_TARGET_FARTHEST = 7,
    };

    enum KitCastFlags : uint8
    {
        KIT_CAST_INTERRUPT = 0x01,
        KIT_CAST_TRIGGERED = 0x02,
        KIT_CAST_AURA_NOT_PRESENT = 0x20,
    };

    constexpr uint8 KIT_ONLY_HEROIC = 0x04;
    constexpr uint8 KIT_ONLY_MYTHIC = 0x08;

    struct KitEntry
    {
        uint32 spell = 0;
        uint8 event = KIT_TIMER;
        uint8 difficulty = 0;
        uint32 initialMin = 0, initialMax = 0, repeatMin = 0, repeatMax = 0;
        uint8 healthPct = 0;
        uint8 target = KIT_TARGET_VICTIM;
        uint8 castFlags = 0;
        int32 basePoints = 0;
    };

    std::unordered_map<uint32, std::vector<KitEntry>> Kits;

    struct KitState : public DataMap::Base
    {
        bool running = false;
        std::vector<int32> timers;
    };

    uint32 KitRoll(uint32 lo, uint32 hi)
    {
        return hi > lo ? urand(lo, hi) : lo;
    }

    Unit* SelectKitTarget(Creature* me, KitEntry const& kit)
    {
        switch (kit.target)
        {
            case KIT_TARGET_SELF:
                return me;
            case KIT_TARGET_RANDOM:
                return me->AI()->SelectTarget(SelectTargetMethod::Random, 0, 0.0f, true);
            case KIT_TARGET_RANDOM_NOT_TANK:
                if (Unit* target = me->AI()->SelectTarget(SelectTargetMethod::Random, 1, 0.0f, true))
                    return target;
                return me->GetVictim();
            case KIT_TARGET_FARTHEST:
                if (Unit* target = me->AI()->SelectTarget(SelectTargetMethod::MaxDistance, 0, 0.0f, true))
                    return target;
                return me->GetVictim();
            default:
                return me->GetVictim();
        }
    }

    bool CastKit(Creature* me, KitEntry const& kit)
    {
        SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(kit.spell);
        if (!spellInfo)
            return true;
        bool triggered = kit.castFlags & KIT_CAST_TRIGGERED;
        if (!triggered && me->HasUnitState(UNIT_STATE_CASTING) && !(kit.castFlags & KIT_CAST_INTERRUPT))
            return false;
        Unit* target = SelectKitTarget(me, kit);
        if (!target)
            return false;
        if ((kit.castFlags & KIT_CAST_AURA_NOT_PRESENT) && target->HasAura(kit.spell))
            return true;
        if (kit.castFlags & KIT_CAST_INTERRUPT)
            me->InterruptNonMeleeSpells(false);
        SpellCastResult result;
        if (kit.basePoints)
        {
            CustomSpellValues values;
            values.AddSpellMod(SPELLVALUE_BASE_POINT0, kit.basePoints);
            result = me->CastCustomSpell(spellInfo, values, target, triggered ? TRIGGERED_FULL_MASK : TRIGGERED_NONE);
        }
        else
            result = me->CastSpell(target, kit.spell, triggered ? TRIGGERED_FULL_MASK : TRIGGERED_NONE);
        return result != SPELL_FAILED_SPELL_IN_PROGRESS && result != SPELL_FAILED_NOT_READY;
    }
}

class CoADungeonBossKitWorld final : public WorldScript
{
public:
    CoADungeonBossKitWorld() : WorldScript("CoADungeonBossKitWorld", { WORLDHOOK_ON_STARTUP }) { }

    void OnStartup() override
    {
        Kits.clear();
        uint32 count = 0;
        if (QueryResult result = WorldDatabase.Query("SELECT entry, spell, event, difficulty, initial_min, initial_max, repeat_min, "
            "repeat_max, health_pct, target, cast_flags, base_points FROM coa_dungeon_boss_kit ORDER BY entry, id"))
        {
            do
            {
                Field* f = result->Fetch();
                KitEntry kit;
                kit.spell = f[1].Get<uint32>();
                kit.event = f[2].Get<uint8>();
                kit.difficulty = f[3].Get<uint8>();
                kit.initialMin = f[4].Get<uint32>();
                kit.initialMax = f[5].Get<uint32>();
                kit.repeatMin = f[6].Get<uint32>();
                kit.repeatMax = f[7].Get<uint32>();
                kit.healthPct = f[8].Get<uint8>();
                kit.target = f[9].Get<uint8>();
                kit.castFlags = f[10].Get<uint8>();
                kit.basePoints = f[11].Get<int32>();
                Kits[f[0].Get<uint32>()].push_back(kit);
                ++count;
            } while (result->NextRow());
        }
        LOG_INFO("server.loading", ">> Loaded {} CoA dungeon boss kit rows for {} scripted bosses", count, Kits.size());
    }
};

class CoADungeonBossKit final : public AllCreatureScript
{
public:
    CoADungeonBossKit() : AllCreatureScript("CoADungeonBossKit") { }

    void OnAllCreatureUpdate(Creature* me, uint32 diff) override
    {
        if (Kits.empty())
            return;
        auto itr = Kits.find(me->GetEntry());
        if (itr == Kits.end())
            return;
        Map const* map = me->GetMap();
        if (!map || !map->IsNonRaidDungeon() || me->IsCharmedOwnedByPlayerOrPlayer())
            return;

        std::vector<KitEntry> const& kits = itr->second;
        if (!me->IsAlive() || !me->IsInCombat() || !me->GetVictim())
        {
            if (KitState* state = me->CustomData.Get<KitState>("coa_boss_kit"))
                state->running = false;
            return;
        }

        bool mythic = map->GetDifficulty() == DUNGEON_DIFFICULTY_EPIC;
        KitState* state = me->CustomData.GetDefault<KitState>("coa_boss_kit");
        if (!state->running)
        {
            state->running = true;
            state->timers.assign(kits.size(), -1);
            for (size_t i = 0; i < kits.size(); ++i)
            {
                KitEntry const& kit = kits[i];
                if ((kit.difficulty & KIT_ONLY_HEROIC && mythic) || (kit.difficulty & KIT_ONLY_MYTHIC && !mythic))
                    continue;
                if (kit.event == KIT_PULL)
                    state->timers[i] = 0;
                else if (kit.event == KIT_TIMER)
                    state->timers[i] = int32(KitRoll(kit.initialMin, kit.initialMax));
                else if (kit.event == KIT_HEALTH)
                    state->timers[i] = 0;
            }
        }

        for (size_t i = 0; i < kits.size(); ++i)
        {
            int32& timer = state->timers[i];
            if (timer < 0)
                continue;
            KitEntry const& kit = kits[i];
            if (kit.event == KIT_HEALTH && kit.healthPct && !me->HealthBelowPct(kit.healthPct + 1))
                continue;
            timer -= int32(diff);
            if (timer > 0)
                continue;
            if (!CastKit(me, kit))
            {
                timer = 250;
                continue;
            }
            timer = kit.repeatMin ? int32(KitRoll(kit.repeatMin, kit.repeatMax)) : -1;
            if (kit.event == KIT_HEALTH && kit.repeatMin)
                timer = std::max(timer, 1);
        }
    }
};

void AddSC_CoADungeonBossKit()
{
    new CoADungeonBossKitWorld();
    new CoADungeonBossKit();
}
