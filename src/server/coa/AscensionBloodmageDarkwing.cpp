/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionBloodmageDarkwing.h"
#include "Creature.h"
#include "EventMap.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptedCreature.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "TemporarySummon.h"
#include <algorithm>
#include <cmath>
#include <limits>
#include <list>
#include <vector>

namespace
{
enum DarkwingCreatures : uint32
{
    NPC_SHADOW_BAT = 50069
};

enum DarkwingSpells : uint32
{
    SPELL_CALL_OF_THE_DARKWING = 801958,
    SPELL_BAT_BITE = 802358,
    SPELL_BAT_BITE_HEAL = 802399
};

constexpr std::size_t MaxShadowBats = 10;
constexpr uint8 BAT_BITE_SCALING_EVENT = 23;
constexpr double BAT_BITE_SPELL_POWER_COEFFICIENT = 0.4;
constexpr double BAT_BITE_ATTACK_POWER_COEFFICIENT = 0.2;
constexpr uint32 BAT_RETARGET_EVENT = 1;
constexpr Milliseconds BAT_RETARGET_INTERVAL = 200ms;
constexpr Milliseconds BAT_RETARGET_TIMEOUT = 2000ms;

void CapShadowBats(Player* player, Guardian* newest)
{
    std::list<Creature*> minions;
    player->GetAllMinionsByEntry(minions, NPC_SHADOW_BAT);

    std::vector<TempSummon*> older;
    for (Creature* minion : minions)
        if (minion != newest && minion->IsInWorld())
            if (TempSummon* summon = minion->ToTempSummon())
                older.push_back(summon);

    if (older.size() < MaxShadowBats)
        return;

    std::sort(older.begin(), older.end(),
        [](TempSummon const* a, TempSummon const* b) { return a->GetGUID().GetCounter() < b->GetGUID().GetCounter(); });

    std::size_t const excess = older.size() - (MaxShadowBats - 1);
    for (std::size_t i = 0; i < excess; ++i)
        older[i]->UnSummon();
}

class bloodmage_darkwing_bat : public PlayerScript
{
  public:
    bloodmage_darkwing_bat()
        : PlayerScript("bloodmage_darkwing_bat", {PLAYERHOOK_ON_AFTER_GUARDIAN_INIT_STATS_FOR_LEVEL})
    {
    }

    void OnPlayerAfterGuardianInitStatsForLevel(Player* player, Guardian* guardian) override
    {
        if (!player || !guardian || guardian->GetEntry() != NPC_SHADOW_BAT)
            return;

        CapShadowBats(player, guardian);
        guardian->SetReactState(REACT_PASSIVE);

        if (player->getClass() != CLASS_SON_OF_ARUGAL)
            return;

        CreatureTemplate const* info = guardian->GetCreatureTemplate();
        CreatureBaseStats const* stats = sObjectMgr->GetCreatureBaseStats(guardian->GetLevel(), info->unit_class);
        float const damage = stats->GenerateBaseDamage(info);
        guardian->SetBaseWeaponDamage(BASE_ATTACK, MINDAMAGE, damage);
        guardian->SetBaseWeaponDamage(BASE_ATTACK, MAXDAMAGE, damage * 1.5f);
        guardian->SetStatFlatModifier(UNIT_MOD_ATTACK_POWER, BASE_VALUE, float(stats->AttackPower));
        guardian->UpdateAllStats();
    }
};

struct ShadowBatAI : public ScriptedAI
{
    explicit ShadowBatAI(Creature* creature) : ScriptedAI(creature) {}

    bool bitten = false;
    Milliseconds elapsed{0};
    EventMap events;

    void AttackStart(Unit*) override {}
    void MoveInLineOfSight(Unit*) override {}
    void EnterEvadeMode(EvadeReason) override {}

    void IsSummonedBy(WorldObject*) override
    {
        me->SetReactState(REACT_PASSIVE);
        if (TryBite())
            return;
        events.ScheduleEvent(BAT_RETARGET_EVENT, BAT_RETARGET_INTERVAL);
    }

