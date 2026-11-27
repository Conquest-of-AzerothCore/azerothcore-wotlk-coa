/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionBattlegroundCombat.h"
#include "AscensionClientSpellPatches.h"
#include "AscensionPooledVitality.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
#include <cmath>
#include <limits>

namespace
{
using namespace AscensionBloodmage;
constexpr uint32 VitalityCost = 10;
constexpr uint32 Hemopulse = 524906;
constexpr uint32 DarkfallenLamentLeech = 630874;
constexpr uint32 DarkLiturgy = 800781;
constexpr uint32 BloodCovenant = 1200012;
constexpr uint32 VitalShield = 504849;
constexpr uint32 Torture = 504071;
constexpr uint32 VampiricFeast = 804934;
constexpr uint32 SovereigntyBuff = 504272;
constexpr uint32 FleshcraftSpell = 801952;
constexpr uint32 FleshcraftSated = 532125;
constexpr uint32 BloodRitualsHeal = 704119;
constexpr uint32 HeartbreakAllyHeal = 520315;
constexpr uint32 EnragingWound = 560589;
constexpr uint32 ShadowStrengthDamage = 536277;
constexpr uint32 BloodmoonStrength = 578120;
constexpr uint32 Bloodthorns = 802313;
constexpr uint32 GreaterBloodthorns = 572116;
constexpr uint32 BloodmoonStrengthMask1 = 0x820000;
constexpr uint32 BloodmoonStrengthMask2 = 0x4000;

bool IsBloodmage(Player const* player)
{
    return player && player->getClass() == CLASS_SON_OF_ARUGAL && player->IsAlive() && player->IsInWorld();
}

bool CanEmpower(Player* player)
{
    if (!IsBloodmage(player) || !player->HasAura(PooledVitalityTalent) || player->HasAura(CursedForm))
        return false;
    Aura const* pool = player->GetAura(PooledVitality, player->GetGUID());
    return pool && uint32(pool->GetStackAmount()) >= VitalityCost;
}

class bloodmage_vitality_contracts : public GlobalScript
{
public:
    bloodmage_vitality_contracts() : GlobalScript("bloodmage_vitality_contracts",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (!info)
            return;
        if (info->Id == BloodCovenant)
            info->UsesMaxHealthForCost = true;
        if (info->Id == VitalShield &&
            info->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_ASCENSION_MOD_HEALING_RECEIVED_PCT)
            info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_DUMMY;
        if (info->Id == FleshcraftSpell)
        {
            info->ExcludeTargetAuraSpell = FleshcraftSated;
            info->Effects[EFFECT_1].Effect = 0;
            info->Effects[EFFECT_2].Effect = 0;
            info->Effects[EFFECT_2].ApplyAuraName = SPELL_AURA_NONE;
            Ascension::ClientSpellPatches::Instance().Register(info->Id);
        }
        if (info->Id == FleshcraftSated)
            info->AttributesCu |= SPELL_ATTR0_CU_NEGATIVE;
    }
};

class bloodmage_vitality_casts : public AllSpellScript
{
public:
    bloodmage_vitality_casts() : AllSpellScript("bloodmage_vitality_casts",
        {ALLSPELLHOOK_CAN_PREPARE, ALLSPELLHOOK_ON_SPELL_CHECK_CAST, ALLSPELLHOOK_ON_BEFORE_EFFECTS,
            ALLSPELLHOOK_ON_CAST, ALLSPELLHOOK_ON_HIT_RESULT}) { }

    bool CanPrepare(Spell* spell, SpellCastTargets const*, AuraEffect const*) override
    {
        Player* player = spell->GetCaster()->ToPlayer();
        SpellInfo const* info = spell->GetSpellInfo();
        if (!spell->IsTriggered() && info->SpellFamilyName == 26 && info->PowerType == POWER_RAGE &&
            (info->ManaCost || info->ManaCostPercentage) && CanEmpower(player))
            spell->SetScriptValue(PooledVitalityTalent, GetEmpowerment(info->Id));
        return true;
    }

    void OnSpellCheckCast(Spell* spell, bool, SpellCastResult& result) override
    {
        if (spell->GetScriptValue(PooledVitalityTalent) && !CanEmpower(spell->GetCaster()->ToPlayer()))
            result = SPELL_FAILED_CASTER_AURASTATE;
    }

