/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionRunemasterBrand.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
#include <limits>
#include <vector>

namespace
{
enum RunemasterTalentProcSpells : uint32
{
    SPELL_ANCIENT_WARRIOR_COOLDOWN = 520757,
    SPELL_HOARFROST = 801104,
    SPELL_LEY_LOCK = 800995,
    SPELL_HARVESTED_LEY_ENERGY = 803258,
    SPELL_LEY_POWER_STRIKE = 803282,
    SPELL_ENGRAVING_FIRE = 653210,
    SPELL_ENGRAVING_WATER = 653261,
    SPELL_ENGRAVING_ICE = 653217,
    SPELL_ENGRAVING_ARCANE = 653263,
    SPELL_ENGRAVING_EARTH = 653272,
    SPELL_ENGRAVING_AIR = 653226,
    SPELL_AIR_ENGRAVING_PROC = 653225,
    SPELL_ICE_ENGRAVING_PROC = 653266,
    SPELL_ICEBOUND_MOMENTUM = 712490,
    SPELL_ICEBOUND_MOMENTUM_DAMAGE = 712491
};

bool IsRunemaster(Unit const* unit)
{
    return unit && unit->IsPlayer() && unit->getClass() == CLASS_SPIRIT_MAGE;
}

void ReduceSharedCooldowns(Player* player, uint32 spellId, int32 delta)
{
    SpellInfo const* named = sSpellMgr->GetSpellInfo(spellId);
    if (!player || !named || delta >= 0)
        return;
    uint32 const root = sSpellMgr->GetFirstSpellInChain(spellId);
    uint32 const category = named->GetCategory();
    std::vector<uint32> cooling;
    for (auto const& [id, cooldown] : player->GetSpellCooldownMap())
        if (SpellInfo const* info = sSpellMgr->GetSpellInfo(id))
            if (sSpellMgr->GetFirstSpellInChain(id) == root ||
                (category && info->GetCategory() == category && info->SpellFamilyName == named->SpellFamilyName))
                cooling.push_back(id);
    for (uint32 id : cooling)
    {
        uint32 const remaining = player->GetSpellCooldownDelay(id);
        if (uint64(-int64(delta)) >= remaining)
            player->RemoveSpellCooldown(id, true);
        else
            player->ModifySpellCooldown(id, delta);
    }
}

class spell_ascension_runemaster_ancient_warrior : public SpellScript
{
    PrepareSpellScript(spell_ascension_runemaster_ancient_warrior);

    bool Validate(SpellInfo const* info) override
    {
        return info->Id == SPELL_ANCIENT_WARRIOR_COOLDOWN &&
            info->Effects[EFFECT_0].Effect == SPELL_EFFECT_ASCENSION_MODIFY_COOLDOWN &&
            ValidateSpellInfo({uint32(info->Effects[EFFECT_0].MiscValue)});
    }

    bool Load() override
    {
        return IsRunemaster(GetCaster());
    }

    void ReduceFistOfTheAncients(SpellEffIndex effIndex)
    {
        PreventHitDefaultEffect(effIndex);
        ReduceSharedCooldowns(GetHitPlayer(), uint32(GetSpellInfo()->Effects[effIndex].MiscValue), GetEffectValue());
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_runemaster_ancient_warrior::ReduceFistOfTheAncients,
            EFFECT_0, SPELL_EFFECT_ASCENSION_MODIFY_COOLDOWN);
    }
};

class aura_ascension_runemaster_decoder : public AuraScript
{
    PrepareAuraScript(aura_ascension_runemaster_decoder);

    bool CheckDamagedEnemy(ProcEventInfo& eventInfo)
    {
        Unit* owner = GetTarget();
        Unit* target = eventInfo.GetActionTarget();
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        return IsRunemaster(owner) && owner->IsAlive() && eventInfo.GetActor() == owner && target &&
            target != owner && target->IsAlive() && !owner->IsFriendlyTo(target) && damage && damage->GetDamage();
    }

    void TriggerEngravings(ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        TriggerRunemasterWeaponEngravings(GetTarget(), eventInfo.GetActionTarget());
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_runemaster_decoder::CheckDamagedEnemy);
        OnProc += AuraProcFn(aura_ascension_runemaster_decoder::TriggerEngravings);
    }
};

class aura_ascension_runemaster_air_engraving : public AuraScript
{
    PrepareAuraScript(aura_ascension_runemaster_air_engraving);

    bool Validate(SpellInfo const* info) override
    {
        return info->Id == SPELL_AIR_ENGRAVING_PROC && info->Effects[EFFECT_0].IsAura(AuraType(354)) &&
            info->Effects[EFFECT_0].TriggerSpell == SPELL_ENGRAVING_AIR &&
            ValidateSpellInfo({SPELL_ENGRAVING_AIR});
    }

    bool CheckDirectDamage(ProcEventInfo& eventInfo)
    {
        Unit* owner = GetTarget();
        Unit* target = eventInfo.GetActionTarget();
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        SpellInfo const* info = eventInfo.GetSpellInfo();
        return IsRunemaster(owner) && GetCaster() == owner && eventInfo.GetActor() == owner && target &&
            target->IsAlive() && owner->IsValidAttackTarget(target) && damage && damage->GetDamage() &&
            (!info || info->Id != SPELL_ENGRAVING_AIR);
    }

