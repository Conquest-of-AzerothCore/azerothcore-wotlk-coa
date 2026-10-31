/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "DBCStores.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "Unit.h"

namespace
{
enum HeroShamanSpells : uint32
{
    ImprovedEarthShieldCapstone = 851561,
    ImprovedEarthShieldTidal    = 851562,
    TidalWavesFinalRank         = 51564,
    ElectrocuteDamage           = 272034,
    ElectrocuteIncapacitate     = 272053,
    ElectrocuteIncapacitateLock = 272056
};

constexpr float ELECTROCUTE_DAMAGE_PER_LEVEL = 2.6f;

constexpr float ELEMENTAL_REACH_YARDS = 20.0f;
constexpr uint32 IMPROVED_EARTH_SHIELD_COOLDOWN_MS = 5000;
}

class aura_hero_shaman_elemental_reach : public AuraScript
{
    PrepareAuraScript(aura_hero_shaman_elemental_reach);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        Unit* target = eventInfo.GetProcTarget();
        return target && target != GetTarget() && !GetTarget()->IsWithinDist(target, ELEMENTAL_REACH_YARDS);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_hero_shaman_elemental_reach::CheckProc);
    }
};

class aura_hero_shaman_enhancing_totems : public AuraScript
{
    PrepareAuraScript(aura_hero_shaman_enhancing_totems);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* spellInfo = eventInfo.GetSpellInfo();
        if (!spellInfo)
            return false;
        for (SpellEffectInfo const& effect : spellInfo->Effects)
        {
            if (effect.Effect != SPELL_EFFECT_SUMMON)
                continue;
            SummonPropertiesEntry const* properties = sSummonPropertiesStore.LookupEntry(effect.MiscValueB);
            if (properties && properties->Slot >= SUMMON_SLOT_TOTEM_FIRE && properties->Slot <= SUMMON_SLOT_TOTEM_AIR)
                return true;
        }
        return false;
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_hero_shaman_enhancing_totems::CheckProc);
    }
};

class aura_hero_shaman_dual_wield_specialization : public AuraScript
{
    PrepareAuraScript(aura_hero_shaman_dual_wield_specialization);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        DamageInfo* damage = eventInfo.GetDamageInfo();
        return damage && damage->GetAttackType() == OFF_ATTACK;
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_hero_shaman_dual_wield_specialization::CheckProc);
    }
};

class spell_hero_shaman_earth_shield_heal : public SpellScript
{
    PrepareSpellScript(spell_hero_shaman_earth_shield_heal);

    void AfterHeal()
    {
        Player* shaman = ObjectAccessor::GetPlayer(*GetCaster(), GetOriginalCaster() ? GetOriginalCaster()->GetGUID() :
            GetCaster()->GetGUID());
        if (!shaman || !shaman->HasAura(ImprovedEarthShieldCapstone) || !shaman->HasSpell(TidalWavesFinalRank) ||
            shaman->HasSpellCooldown(ImprovedEarthShieldTidal))
            return;
        shaman->CastSpell(shaman, ImprovedEarthShieldTidal, true);
        shaman->AddSpellCooldown(ImprovedEarthShieldTidal, 0, IMPROVED_EARTH_SHIELD_COOLDOWN_MS);
    }

    void Register() override
    {
        AfterHit += SpellHitFn(spell_hero_shaman_earth_shield_heal::AfterHeal);
    }
};

class aura_hero_shaman_doused : public AuraScript
{
    PrepareAuraScript(aura_hero_shaman_doused);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({ ElectrocuteDamage, ElectrocuteIncapacitate, ElectrocuteIncapacitateLock });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        DamageInfo* damage = eventInfo.GetDamageInfo();
        return eventInfo.GetActor() && damage && damage->GetDamage();
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        Unit* attacker = eventInfo.GetActor();
        Unit* target = GetTarget();
        if (!attacker || !target->IsAlive())
            return;

        SpellInfo const* electrocute = sSpellMgr->AssertSpellInfo(ElectrocuteDamage);
        int32 damage = electrocute->Effects[EFFECT_0].CalcValue(attacker) +
            int32(float(attacker->GetLevel()) * ELECTROCUTE_DAMAGE_PER_LEVEL);
        attacker->CastCustomSpell(target, ElectrocuteDamage, &damage, nullptr, nullptr, true, nullptr, aurEff);
        if (target->IsAlive() && !target->HasAura(ElectrocuteIncapacitateLock))
            attacker->CastSpell(target, ElectrocuteIncapacitate, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_hero_shaman_doused::CheckProc);
        OnEffectProc += AuraEffectProcFn(aura_hero_shaman_doused::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

class spell_hero_shaman_sundering : public SpellScript
{
    PrepareSpellScript(spell_hero_shaman_sundering);

    void HandleDamage(SpellEffIndex)
    {
        Unit* caster = GetCaster();
        int32 const power = int32(caster->GetTotalAttackPowerValue(BASE_ATTACK)) +
            caster->SpellBaseDamageBonusDone(GetSpellInfo()->GetSchoolMask());
        SetEffectValue(GetEffectValue() + power / 2);
    }

    void Register() override
    {
        OnEffectLaunchTarget += SpellEffectFn(spell_hero_shaman_sundering::HandleDamage, EFFECT_0,
            SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};

void AddSC_AscensionHeroShaman()
{
    RegisterSpellScript(spell_hero_shaman_sundering);
    RegisterSpellScript(aura_hero_shaman_elemental_reach);
    RegisterSpellScript(aura_hero_shaman_enhancing_totems);
    RegisterSpellScript(aura_hero_shaman_dual_wield_specialization);
    RegisterSpellScript(spell_hero_shaman_earth_shield_heal);
    RegisterSpellScript(aura_hero_shaman_doused);
}