    void OnSpellBeforeEffects(Spell* spell, Unit* caster, SpellInfo const*) override
    {
        Player* player = caster->ToPlayer();
        if (!spell->GetScriptValue(PooledVitalityTalent) || spell->GetScriptValue(PooledVitality) ||
            !CanEmpower(player))
            return;
        spell->SetScriptValue(PooledVitality, 1);
        player->GetAura(PooledVitality, player->GetGUID())->ModStackAmount(-int32(VitalityCost));
    }

    void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const* info, bool) override
    {
        Player* player = caster->ToPlayer();
        if (!IsBloodmage(player) || spell->IsTriggered() || info->SpellFamilyName != 26)
            return;
        if (GetEmpowerment(info->Id) == Bloodbolt)
            player->RemoveAurasDueToSpell(SovereigntyBuff);
        if (!spell->GetScriptValue(PooledVitality) || spell->GetScriptValue(VitalityForLater))
            return;
        spell->SetScriptValue(VitalityForLater, 1);
        if (spell->GetScriptValue(PooledVitalityTalent))
        {
            if (player->HasAura(VitalityForLater))
                player->CastSpell(player, VitalityHeal, true);
        }
        else if (info->PowerType == POWER_HEALTH && player->HasAura(PooledVitalityTalent))
            player->CastSpell(player, PooledVitality, true);
    }

    void OnSpellHitResult(Spell* spell, Unit*, uint8 miss, uint32, uint32 healing, bool) override
    {
        Player* player = spell->GetCaster()->ToPlayer();
        if (!IsBloodmage(player) || spell->IsTriggered() || miss != SPELL_MISS_NONE || !healing ||
            spell->GetScriptValue(PooledVitalityTalent) != Mend || spell->GetScriptValue(MendSelfHeal))
            return;
        spell->SetScriptValue(MendSelfHeal, 1);
        uint32 maximum = uint32(std::nextafter(float(std::numeric_limits<int32>::max()), 0.0f));
        int32 amount = int32(std::min(healing / 2, maximum));
        if (amount)
            player->CastCustomSpell(player, MendSelfHeal, &amount, nullptr, nullptr, true);
    }
};

class bloodmage_vitality_scaling : public UnitScript
{
public:
    bloodmage_vitality_scaling() : UnitScript("bloodmage_vitality_scaling", true,
        {UNITHOOK_MODIFY_SPELL_EFFECT_BASE_VALUE, UNITHOOK_MODIFY_HEAL_RECEIVED,
            UNITHOOK_ON_AFTER_AURA_EFFECT_CALCULATE_AMOUNT}) { }

    void ModifySpellEffectBaseValue(Unit const* caster, SpellInfo const* info, uint8 index, float& value) override
    {
        if (!caster || !caster->IsPlayer() || caster->getClass() != CLASS_SON_OF_ARUGAL ||
            info->SpellFamilyName != 26 || index != EFFECT_0)
            return;

        uint32 const effect = info->Effects[EFFECT_0].Effect;
        if (effect != SPELL_EFFECT_HEAL && effect != SPELL_EFFECT_HEALTH_LEECH &&
            effect != SPELL_EFFECT_SCHOOL_DAMAGE)
            return;

        double bonus = 0.0;
        bool matched = false;
        if (effect == SPELL_EFFECT_HEAL || effect == SPELL_EFFECT_HEALTH_LEECH)
        {
            if (info->Id == VitalityHeal)
            {
                bonus += caster->GetStat(STAT_SPIRIT) * 0.5;
                matched = true;
            }
            else if (info->Id == Hemopulse)
            {
                bonus += caster->GetStat(STAT_SPIRIT) * 0.45 + caster->GetStat(STAT_STAMINA) * 0.35;
                matched = true;
            }
            else if (GetEmpowerment(info->Id) == Heartbreak)
            {
                int32 shadowPower = std::max(0,
                    const_cast<Unit*>(caster)->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_SHADOW));
                bonus += shadowPower * 0.5 + caster->GetStat(STAT_SPIRIT);
                matched = true;
            }
            else if (GetEmpowerment(info->Id) == Mend || sSpellMgr->GetFirstSpellInChain(info->Id) == DarkLiturgy)
            {
                bonus += caster->GetStat(STAT_SPIRIT) * 0.25;
                matched = true;
            }
            else if (info->Id == DarkfallenLamentLeech &&
                effect == SPELL_EFFECT_HEALTH_LEECH &&
                info->Effects[EFFECT_0].BonusMultiplier == 0)
            {
                SpellBonusEntry const* native = sSpellMgr->GetSpellBonusData(info->Id);
                if (!native || (native->direct_damage == 0 && native->ap_bonus == 0))
                {
                    float coefficient = 100.0f;
                    if (Player* owner = caster->GetSpellModOwner())
                        owner->ApplySpellMod(info->Id, SPELLMOD_BONUS_MULTIPLIER, coefficient);
                    int32 healingPower = std::max(0,
                        const_cast<Unit*>(caster)->SpellBaseHealingBonusDone(SPELL_SCHOOL_MASK_SHADOW));
                    bonus += healingPower * coefficient / 100.0f;
                    matched = true;
                }
            }
            else if (info->Id == BloodRitualsHeal)
            {
                bonus += caster->GetStat(STAT_STAMINA) * 0.085;
                matched = true;
            }
            else if (info->Id == HeartbreakAllyHeal)
            {
                bonus += caster->GetStat(STAT_SPIRIT);
                matched = true;
            }
            else if (info->Id == EnragingWound)
            {
                bonus += caster->GetStat(STAT_STAMINA) * 0.3;
                matched = true;
            }
        }

