/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "SpellMgr.h"
#include "SpellScript.h"

#include <vector>

namespace
{
enum GuidanceSpells : uint32
{
    SeismicGrasp = 807432,
    BoulderDash = 500692,
    PrimalConvergence = 800181,
    Bearskin = 800094,
    Rupturer = 706208,
    TerrasurgeFirst = 681119
};

void ReduceRankCooldowns(Player* player, uint32 firstRank, int32 delta)
{
    if (!player || delta >= 0)
        return;
    std::vector<uint32> cooldowns;
    for (auto const& entry : player->GetSpellCooldownMap())
        if (sSpellMgr->GetFirstSpellInChain(entry.first) == firstRank)
            cooldowns.push_back(entry.first);
    for (uint32 spell : cooldowns)
    {
        uint32 remaining = player->GetSpellCooldownDelay(spell);
        if (uint64(-int64(delta)) >= remaining)
            player->RemoveSpellCooldown(spell, true);
        else
            player->ModifySpellCooldown(spell, delta);
    }
}

class aura_ascension_primalist_direct_damage : public AuraScript
{
    PrepareAuraScript(aura_ascension_primalist_direct_damage);

    bool Load() override
    {
        return GetUnitOwner()->IsPlayer() && GetUnitOwner()->getClass() == CLASS_WILDWALKER;
    }

    bool Check(ProcEventInfo& event)
    {
        Unit* owner = GetTarget();
        Unit* victim = event.GetActionTarget();
        DamageInfo const* damage = event.GetDamageInfo();
        return owner->IsAlive() && event.GetActor() == owner && victim && victim != owner &&
            !owner->IsFriendlyTo(victim) && damage && damage->GetDamage() &&
            damage->GetDamageType() != DOT;
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_primalist_direct_damage::Check);
    }
};

class spell_ascension_protector_of_the_grove : public SpellScript
{
    PrepareSpellScript(spell_ascension_protector_of_the_grove);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({BoulderDash, PrimalConvergence, Bearskin}); }

    bool Load() override
    {
        return GetCaster()->IsPlayer() && GetCaster()->getClass() == CLASS_WILDWALKER;
    }

    void Reduce(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        int32 delta = GetSpellInfo()->Effects[EFFECT_0].CalcValue(GetCaster());
        ReduceRankCooldowns(GetHitPlayer(), GetSpellInfo()->Effects[index].MiscValue, delta);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_protector_of_the_grove::Reduce,
            EFFECT_ALL, SPELL_EFFECT_ASCENSION_MODIFY_COOLDOWN);
    }
};

class spell_ascension_thanes_guidance : public SpellScript
{
    PrepareSpellScript(spell_ascension_thanes_guidance);

    bool Load() override
    {
        return GetCaster()->IsPlayer() && GetCaster()->getClass() == CLASS_WILDWALKER;
    }

    void Reduce(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        if (index != EFFECT_0 && index != EFFECT_2)
            return;
        ReduceRankCooldowns(GetHitPlayer(), GetSpellInfo()->Effects[index].MiscValue, GetEffectValue());
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_thanes_guidance::Reduce,
            EFFECT_ALL, SPELL_EFFECT_ASCENSION_MODIFY_COOLDOWN);
    }
};

class spell_ascension_spiritbound_cooldowns : public SpellScript
{
    PrepareSpellScript(spell_ascension_spiritbound_cooldowns);

    bool Load() override
    {
        return GetCaster()->IsPlayer() && GetCaster()->getClass() == CLASS_WILDWALKER;
    }

    void Reduce(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        ReduceRankCooldowns(GetHitPlayer(), GetSpellInfo()->Effects[index].MiscValue, GetEffectValue());
        if (index == EFFECT_0)
            ReduceRankCooldowns(GetHitPlayer(), SeismicGrasp, GetEffectValue());
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_spiritbound_cooldowns::Reduce,
            EFFECT_ALL, SPELL_EFFECT_ASCENSION_MODIFY_COOLDOWN);
    }
};

class spell_ascension_rupturer_lance : public SpellScript
{
    PrepareSpellScript(spell_ascension_rupturer_lance);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({Rupturer, TerrasurgeFirst}); }

    bool Load() override
    {
        return GetCaster()->IsPlayer() && GetCaster()->getClass() == CLASS_WILDWALKER;
    }

    void Reduce(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        if (GetCaster()->HasAura(Rupturer))
            ReduceRankCooldowns(GetHitPlayer(), TerrasurgeFirst, GetEffectValue());
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_rupturer_lance::Reduce,
            EFFECT_0, SPELL_EFFECT_ASCENSION_MODIFY_COOLDOWN);
    }
};
}

void AddSC_AscensionPrimalistGuidance()
{
    RegisterSpellScript(aura_ascension_primalist_direct_damage);
    RegisterSpellScript(spell_ascension_protector_of_the_grove);
    RegisterSpellScript(spell_ascension_thanes_guidance);
    RegisterSpellScript(spell_ascension_spiritbound_cooldowns);
    RegisterSpellScript(spell_ascension_rupturer_lance);
}
