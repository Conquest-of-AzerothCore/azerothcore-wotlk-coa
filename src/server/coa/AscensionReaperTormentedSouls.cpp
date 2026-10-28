/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
#include <cmath>

namespace
{
constexpr uint32 ReapedSoul = 500363;
constexpr uint32 TormentedSoulsBuff = 500481;
constexpr uint32 TormentedSoulHeal = 500482;
constexpr uint32 SoulfusedConstitution = 561100;
constexpr uint32 SoulfusedConstitutionWard = 561234;
constexpr uint32 AdditionalTormentedSouls = 525013;
constexpr uint32 AdditionalTormentedSoulCount = 2;
constexpr float HealBase = 50.0f;
constexpr float HealPerLevel = 0.5f;
constexpr float HealPerStamina = 0.24f;

class spell_ascension_reaper_tormented_souls : public SpellScript
{
    PrepareSpellScript(spell_ascension_reaper_tormented_souls);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({ReapedSoul, TormentedSoulsBuff}); }

    void CountSouls()
    {
        Aura const* souls = GetCaster()->GetAura(ReapedSoul, GetCaster()->GetGUID());
        _souls = souls ? souls->GetStackAmount() : 0;
    }

    void SkipDelayedReapplication(SpellEffIndex effIndex)
    {
        PreventHitDefaultEffect(effIndex);
    }

    void CreateTormentedSouls()
    {
        Unit* caster = GetCaster();
        Aura* buff = caster->GetAura(TormentedSoulsBuff, caster->GetGUID());
        if (!buff || !_souls)
            return;

        uint32 stacks = _souls * (caster->HasAura(SoulfusedConstitution) ? 2 : 1);
        if (caster->HasAura(AdditionalTormentedSouls))
            stacks += AdditionalTormentedSoulCount;
        buff->SetStackAmount(uint8(std::min<uint32>(stacks, UINT8_MAX)));
    }

    void Register() override
    {
        BeforeCast += SpellCastFn(spell_ascension_reaper_tormented_souls::CountSouls);
        OnEffectLaunch += SpellEffectFn(spell_ascension_reaper_tormented_souls::SkipDelayedReapplication, EFFECT_1,
            SPELL_EFFECT_ASCENSION_TRIGGER_SPELL_DELAYED);
        OnEffectLaunchTarget += SpellEffectFn(spell_ascension_reaper_tormented_souls::SkipDelayedReapplication,
            EFFECT_1, SPELL_EFFECT_ASCENSION_TRIGGER_SPELL_DELAYED);
        OnEffectLaunch += SpellEffectFn(spell_ascension_reaper_tormented_souls::SkipDelayedReapplication, EFFECT_2,
            SPELL_EFFECT_ASCENSION_TRIGGER_SPELL_DELAYED);
        OnEffectLaunchTarget += SpellEffectFn(spell_ascension_reaper_tormented_souls::SkipDelayedReapplication,
            EFFECT_2, SPELL_EFFECT_ASCENSION_TRIGGER_SPELL_DELAYED);
        AfterCast += SpellCastFn(spell_ascension_reaper_tormented_souls::CreateTormentedSouls);
    }

    uint32 _souls = 0;
};

class aura_ascension_reaper_tormented_souls : public AuraScript
{
    PrepareAuraScript(aura_ascension_reaper_tormented_souls);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({TormentedSoulHeal, SoulfusedConstitution, SoulfusedConstitutionWard});
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        return eventInfo.GetDamageInfo() && eventInfo.GetActionTarget() == GetTarget();
    }

    void Consume(AuraEffect const*, ProcEventInfo&)
    {
        PreventDefaultAction();
        Unit* owner = GetTarget();
        float const heal = HealBase + HealPerLevel * owner->GetLevel() +
            HealPerStamina * std::max(0.0f, owner->GetStat(STAT_STAMINA));
        owner->CastCustomSpell(TormentedSoulHeal, SPELLVALUE_BASE_POINT0, int32(std::lround(heal)), owner, true);
        GetAura()->ModStackAmount(-1);
    }

    void Ward(AuraEffect const*, AuraEffectHandleModes)
    {
        Unit* owner = GetTarget();
        if (!owner->HasAura(SoulfusedConstitution))
            return;
        Aura* ward = owner->GetAura(SoulfusedConstitutionWard, owner->GetGUID());
        if (!ward)
            ward = owner->AddAura(SoulfusedConstitutionWard, owner);
        if (ward)
        {
            ward->SetMaxDuration(GetAura()->GetMaxDuration());
            ward->SetDuration(GetAura()->GetDuration());
        }
    }

    void EndWard(AuraEffect const*, AuraEffectHandleModes)
    {
        GetTarget()->RemoveAurasDueToSpell(SoulfusedConstitutionWard, GetTarget()->GetGUID());
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_reaper_tormented_souls::CheckProc);
        OnEffectProc += AuraEffectProcFn(aura_ascension_reaper_tormented_souls::Consume, EFFECT_1,
            SPELL_AURA_PROC_TRIGGER_SPELL);
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_reaper_tormented_souls::Ward, EFFECT_0,
            SPELL_AURA_MOD_DAMAGE_PERCENT_TAKEN, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_reaper_tormented_souls::EndWard, EFFECT_0,
            SPELL_AURA_MOD_DAMAGE_PERCENT_TAKEN, AURA_EFFECT_HANDLE_REAL);
    }
};
}

void AddSC_AscensionReaperTormentedSouls()
{
    RegisterSpellScript(spell_ascension_reaper_tormented_souls);
    RegisterSpellScript(aura_ascension_reaper_tormented_souls);
}