        if (effect == SPELL_EFFECT_SCHOOL_DAMAGE && info->Id == ShadowStrengthDamage)
        {
            bonus += caster->GetStat(STAT_STAMINA) * 0.25 + caster->GetStat(STAT_AGILITY) * 0.25;
            matched = true;
        }

        if (caster->HasAura(BloodmoonStrength) &&
            ((info->SpellFamilyFlags[1] & BloodmoonStrengthMask1) ||
             (info->SpellFamilyFlags[2] & BloodmoonStrengthMask2)))
        {
            bonus += 0.25 * double(caster->ToPlayer()->GetUInt32Value(uint32(PLAYER_FIELD_COMBAT_RATING_1) + uint32(CR_DODGE)));
            matched = true;
        }

        if (!matched)
            return;

        double amount = double(value) + bonus;
        if (std::isfinite(amount) && amount >= 0 &&
            double(float(amount)) <= std::numeric_limits<int32>::max())
            value = float(amount);
    }

    void ModifyHealReceivedFor(Unit* recipient, Unit* first, Unit* second, uint32& heal,
        SpellInfo const* spellInfo) override
    {
        if (!spellInfo || !heal)
            return;

        if (recipient)
            if (AuraEffect const* vital = recipient->GetAuraEffect(VitalShield, EFFECT_0))
                if (uint32(spellInfo->GetSchoolMask()) & uint32(vital->GetMiscValue()))
                    AddPct(heal, vital->GetAmount());

        if (spellInfo->Id == VampiricFeast && first == second && first)
            if (AuraEffect const* torture = first->GetAuraEffect(Torture, EFFECT_0))
                AddPct(heal, torture->GetAmount());
    }

    void OnAfterAuraEffectCalculateAmount(AuraEffect const* effect, Unit*, int32& amount) override
    {
        if (!effect || effect->GetAuraType() != SPELL_AURA_DAMAGE_SHIELD)
            return;
        SpellInfo const* info = effect->GetSpellInfo();
        if (!info || info->SpellFamilyName != 26)
            return;
        if (info->Id == Bloodthorns || info->Id == GreaterBloodthorns ||
            sSpellMgr->GetFirstSpellInChain(info->Id) == Bloodthorns)
            amount = effect->GetOldAmount();
    }
};

void SetHealthPct(Unit* unit, float pct)
{
    uint32 maximum = unit->GetMaxHealth();
    double health = double(maximum) * std::clamp(double(pct), 0.0, 100.0) / 100.0;
    unit->SetHealth(std::min<uint32>(maximum, std::max<uint32>(1, uint32(health + 0.5))));
}

class spell_ascension_bloodmage_transfusion : public SpellScript
{
    PrepareSpellScript(spell_ascension_bloodmage_transfusion);