    void CopyDamage(AuraEffect const* effect, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        uint64 const damage = uint64(eventInfo.GetDamageInfo()->GetDamage()) *
            std::clamp(effect->GetAmount(), 0, 100) / 100;
        if (damage)
            GetTarget()->CastCustomSpell(SPELL_ENGRAVING_AIR, SPELLVALUE_BASE_POINT0,
                int32(std::min<uint64>(damage, std::numeric_limits<int32>::max())), eventInfo.GetActionTarget(),
                TRIGGERED_FULL_MASK, nullptr, effect);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_runemaster_air_engraving::CheckDirectDamage);
        OnEffectProc += AuraEffectProcFn(aura_ascension_runemaster_air_engraving::CopyDamage, EFFECT_0,
            AuraType(354));
    }
};

class aura_ascension_runemaster_leyfrost : public AuraScript
{
    PrepareAuraScript(aura_ascension_runemaster_leyfrost);

    bool CheckHoarfrost(ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        return IsRunemaster(GetTarget()) && eventInfo.GetActor() == GetTarget() && info &&
            sSpellMgr->GetFirstSpellInChain(info->Id) == SPELL_HOARFROST;
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_runemaster_leyfrost::CheckHoarfrost);
    }
};

class aura_ascension_runemaster_convergence : public AuraScript
{
    PrepareAuraScript(aura_ascension_runemaster_convergence);

    static bool IsWeaponEngraving(uint32 spellId)
    {
        switch (spellId)
        {
            case SPELL_ENGRAVING_FIRE:
            case SPELL_ENGRAVING_WATER:
            case SPELL_ENGRAVING_ICE:
            case SPELL_ENGRAVING_ARCANE:
            case SPELL_ENGRAVING_EARTH:
            case SPELL_ENGRAVING_AIR:
                return true;
            default:
                return false;
        }
    }

    bool CheckEngravingHit(ProcEventInfo& eventInfo)
    {
        Unit* owner = GetTarget();
        Unit* target = eventInfo.GetActionTarget();
        SpellInfo const* spell = eventInfo.GetSpellInfo();
        return IsRunemaster(owner) && eventInfo.GetActor() == owner && spell && IsWeaponEngraving(spell->Id) &&
            target && target != owner && target->IsAlive() && !owner->IsFriendlyTo(target);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_runemaster_convergence::CheckEngravingHit);
    }
};

class runemaster_ley_lock_duration : public AllSpellScript
{
public:
    runemaster_ley_lock_duration() : AllSpellScript("runemaster_ley_lock_duration",
        {ALLSPELLHOOK_ON_INTERRUPT_DURATION}) { }

    void OnSpellInterruptDuration(Spell* spell, Unit*, int32& duration) override
    {
        Unit* caster = spell->GetOriginalCaster();
        if (spell->GetSpellInfo()->Id != SPELL_LEY_LOCK || !IsRunemaster(caster))
            return;
        caster->ToPlayer()->ApplySpellMod(SPELL_LEY_LOCK, SPELLMOD_DURATION, duration);
    }
};

class spell_ascension_runemaster_ley_power : public SpellScript
{
    PrepareSpellScript(spell_ascension_runemaster_ley_power);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({SPELL_HARVESTED_LEY_ENERGY});
    }

    bool Load() override
    {
        return IsRunemaster(GetCaster());
    }

    void HarvestEnemy(SpellEffIndex effIndex)
    {
        PreventHitDefaultEffect(effIndex);
        Unit* caster = GetCaster();
        Unit* enemy = GetHitUnit();
        if (enemy && enemy != caster && !caster->IsFriendlyTo(enemy))
            caster->CastSpell(caster, SPELL_HARVESTED_LEY_ENERGY, TRIGGERED_FULL_MASK);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_runemaster_ley_power::HarvestEnemy, EFFECT_0,
            SPELL_EFFECT_SCRIPT_EFFECT);
    }
};

class aura_ascension_runemaster_harvested_ley_energy : public AuraScript
{
    PrepareAuraScript(aura_ascension_runemaster_harvested_ley_energy);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({SPELL_LEY_POWER_STRIKE});
    }

    bool CheckDamagedEnemy(ProcEventInfo& eventInfo)
    {
        Unit* owner = GetTarget();
        Unit* target = eventInfo.GetActionTarget();
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        SpellInfo const* spell = eventInfo.GetSpellInfo();
        return IsRunemaster(owner) && owner->IsAlive() && eventInfo.GetActor() == owner && target &&
            target != owner && !owner->IsFriendlyTo(target) && damage && damage->GetDamage() &&
            (!spell || spell->Id != SPELL_LEY_POWER_STRIKE);
    }

    void Strike(AuraEffect const* effect, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        uint64 const share = uint64(eventInfo.GetDamageInfo()->GetDamage()) *
            std::clamp(effect->GetAmount(), 0, 100) / 100;
        if (share)
            GetTarget()->CastCustomSpell(SPELL_LEY_POWER_STRIKE, SPELLVALUE_BASE_POINT0,
                int32(std::min<uint64>(share, std::numeric_limits<int32>::max())), eventInfo.GetActionTarget(),
                TRIGGERED_FULL_MASK);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_runemaster_harvested_ley_energy::CheckDamagedEnemy);
        OnEffectProc += AuraEffectProcFn(aura_ascension_runemaster_harvested_ley_energy::Strike, EFFECT_0,
            AuraType(354));
    }
};

