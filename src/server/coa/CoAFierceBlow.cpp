/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "AllCreatureScript.h"
#include "AllSpellScript.h"
#include "Config.h"
#include "Creature.h"
#include "DatabaseEnv.h"
#include "DataMap.h"
#include "Field.h"
#include "GameTime.h"
#include "Log.h"
#include "QueryResult.h"
#include "Spell.h"
#include "SpellInfo.h"
#include "WorldScript.h"
#include <unordered_set>

namespace
{
    constexpr uint32 SPELL_FIERCE_BLOW = 975011;
    constexpr uint32 FIERCE_BLOW_MIN_MS = 6000;
    constexpr uint32 FIERCE_BLOW_MAX_MS = 9500;
    constexpr uint32 SCRIPTED_CREATURE_FIRST_MIN_MS = 20000;
    constexpr int32 RETRY_MS = 250;
    constexpr char const* STATE_KEY = "coa_fierce_blow";

    bool Enabled = true;
    std::unordered_set<uint32> SelfScheduledEntries;
    std::unordered_set<ObjectGuid::LowType> SelfScheduledSpawns;
    thread_local bool CastingGenericFierceBlow = false;

    constexpr Milliseconds ENGAGEMENT_GAP = 1s;

    struct FierceBlowState : public DataMap::Base
    {
        bool selfScheduled = false;
        Milliseconds lastUpdate = Milliseconds::zero();
        int32 timer = 0;
    };

    int32 NextFierceBlowDelay()
    {
        return int32(urand(FIERCE_BLOW_MIN_MS, FIERCE_BLOW_MAX_MS));
    }

    int32 FirstFierceBlowDelay(Creature const* me)
    {
        if (me->GetScriptId())
            return int32(SCRIPTED_CREATURE_FIRST_MIN_MS + urand(0, FIERCE_BLOW_MAX_MS - FIERCE_BLOW_MIN_MS));
        return NextFierceBlowDelay();
    }

    bool CanReceiveFierceBlow(Creature const* me)
    {
        return !me->IsCharmedOwnedByPlayerOrPlayer() && !me->IsTotem() && !me->IsTrigger()
            && !SelfScheduledEntries.contains(me->GetEntry())
            && !(me->GetSpawnId() && SelfScheduledSpawns.contains(me->GetSpawnId()));
    }

    bool HasPendingFierceBlow(Unit const* caster)
    {
        Spell const* pending = caster->GetCurrentSpell(CURRENT_MELEE_SPELL);
        return pending && pending->GetSpellInfo()->Id == SPELL_FIERCE_BLOW;
    }

    void LoadSelfScheduledEntries()
    {
        SelfScheduledEntries.clear();
        SelfScheduledSpawns.clear();
        QueryResult result = WorldDatabase.Query(
            "SELECT entryorguid FROM smart_scripts WHERE source_type = 0 AND entryorguid > 0 "
            "AND action_type IN (11, 218) AND action_param1 = {0} "
            "UNION SELECT entryorguid DIV 100 FROM smart_scripts WHERE source_type = 9 "
            "AND action_type IN (11, 218) AND action_param1 = {0} "
            "UNION SELECT entry FROM coa_dungeon_boss_kit WHERE spell = {0} "
            "UNION SELECT entry FROM coa_boss_schedule "
            "WHERE spell_d0 = {0} OR spell_d1 = {0} OR spell_d2 = {0} OR spell_d3 = {0}", SPELL_FIERCE_BLOW);
        if (result)
        {
            do
                SelfScheduledEntries.insert(result->Fetch()[0].Get<uint32>());
            while (result->NextRow());
        }
        result = WorldDatabase.Query(
            "SELECT DISTINCT c.guid FROM creature c JOIN smart_scripts s ON c.guid = -s.entryorguid "
            "WHERE s.source_type = 0 AND s.entryorguid < 0 AND s.action_type IN (11, 218) AND s.action_param1 = {}",
            SPELL_FIERCE_BLOW);
        if (result)
        {
            do
                SelfScheduledSpawns.insert(result->Fetch()[0].Get<ObjectGuid::LowType>());
            while (result->NextRow());
        }
        LOG_INFO("server.loading", ">> Loaded {} creature entries and {} spawns that schedule their own Fierce Blow",
            SelfScheduledEntries.size(), SelfScheduledSpawns.size());
    }
}

class CoAFierceBlowWorld final : public WorldScript
{
public:
    CoAFierceBlowWorld() : WorldScript("CoAFierceBlowWorld", { WORLDHOOK_ON_AFTER_CONFIG_LOAD, WORLDHOOK_ON_STARTUP }) { }

    void OnAfterConfigLoad(bool) override
    {
        Enabled = sConfigMgr->GetOption<bool>("CoA.FierceBlow.Enable", true);
    }

    void OnStartup() override
    {
        LoadSelfScheduledEntries();
    }
};

class CoAFierceBlow final : public AllCreatureScript
{
public:
    CoAFierceBlow() : AllCreatureScript("CoAFierceBlow") { }

    void OnAllCreatureUpdate(Creature* me, uint32 diff) override
    {
        if (!Enabled || !me->IsInCombat())
            return;

        Unit* victim = me->GetVictim();
        if (!victim || !me->IsAlive() || !victim->IsCharmedOwnedByPlayerOrPlayer() || !CanReceiveFierceBlow(me))
            return;

        FierceBlowState* state = me->CustomData.GetDefault<FierceBlowState>(STATE_KEY);
        if (state->selfScheduled)
            return;
        Milliseconds now = GameTime::GetGameTimeMS();
        if (now - state->lastUpdate > Milliseconds(diff) + ENGAGEMENT_GAP)
            state->timer = FirstFierceBlowDelay(me);
        state->lastUpdate = now;

        state->timer -= int32(diff);
        if (state->timer > 0)
            return;

        if (me->GetCurrentSpell(CURRENT_MELEE_SPELL) || me->HasUnitState(UNIT_STATE_CASTING)
            || !me->IsWithinMeleeRange(victim))
        {
            state->timer = RETRY_MS;
            return;
        }

        CastingGenericFierceBlow = true;
        me->CastSpell(victim, SPELL_FIERCE_BLOW, TRIGGERED_NONE);
        CastingGenericFierceBlow = false;
        state->timer = NextFierceBlowDelay();
    }
};

class CoAFierceBlowOwnership final : public AllSpellScript
{
public:
    CoAFierceBlowOwnership() : AllSpellScript("CoAFierceBlowOwnership", { ALLSPELLHOOK_CAN_PREPARE }) { }

    bool CanPrepare(Spell* spell, SpellCastTargets const*, AuraEffect const*) override
    {
        if (CastingGenericFierceBlow || spell->GetSpellInfo()->Id != SPELL_FIERCE_BLOW)
            return true;
        Creature* caster = spell->GetCaster() ? spell->GetCaster()->ToCreature() : nullptr;
        if (!caster)
            return true;
        FierceBlowState* state = caster->CustomData.GetDefault<FierceBlowState>(STATE_KEY);
        if (state->selfScheduled)
            return true;
        state->selfScheduled = true;
        return !HasPendingFierceBlow(caster);
    }
};

void AddSC_CoAFierceBlow()
{
    new CoAFierceBlowWorld();
    new CoAFierceBlow();
    new CoAFierceBlowOwnership();
}