    void Swap(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        if (!caster || !target || caster == target || !caster->IsAlive() || !target->IsAlive() ||
            !caster->GetMaxHealth() || !target->GetMaxHealth())
            return;
        float casterPct = caster->GetHealthPct();
        float targetPct = target->GetHealthPct();
        float lower = std::min(casterPct, targetPct);
        float raised = std::max(lower, float(GetEffectValue()));
        SetHealthPct(caster, targetPct > lower ? targetPct : raised);
        SetHealthPct(target, casterPct > lower ? casterPct : raised);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_bloodmage_transfusion::Swap,
            EFFECT_0, SPELL_EFFECT_SCRIPT_EFFECT);
    }
};

class spell_ascension_bloodmage_empowered : public SpellScript
{
    PrepareSpellScript(spell_ascension_bloodmage_empowered);
    bool _heartbreak = false;

    void SnapshotNightFeastRage()
    {
        Player* player = GetCaster()->ToPlayer();
        if (!player || player->getClass() != CLASS_SON_OF_ARUGAL ||
            GetEmpowerment(m_scriptSpellId) != Bloodbolt || !player->HasAura(NightFeast))
            return;
        GetSpell()->SetScriptValue(m_scriptSpellId, player->GetPower(POWER_RAGE));
    }

    bool Load() override
    {
        return GetCaster()->IsPlayer() && GetCaster()->getClass() == CLASS_SON_OF_ARUGAL &&
            GetSpellInfo()->SpellFamilyName == 26;
    }

    bool Empowered(Empowerment kind)
    {
        return !GetSpell()->IsTriggered() && GetSpell()->GetScriptValue(PooledVitalityTalent) == kind;
    }

    void HeartbreakPower(SpellEffIndex index)
    {
        if (GetSpellInfo()->Effects[index].TriggerSpell != HeartbreakBuff)
            return;
        PreventHitDefaultEffect(index);
        if (!Empowered(Heartbreak) || _heartbreak)
            return;
        _heartbreak = true;
        int32 amount = GetEffectValue();
        Unit* player = GetCaster();
        player->CastCustomSpell(player, HeartbreakBuff, &amount, &amount, nullptr, true);
        player->CastSpell(player, VisceralPower, true);
    }

    void ModifyHit()
    {
        Player* player = GetCaster()->ToPlayer();
        if (player && GetEmpowerment(m_scriptSpellId) == Bloodbolt &&
            player->HasAura(NightFeast) && GetHitDamage() > 0)
        {
            uint64 rage = GetSpell()->GetScriptValue(m_scriptSpellId);
            double multiplier = 1.0 + double(rage) / 1000.0;
            SetHitDamage(int32(std::min(double(GetHitDamage()) * multiplier,
                double(std::numeric_limits<int32>::max()))));
        }
        if (Empowered(Bloodbolt) && GetHitUnit() == GetExplTargetUnit() && GetHitDamage() > 0)
            SetHitDamage(int32(std::min<int64>(int64(GetHitDamage()) * 2, std::numeric_limits<int32>::max())));
        if (Empowered(Fleshcraft) && GetHitUnit() && GetHitUnit()->IsAlive() && GetHitHeal() > 0)
        {
            Unit* caster = GetCaster();
            Unit* target = GetHitUnit();
            uint32 bonus = caster->SpellHealingBonusDone(target, GetSpellInfo(),
                caster->CountPctFromMaxHealth(25), HEAL, EFFECT_0);
            bonus = target->SpellHealingBonusTaken(caster, GetSpellInfo(), bonus, HEAL);
            SetHitHeal(int32(std::min<int64>(int64(GetHitHeal()) + bonus, std::numeric_limits<int32>::max())));
        }
        if (GetSpellInfo()->Id == FleshcraftSpell)
            if (Unit* target = GetHitUnit(); target && target->IsAlive() && !target->HasAura(FleshcraftSated))
                GetCaster()->CastSpell(target, FleshcraftSated, TRIGGERED_FULL_MASK);
    }

    void Register() override
    {
        BeforeCast += SpellCastFn(spell_ascension_bloodmage_empowered::SnapshotNightFeastRage);
        if (GetEmpowerment(m_scriptSpellId) == Heartbreak)
            OnEffectLaunch += SpellEffectFn(spell_ascension_bloodmage_empowered::HeartbreakPower,
                EFFECT_1, SPELL_EFFECT_TRIGGER_SPELL_WITH_VALUE);
        OnHit += SpellHitFn(spell_ascension_bloodmage_empowered::ModifyHit);
    }
};