class runemaster_ice_engraving_hits : public AllSpellScript
{
public:
    runemaster_ice_engraving_hits() : AllSpellScript("runemaster_ice_engraving_hits",
        {ALLSPELLHOOK_ON_HIT_RESULT}) { }

    void OnSpellHitResult(Spell* spell, Unit* target, uint8 miss, uint32 damage, uint32, bool) override
    {
        Unit* caster = spell->GetCaster();
        SpellInfo const* info = spell->GetSpellInfo();
        if (info->Id == SPELL_ENGRAVING_ICE && info->SpellFamilyName == uint32(CLASS_SPIRIT_MAGE) + 6 &&
            IsRunemaster(caster) && caster->HasAura(SPELL_ICE_ENGRAVING_PROC, caster->GetGUID()) &&
            miss == SPELL_MISS_NONE && damage && target && target->IsAlive() && caster->IsValidAttackTarget(target))
            caster->CastSpell(target, SPELL_ICEBOUND_MOMENTUM, TRIGGERED_FULL_MASK);
    }
};

class aura_ascension_runemaster_icebound_momentum : public AuraScript
{
    PrepareAuraScript(aura_ascension_runemaster_icebound_momentum);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({SPELL_ICEBOUND_MOMENTUM_DAMAGE}); }

    bool Check(ProcEventInfo& event)
    {
        Unit* caster = GetCaster();
        DamageInfo const* damage = event.GetDamageInfo();
        SpellInfo const* info = event.GetSpellInfo();
        return IsRunemaster(caster) && event.GetActor() == caster && event.GetActionTarget() == GetTarget() &&
            damage && damage->GetDamage() && (!info || info->Id != SPELL_ICEBOUND_MOMENTUM_DAMAGE);
    }

    void CopyDamage(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        uint64 const amount = uint64(event.GetDamageInfo()->GetDamage()) *
            std::clamp(effect->GetAmount(), 0, 100) / 100;
        if (amount)
            GetCaster()->CastCustomSpell(SPELL_ICEBOUND_MOMENTUM_DAMAGE, SPELLVALUE_BASE_POINT0,
                int32(std::min<uint64>(amount, std::numeric_limits<int32>::max())), GetTarget(),
                TRIGGERED_FULL_MASK, nullptr, effect);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_runemaster_icebound_momentum::Check);
        OnEffectProc += AuraEffectProcFn(aura_ascension_runemaster_icebound_momentum::CopyDamage,
            EFFECT_0, SPELL_AURA_DUMMY);
    }
};

class runemaster_ley_power_metadata : public GlobalScript
{
public:
    runemaster_ley_power_metadata() : GlobalScript("runemaster_ley_power_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->SpellFamilyName == uint32(CLASS_SPIRIT_MAGE) + 6)
        {
            if (info->Id == SPELL_ICEBOUND_MOMENTUM)
                info->ProcFlags = PROC_FLAG_TAKEN_DAMAGE;
            if (info->Id == SPELL_ICEBOUND_MOMENTUM_DAMAGE)
            {
                info->AscensionInheritsResolvedAmount = true;
                info->Effects[EFFECT_0].BonusMultiplier = 0.0f;
                info->AttributesEx2 |= SPELL_ATTR2_CANT_CRIT;
                info->AttributesEx3 |= SPELL_ATTR3_IGNORE_CASTER_MODIFIERS;
                info->AttributesEx4 |= SPELL_ATTR4_IGNORE_DAMAGE_TAKEN_MODIFIERS;
            }
        }
        if (info->Id != SPELL_LEY_POWER_STRIKE || info->Effects[EFFECT_0].Effect != SPELL_EFFECT_SCHOOL_DAMAGE)
            return;
        info->AscensionInheritsResolvedAmount = true;
        info->Effects[EFFECT_0].BonusMultiplier = 0.0f;
    }
};
}

void AddSC_AscensionRunemasterTalentProcs()
{
    RegisterSpellScript(spell_ascension_runemaster_ancient_warrior);
    RegisterSpellScript(aura_ascension_runemaster_decoder);
    RegisterSpellScript(aura_ascension_runemaster_air_engraving);
    RegisterSpellScript(aura_ascension_runemaster_leyfrost);
    RegisterSpellScript(aura_ascension_runemaster_convergence);
    new runemaster_ley_lock_duration();
    RegisterSpellScript(spell_ascension_runemaster_ley_power);
    RegisterSpellScript(aura_ascension_runemaster_harvested_ley_energy);
    new runemaster_ice_engraving_hits();
    RegisterSpellScript(aura_ascension_runemaster_icebound_momentum);
    new runemaster_ley_power_metadata();
}