    bool TryBite()
    {
        if (bitten)
            return true;

        Unit* owner = me->GetOwner();
        Unit* target = owner ? owner->GetVictim() : nullptr;
        if (!target || !target->IsAlive() || !me->IsValidAttackTarget(target))
            return false;

        bitten = me->CastSpell(target, SPELL_BAT_BITE, false) == SPELL_CAST_OK;
        return bitten;
    }

    void UpdateAI(uint32 diff) override
    {
        if (bitten)
            return;

        events.Update(diff);
        elapsed += Milliseconds(diff);
        if (events.ExecuteEvent() != BAT_RETARGET_EVENT)
            return;

        if (TryBite() || elapsed >= BAT_RETARGET_TIMEOUT)
            return;

        events.ScheduleEvent(BAT_RETARGET_EVENT, BAT_RETARGET_INTERVAL);
    }
};

class npc_ascension_bloodmage_shadow_bat : public CreatureScript
{
  public:
    npc_ascension_bloodmage_shadow_bat() : CreatureScript("npc_ascension_bloodmage_shadow_bat") {}

    CreatureAI* GetAI(Creature* creature) const override { return new ShadowBatAI(creature); }
};

class spell_ascension_bloodmage_bat_bite : public SpellScript
{
    PrepareSpellScript(spell_ascension_bloodmage_bat_bite);

    void HealMaster()
    {
        Unit* caster = GetCaster();
        if (!caster || caster->GetEntry() != NPC_SHADOW_BAT ||
            caster->GetUInt32Value(UNIT_CREATED_BY_SPELL) != SPELL_CALL_OF_THE_DARKWING)
            return;

        int32 const damage = GetHitDamage();
        if (damage <= 0)
            return;

        caster->CastCustomSpell(SPELL_BAT_BITE_HEAL, SPELLVALUE_BASE_POINT0, damage, nullptr, TRIGGERED_FULL_MASK);
    }

    void Register() override
    {
        AfterHit += SpellHitFn(spell_ascension_bloodmage_bat_bite::HealMaster);
    }
};
}

void PrepareAscensionBloodmageBatBite(Spell* spell)
{
    if (!spell)
        return;

    SpellInfo const* info = spell->GetSpellInfo();
    if (info->Id != SPELL_BAT_BITE)
        return;

    Unit* caster = spell->GetCaster();
    if (!caster || caster->GetEntry() != NPC_SHADOW_BAT)
        return;

    Unit* owner = caster->GetOwner();
    if (!owner)
        return;

    Player* source = owner->ToPlayer();
    if (!source)
        return;

    SpellEffectInfo const& effect = info->Effects[EFFECT_0];
    if (effect.Effect != SPELL_EFFECT_SCHOOL_DAMAGE || effect.DieSides != 1 || effect.BonusMultiplier != 0.0f ||
        sSpellMgr->GetSpellBonusData(info->Id))
        return;

    double const bonus = source->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_SHADOW) * BAT_BITE_SPELL_POWER_COEFFICIENT +
        source->GetTotalAttackPowerValue(BASE_ATTACK) * BAT_BITE_ATTACK_POWER_COEFFICIENT;
    if (!std::isfinite(bonus) || bonus < 0)
        return;

    int64 const value = int64(spell->GetSpellValue()->EffectBasePoints[EFFECT_0]) + 1 + int32(bonus);
    if (value < std::numeric_limits<int32>::min() || value > std::numeric_limits<int32>::max() ||
        !spell->TryMarkScriptEventHandled(BAT_BITE_SCALING_EVENT))
        return;

    spell->SetSpellValue(SPELLVALUE_BASE_POINT0, int32(value));
}

void AddSC_AscensionBloodmageDarkwing()
{
    new bloodmage_darkwing_bat();
    new npc_ascension_bloodmage_shadow_bat();
    RegisterSpellScript(spell_ascension_bloodmage_bat_bite);
}