void SyncEmpoweredIndicator(Unit* unit)
{
    Player* player = unit ? unit->ToPlayer() : nullptr;
    if (!player || player->getClass() != CLASS_SON_OF_ARUGAL)
        return;
    if (!CanEmpower(player))
        player->RemoveAurasDueToSpell(EmpoweredIndicator, player->GetGUID());
    else if (!player->HasAura(EmpoweredIndicator, player->GetGUID()))
        player->CastSpell(player, EmpoweredIndicator, true);
}

class aura_ascension_bloodmage_empowered_indicator : public AuraScript
{
    PrepareAuraScript(aura_ascension_bloodmage_empowered_indicator);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({EmpoweredIndicator}); }

    void Sync(AuraEffect const*, AuraEffectHandleModes)
    {
        SyncEmpoweredIndicator(GetTarget());
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_bloodmage_empowered_indicator::Sync, EFFECT_FIRST_FOUND,
            SPELL_AURA_ANY, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_bloodmage_empowered_indicator::Sync,
            EFFECT_FIRST_FOUND, SPELL_AURA_ANY, AURA_EFFECT_HANDLE_REAL);
    }
};

constexpr uint32 EternalPresenceBuff = 560010;

class aura_ascension_eternal_presence : public AuraScript
{
    PrepareAuraScript(aura_ascension_eternal_presence);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({EternalPresenceBuff}); }

    bool Check(ProcEventInfo& event)
    {
        Unit* target = GetTarget();
        DamageInfo const* damage = event.GetDamageInfo();
        return target->IsPlayer() && target->IsAlive() && target->IsInWorld() &&
            event.GetActionTarget() == target && damage && damage->GetDamage();
    }

    void Proc(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        Unit* target = GetTarget();
        uint64 amount = uint64(event.GetDamageInfo()->GetDamage()) * std::clamp(effect->GetAmount(), 0, 100) / 100;
        if (amount && event.GetActor() && target->IsHostileTo(event.GetActor()) &&
            AscensionBattlegroundCombat::SharedTopLevel(target, event.GetActor()) != 0)
            amount = std::max<uint64>(1, uint64(std::llround(
                double(amount) * double(AscensionBattlegroundCombat::UnitUnscaledFactor(target)))));
        if (!amount)
            return;
        target->CastCustomSpell(EternalPresenceBuff, SPELLVALUE_BASE_POINT0,
            int32(std::min<uint64>(amount, std::numeric_limits<int32>::max())), target, TRIGGERED_FULL_MASK);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_eternal_presence::Check);
        OnEffectProc += AuraEffectProcFn(aura_ascension_eternal_presence::Proc, EFFECT_2, AuraType(354));
    }
};

constexpr uint32 EndureTheCurseHeal = 681189;

class aura_ascension_endure_the_curse : public AuraScript
{
    PrepareAuraScript(aura_ascension_endure_the_curse);
    bool _healed = false;

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({EndureTheCurseHeal}); }

    void Amount(AuraEffect const*, int32& amount, bool& recalculate)
    {
        amount = -1;
        recalculate = false;
    }

    void Absorb(AuraEffect*, DamageInfo& damage, uint32& absorb)
    {
        absorb = 0;
        Unit* target = GetTarget();
        if (_healed || !target->IsAlive() || !damage.GetDamage())
            return;
        if (uint64(target->GetHealth()) >= uint64(damage.GetDamage()) + target->CountPctFromMaxHealth(10))
            return;
        _healed = true;
        target->CastSpell(target, EndureTheCurseHeal, true);
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_ascension_endure_the_curse::Amount,
            EFFECT_0, SPELL_AURA_SCHOOL_ABSORB);
        OnEffectAbsorb += AuraEffectAbsorbFn(aura_ascension_endure_the_curse::Absorb, EFFECT_0);
    }
};
}

void AddSC_AscensionBloodmageVitality()
{
    new bloodmage_vitality_contracts();
    new bloodmage_vitality_casts();
    new bloodmage_vitality_scaling();
    RegisterSpellScript(spell_ascension_bloodmage_transfusion);
    RegisterSpellScript(spell_ascension_bloodmage_empowered);
    RegisterSpellScript(aura_ascension_bloodmage_empowered_indicator);
    RegisterSpellScript(aura_ascension_eternal_presence);
    RegisterSpellScript(aura_ascension_endure_the_curse);
}
