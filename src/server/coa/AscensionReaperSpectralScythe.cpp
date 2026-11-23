/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "ObjectMgr.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "SpellAuras.h"
#include "SpellScript.h"
#include <algorithm>

namespace
{
constexpr uint32 SpellReapedSoul = 500363;
constexpr uint32 SpellScytheSweep = 500489;

class spell_ascension_reaper_spectral_scythe : public SpellScript
{
    PrepareSpellScript(spell_ascension_reaper_spectral_scythe);

    void SummonOneScythePerReapedSoul(SpellEffIndex)
    {
        Unit* caster = GetCaster();
        if (Aura const* souls = caster ? caster->GetAura(SpellReapedSoul) : nullptr)
            SetEffectValue(std::max<int32>(1, souls->GetStackAmount()));
    }

    void Register() override
    {
        OnEffectHit += SpellEffectFn(spell_ascension_reaper_spectral_scythe::SummonOneScythePerReapedSoul,
            EFFECT_0, SPELL_EFFECT_SUMMON);
    }
};

class spell_ascension_reaper_scythe_sweep : public SpellScript
{
    PrepareSpellScript(spell_ascension_reaper_scythe_sweep);

    void ScaleWithScytheLevel(SpellEffIndex)
    {
        Unit* caster = GetCaster();
        SpellInfo const* info = GetSpellInfo();
        if (!caster || !info->SpellLevel || caster->GetLevel() == info->SpellLevel)
            return;

        CreatureBaseStats const* scythe = sObjectMgr->GetCreatureBaseStats(caster->GetLevel(), caster->getClass());
        CreatureBaseStats const* spell = sObjectMgr->GetCreatureBaseStats(info->SpellLevel, caster->getClass());
        if (scythe && spell && spell->BaseDamage[0] > 0.0f)
            SetEffectValue(int32(GetEffectValue() * scythe->BaseDamage[0] / spell->BaseDamage[0]));
    }

    void Register() override
    {
        OnEffectLaunchTarget += SpellEffectFn(spell_ascension_reaper_scythe_sweep::ScaleWithScytheLevel,
            EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};

struct npc_ascension_reaper_spectral_scythe : public ScriptedAI
{
    explicit npc_ascension_reaper_spectral_scythe(Creature* creature) : ScriptedAI(creature) { }

    void UpdateAI(uint32) override
    {
        Unit* victim = me->GetVictim();
        if (!victim || !victim->IsAlive() || !me->IsValidAttackTarget(victim))
            victim = AssistOwner();

        if (!victim)
            return;

        if (!me->GetCurrentSpell(CURRENT_MELEE_SPELL) && !me->HasUnitState(UNIT_STATE_CASTING))
            me->CastSpell(victim, SpellScytheSweep, false);

        DoMeleeAttackIfReady();
    }

private:
    Unit* AssistOwner()
    {
        Unit* owner = me->GetOwner();
        Unit* target = owner ? owner->GetVictim() : nullptr;
        if (!target || !target->IsAlive() || !me->IsValidAttackTarget(target))
        {
            if (me->GetVictim())
                EnterEvadeMode(EVADE_REASON_NO_HOSTILES);
            return nullptr;
        }

        AttackStart(target);
        return me->GetVictim();
    }
};
}

void AddSC_AscensionReaperSpectralScythe()
{
    RegisterSpellScript(spell_ascension_reaper_spectral_scythe);
    RegisterSpellScript(spell_ascension_reaper_scythe_sweep);
    RegisterCreatureAI(npc_ascension_reaper_spectral_scythe);
}
