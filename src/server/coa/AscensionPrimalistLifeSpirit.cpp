/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "SpellInfo.h"
#include "SpellScript.h"
#include "TemporarySummon.h"

#include <algorithm>

namespace
{
enum LifeSpiritEntries : uint32
{
    SpiritOfLife = 840002,
    PrimordialSummon = 572853,
    EternallyChosen = 802888,
    ChosenSummon = 572826,
    LesserSpiritCharge = 572830
};

class spell_ascension_primordial_spirit : public SpellScript
{
    PrepareSpellScript(spell_ascension_primordial_spirit);

    bool Validate(SpellInfo const* info) override
    {
        return (info->Id == PrimordialSummon || info->Id == ChosenSummon) &&
            ValidateSpellInfo({LesserSpiritCharge});
    }

    bool Load() override
    {
        return GetCaster()->IsPlayer() && GetCaster()->getClass() == CLASS_WILDWALKER;
    }

    void Summon(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        Player* owner = GetCaster()->ToPlayer();
        WorldLocation const* destination = GetHitDest();
        int32 duration = GetSpellInfo()->GetDuration();
        if (!destination || duration <= 0)
            return;

        for (int32 i = 0; i < std::clamp(GetEffectValue(), 1, 2); ++i)
        {
            if (TempSummon* spirit = owner->SummonCreature(SpiritOfLife, *destination,
                TEMPSUMMON_TIMED_DESPAWN, uint32(duration)))
            {
                spirit->SetOwnerGUID(owner->GetGUID());
                spirit->SetFaction(owner->GetFaction());
                spirit->SetLevel(owner->GetLevel());
                spirit->SetReactState(REACT_PASSIVE);
                spirit->SetUInt32Value(UNIT_CREATED_BY_SPELL, GetSpellInfo()->Id);
                spirit->CastSpell(nullptr, LesserSpiritCharge, TRIGGERED_FULL_MASK, nullptr, nullptr, owner->GetGUID());
            }
        }
    }

    void IgnoreLegacyCooldown(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
    }

    void Register() override
    {
        OnEffectHit += SpellEffectFn(spell_ascension_primordial_spirit::Summon, EFFECT_0, SPELL_EFFECT_SUMMON);
        if (m_scriptSpellId == ChosenSummon)
            OnEffectHitTarget += SpellEffectFn(spell_ascension_primordial_spirit::IgnoreLegacyCooldown,
                EFFECT_1, SPELL_EFFECT_ASCENSION_MODIFY_COOLDOWN);
    }
};

class aura_ascension_eternally_chosen : public AuraScript
{
    PrepareAuraScript(aura_ascension_eternally_chosen);

    bool Check(ProcEventInfo& event)
    {
        Unit* owner = GetTarget();
        return owner->IsPlayer() && owner->getClass() == CLASS_WILDWALKER && owner->IsAlive() &&
            GetCaster() == owner && event.GetActor() == owner;
    }

    void Register() override { DoCheckProc += AuraCheckProcFn(aura_ascension_eternally_chosen::Check); }
};

class primalist_life_spirit_scaling : public UnitScript
{
public:
    primalist_life_spirit_scaling() : UnitScript("primalist_life_spirit_scaling",
        true, {UNITHOOK_MODIFY_SPELL_EFFECT_BASE_VALUE}) { }

    void ModifySpellEffectBaseValue(Unit const* caster, SpellInfo const* info, uint8 index,
        float& value) override
    {
        if (!caster || info->Id != LesserSpiritCharge || (index != EFFECT_1 && index != EFFECT_2))
            return;
        Unit const* owner = caster->IsPlayer() ? caster : caster->GetOwner();
        if (!owner || !owner->IsPlayer() || owner->getClass() != CLASS_WILDWALKER)
            return;

        value += 0.2f * (std::max(0, const_cast<Unit*>(owner)->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_NATURE)) +
            std::max(0.0f, owner->GetTotalAttackPowerValue(BASE_ATTACK)));
    }
};

class spell_ascension_lesser_spirit_charge : public SpellScript
{
    PrepareSpellScript(spell_ascension_lesser_spirit_charge);

    void SelectDestination(WorldObject*& target)
    {
        if (!target)
            return;

        WorldLocation destination(target->GetMapId(), target->GetPosition());
        SetExplTargetDest(destination);
    }

    void Register() override
    {
        OnObjectTargetSelect += SpellObjectTargetSelectFn(spell_ascension_lesser_spirit_charge::SelectDestination,
            EFFECT_0, TARGET_UNIT_NEARBY_PARTY);
    }
};
}

void AddSC_AscensionPrimalistLifeSpirit()
{
    new primalist_life_spirit_scaling();
    RegisterSpellScript(spell_ascension_primordial_spirit);
    RegisterSpellScript(aura_ascension_eternally_chosen);
    RegisterSpellScript(spell_ascension_lesser_spirit_charge);
}
