/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionBattleResurrection.h"
#include "Chat.h"
#include "DataMap.h"
#include "InstanceScript.h"
#include "Map.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellInfo.h"
#include "StringFormat.h"
#include <string>

namespace
{
using namespace Ascension::BattleResurrection;

constexpr char const* BudgetKey = "AscensionBattleResurrection";
constexpr char const* NoChargesMessage = "No battle resurrections left.";

struct InstanceBudget final : DataMap::Base
{
    Budget budget;
    bool mythicPlus = false;
};

bool IsBattleResurrection(Spell const* spell)
{
    SpellInfo const* info = spell->GetSpellInfo();
    return !spell->IsTriggered() && spell->GetCaster()->IsPlayer()
        && (info->HasEffect(SPELL_EFFECT_RESURRECT) || info->HasEffect(SPELL_EFFECT_RESURRECT_NEW));
}

InstanceBudget* ActiveBudget(Unit const* caster)
{
    if (!caster->IsInCombat())
        return nullptr;

    Map* map = caster->GetMap();
    InstanceBudget* state = map->CustomData.Get<InstanceBudget>(BudgetKey);
    if (!state || state->mythicPlus)
        return state;

    InstanceMap* instanceMap = map->ToInstanceMap();
    InstanceScript* instance = instanceMap ? instanceMap->GetInstanceScript() : nullptr;
    return instance && instance->IsEncounterInProgress() ? state : nullptr;
}

class AscensionBattleResurrectionEncounters final : public GlobalScript
{
public:
    AscensionBattleResurrectionEncounters() : GlobalScript("AscensionBattleResurrectionEncounters",
        {GLOBALHOOK_ON_BEFORE_SET_BOSS_STATE}) { }

    void OnBeforeSetBossState(uint32, EncounterState newState, EncounterState oldState, Map* instance) override
    {
        if (newState != IN_PROGRESS || oldState == IN_PROGRESS || !instance->IsRaid())
            return;

        InstanceMap* instanceMap = instance->ToInstanceMap();
        InstanceScript* script = instanceMap ? instanceMap->GetInstanceScript() : nullptr;
        if (script && script->IsEncounterInProgress())
            return;

        InstanceBudget* state = instance->CustomData.GetDefault<InstanceBudget>(BudgetKey);
        if (!state->mythicPlus)
            state->budget.Start(RaidCharges(instance->GetPlayersCountExceptGMs()));
    }
};

class AscensionBattleResurrectionSpells final : public AllSpellScript
{
public:
    AscensionBattleResurrectionSpells() : AllSpellScript("AscensionBattleResurrectionSpells",
        {ALLSPELLHOOK_ON_SPELL_CHECK_CAST, ALLSPELLHOOK_ON_CAST}) { }

    void OnSpellCheckCast(Spell* spell, bool, SpellCastResult& result) override
    {
        if (result != SPELL_CAST_OK || !IsBattleResurrection(spell))
            return;

        InstanceBudget const* state = ActiveBudget(spell->GetCaster());
        if (!state || state->budget.Available())
            return;

        result = SPELL_FAILED_DONT_REPORT;
        ChatHandler(spell->GetCaster()->ToPlayer()->GetSession()).SendNotification(NoChargesMessage);
    }

    void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const*, bool) override
    {
        if (!IsBattleResurrection(spell))
            return;

        InstanceBudget* state = ActiveBudget(caster);
        if (!state || !state->budget.Consume())
            return;

        std::string const text = Acore::StringFormat("{} used a battle resurrection: {} of {} left.",
            caster->GetName(), state->budget.Remaining(), state->budget.Total());
        caster->GetMap()->DoForAllPlayers([&text](Player* player)
        {
            ChatHandler(player->GetSession()).SendNotification(text);
        });
    }
};
}

void Ascension::BattleResurrection::StartMythicPlusRun(Map* map)
{
    InstanceBudget* state = map->CustomData.GetDefault<InstanceBudget>(BudgetKey);
    state->mythicPlus = true;
    state->budget.Start(MythicPlusCharges);
}

void AddSC_AscensionBattleResurrection()
{
    new AscensionBattleResurrectionEncounters();
    new AscensionBattleResurrectionSpells();
}
