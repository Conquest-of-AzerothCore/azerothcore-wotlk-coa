/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "DBCStores.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellInfo.h"
#include "SpellScript.h"
#include "Unit.h"

namespace
{
enum HeroShamanSpells : uint32
{
    ImprovedEarthShieldCapstone = 851561,
    ImprovedEarthShieldTidal    = 851562,
    TidalWavesFinalRank         = 51564
};

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
}
