/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionDummyFixes.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "UnitScript.h"
#include <algorithm>
#include <array>
#include <initializer_list>
#include <mutex>
#include <unordered_map>
#include <unordered_set>
#include <vector>

namespace
{
template <std::size_t N>
bool IsOneOf(uint32 id, std::array<uint32, N> const& ids)
{
    return std::find(ids.begin(), ids.end(), id) != ids.end();
}

AuraEffect const* OwnGlyph(Unit const* unit, std::initializer_list<uint32> glyphs, uint32 stockGlyph, uint8 effIndex)
{
    for (uint32 glyph : glyphs)
        if (sSpellMgr->GetSpellTwinSource(glyph) != stockGlyph)
            if (AuraEffect const* effect = unit->GetAuraEffect(glyph, effIndex))
                return effect;
    return nullptr;
}

constexpr uint32 PRIEST_SWP_FLAG0 = 0x00008000;
constexpr uint32 PRIEST_MIND_BLAST_FLAG0 = 0x00002000;
constexpr uint32 PRIEST_SMITE_FLAG0 = 0x00000080;
constexpr uint32 PRIEST_HOLY_FIRE_FLAG0 = 0x00100000;
constexpr uint32 PRIEST_MIND_FLAY_FLAG0 = 0x00800000;
constexpr uint32 PRIEST_SW_DEATH_FLAG1 = 0x00000002;

bool IsPriestSpell(SpellInfo const* info, uint8 word, uint32 flag)
{
    return info && info->SpellFamilyName == SPELLFAMILY_PRIEST && (info->SpellFamilyFlags[word] & flag);
}

void CastCustomHeal(Unit* caster, Unit* target, uint32 healSpell, int32 amount)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(healSpell);
    if (!info || amount <= 0)
        return;
    int32 bp = amount - (info->Effects[EFFECT_0].DieSides ? 1 : 0);
    if (bp > 0)
        caster->CastCustomSpell(target, healSpell, &bp, nullptr, nullptr, true);
}

constexpr int32 GORE_PCT_PER_BLEED = 8;
constexpr int32 GORE_PCT_MAX = 40;

class spell_dummyfix_priest_shadow_word_gore : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_priest_shadow_word_gore);

    void CalcAmount(AuraEffect const* , int32& amount, bool& )
    {
        Unit* caster = GetCaster();
        Unit* target = GetUnitOwner();
        if (!caster || !target)
            return;
        std::unordered_set<uint32> bleeds;
        for (auto const& [id, application] : target->GetAppliedAuras())
        {
            Aura const* aura = application->GetBase();
            if (aura->GetId() == GetId() || aura->GetCasterGUID() != caster->GetGUID())
                continue;
            if (aura->GetSpellInfo()->GetAllEffectsMechanicMask() & (uint64(1) << MECHANIC_BLEED))
                bleeds.insert(aura->GetId());
        }
        AddPct(amount, std::min<int32>(GORE_PCT_MAX, GORE_PCT_PER_BLEED * int32(bleeds.size())));
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_dummyfix_priest_shadow_word_gore::CalcAmount, EFFECT_0,
            SPELL_AURA_PERIODIC_DAMAGE);
    }
};

constexpr uint32 BEACON_OF_SHADOW = 92779;
constexpr uint32 BEACON_OF_SHADOW_HEAL = 276988;
constexpr uint32 WARLOCK_SHADOW_BOLT_FLAG0 = 0x00000001;

std::mutex BeaconLock;
std::unordered_map<ObjectGuid, ObjectGuid> ShadowBeacons;

class spell_dummyfix_priest_beacon_of_shadow_cast : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_priest_beacon_of_shadow_cast);

    SpellCastResult CheckCast()
    {
        Unit* target = GetExplTargetUnit();
        if (!target || target == GetCaster())
            return SPELL_FAILED_BAD_TARGETS;
        return SPELL_CAST_OK;
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_dummyfix_priest_beacon_of_shadow_cast::CheckCast);
    }
};

class spell_dummyfix_priest_beacon_of_shadow : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_priest_beacon_of_shadow);

    void HandleApply(AuraEffect const* , AuraEffectHandleModes )
    {
        Unit* target = GetTarget();
        ObjectGuid const caster = GetCasterGUID();
        ObjectGuid previous;
        {
            std::lock_guard<std::mutex> lock(BeaconLock);
            auto const itr = ShadowBeacons.find(caster);
            if (itr != ShadowBeacons.end())
                previous = itr->second;
            ShadowBeacons[caster] = target->GetGUID();
        }
        if (previous && previous != target->GetGUID())
            if (Unit* old = ObjectAccessor::GetUnit(*target, previous))
                old->RemoveAurasDueToSpell(GetId(), caster);
    }

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        std::lock_guard<std::mutex> lock(BeaconLock);
        auto const itr = ShadowBeacons.find(GetCasterGUID());
        if (itr != ShadowBeacons.end() && itr->second == GetTarget()->GetGUID())
            ShadowBeacons.erase(itr);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_dummyfix_priest_beacon_of_shadow::HandleApply, EFFECT_0,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummyfix_priest_beacon_of_shadow::HandleRemove, EFFECT_0,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

void ShadowBoltHealsBeacon(Unit* attacker, int32 damage, SpellInfo const* info)
{
    if (damage <= 0 || !info || info->SpellFamilyName != SPELLFAMILY_WARLOCK ||
        !(info->SpellFamilyFlags[0] & WARLOCK_SHADOW_BOLT_FLAG0))
        return;
    ObjectGuid beaconGuid;
    {
        std::lock_guard<std::mutex> lock(BeaconLock);
        auto const itr = ShadowBeacons.find(attacker->GetGUID());
        if (itr == ShadowBeacons.end())
            return;
        beaconGuid = itr->second;
    }
    Unit* beacon = ObjectAccessor::GetUnit(*attacker, beaconGuid);
    if (!beacon || !beacon->IsAlive())
        return;
    AuraEffect const* effect = beacon->GetAuraEffect(BEACON_OF_SHADOW, EFFECT_0, attacker->GetGUID());
    if (!effect)
        return;
    CastCustomHeal(attacker, beacon, BEACON_OF_SHADOW_HEAL, int32(CalculatePct(damage, effect->GetAmount())));
}

struct TemporalShieldRule
{
    uint32 Shield;
    uint32 Heal;
};

constexpr std::array<TemporalShieldRule, 3> TEMPORAL_SHIELDS = {{
    { 283386, 954269 },
    { 954268, 954269 },
    { 1584443, 1584444 },
}};
constexpr uint64 TEMPORAL_SHIELD_RESTORE_PCT = 75;
constexpr uint32 TEMPORAL_SHIELD_TAKEN = 0;

class spell_dummyfix_priest_temporal_shield : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_priest_temporal_shield);

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        if (GetTargetApplication()->GetRemoveMode() != AURA_REMOVE_BY_EXPIRE)
            return;
        uint64 const restore = GetAura()->GetScriptValue(TEMPORAL_SHIELD_TAKEN) * TEMPORAL_SHIELD_RESTORE_PCT / 100;
        for (TemporalShieldRule const& rule : TEMPORAL_SHIELDS)
            if (rule.Shield == GetId())
                CastCustomHeal(GetTarget(), GetTarget(), rule.Heal, int32(std::min<uint64>(restore, INT32_MAX)));
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummyfix_priest_temporal_shield::HandleRemove, EFFECT_1,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

void CountTemporalShieldDamage(Unit* victim, uint32 damage)
{
    for (TemporalShieldRule const& rule : TEMPORAL_SHIELDS)
        if (Aura* shield = victim->GetAura(rule.Shield))
            shield->SetScriptValue(TEMPORAL_SHIELD_TAKEN, shield->GetScriptValue(TEMPORAL_SHIELD_TAKEN) + damage);
}

constexpr uint32 VAMPIRE_LORD_HEAL = 276986;
constexpr int32 VAMPIRE_LORD_PERIODIC_PCT = 2;

class spell_dummyfix_priest_vampire_lord : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_priest_vampire_lord);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        DamageInfo* damage = eventInfo.GetDamageInfo();
        SpellInfo const* info = damage ? damage->GetSpellInfo() : nullptr;
        if (!damage || !damage->GetDamage() || !info || !(damage->GetSchoolMask() & SPELL_SCHOOL_MASK_SHADOW))
            return false;
        return (eventInfo.GetTypeMask() & PROC_FLAG_DONE_PERIODIC) || !info->IsAffectingArea();
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* caster = GetTarget();
        int32 const pct = (eventInfo.GetTypeMask() & PROC_FLAG_DONE_PERIODIC) ? VAMPIRE_LORD_PERIODIC_PCT : aurEff->GetAmount();
        int32 const heal = int32(CalculatePct(eventInfo.GetDamageInfo()->GetDamage(), pct));
        if (heal > 0)
            caster->CastCustomSpell(VAMPIRE_LORD_HEAL, SPELLVALUE_BASE_POINT0, heal, caster, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_priest_vampire_lord::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_priest_vampire_lord::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

constexpr uint32 VOID_SHIFT = 954522;
constexpr uint32 VOID_INSTABILITY = 956037;

class spell_dummyfix_priest_void_shift : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_priest_void_shift);

    SpellCastResult CheckCast()
    {
        Unit* caster = GetCaster();
        Unit* target = GetExplTargetUnit();
        if (!target || target == caster)
            return SPELL_FAILED_BAD_TARGETS;
        if (caster->HasAura(VOID_INSTABILITY) || target->HasAura(VOID_INSTABILITY))
            return SPELL_FAILED_BAD_TARGETS;
        return SPELL_CAST_OK;
    }

    void HandleDummy(SpellEffIndex )
    {
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        if (!target || target == caster || !target->IsAlive())
            return;
        float const floor = GetSpellInfo()->Id == VOID_SHIFT ? 25.0f : 10.0f;
        float const casterPct = caster->GetHealthPct();
        float const targetPct = target->GetHealthPct();
        caster->SetHealth(std::max<uint32>(1, caster->CountPctFromMaxHealth(int32(std::max(targetPct, floor)))));
        target->SetHealth(std::max<uint32>(1, target->CountPctFromMaxHealth(int32(std::max(casterPct, floor)))));
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_dummyfix_priest_void_shift::CheckCast);
        OnEffectHitTarget += SpellEffectFn(spell_dummyfix_priest_void_shift::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

class spell_dummyfix_priest_devour_mind_extend : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_priest_devour_mind_extend);

    void HandleDummy(SpellEffIndex effIndex)
    {
        Unit* target = GetHitUnit();
        Unit* caster = GetCaster();
        uint32 const disease = uint32(GetSpellInfo()->Effects[effIndex].MiscValue);
        int32 const extra = GetEffectValue();
        if (!target || !disease || extra <= 0)
            return;
        Aura* aura = target->GetAura(disease, caster->GetGUID());
        if (!aura || aura->GetDuration() <= 0)
            return;
        int32 const duration = aura->GetDuration() + extra;
        if (duration > aura->GetMaxDuration())
            aura->SetMaxDuration(duration);
        aura->SetDuration(duration);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_dummyfix_priest_devour_mind_extend::HandleDummy, EFFECT_0,
            SPELL_EFFECT_DUMMY);
    }
};

class spell_dummyfix_priest_power_word_barrier : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_priest_power_word_barrier);

    bool Validate(SpellInfo const* info) override
    {
        return ValidateSpellInfo({ uint32(info->Effects[EFFECT_0].MiscValueB) });
    }

    void HandleAfterCast()
    {
        WorldLocation const* dest = GetExplTargetDest();
        if (!dest)
            return;
        GetCaster()->CastSpell(dest->GetPositionX(), dest->GetPositionY(), dest->GetPositionZ(),
            uint32(GetSpellInfo()->Effects[EFFECT_0].MiscValueB), true);
    }

    void Register() override
    {
        AfterCast += SpellCastFn(spell_dummyfix_priest_power_word_barrier::HandleAfterCast);
    }
};

constexpr uint32 MIND_SHOCK = 965738;
constexpr uint32 DARKNESS = 965739;
constexpr int32 MIND_SHOCK_DAMAGE_PCT = 30;

void ResetMindBlast(Player* player)
{
    std::vector<uint32> reset;
    for (auto const& [spellId, cooldown] : player->GetSpellCooldownMap())
        if (IsPriestSpell(sSpellMgr->GetSpellInfo(spellId), 0, PRIEST_MIND_BLAST_FLAG0))
            reset.push_back(spellId);
    for (uint32 spellId : reset)
        player->RemoveSpellCooldown(spellId, true);
}

class spell_dummyfix_priest_mind_blast_reset : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_priest_mind_blast_reset);

    void HandleDummy(SpellEffIndex )
    {
        Player* player = GetCaster()->ToPlayer();
        if (!player)
            return;
        ResetMindBlast(player);
        if (GetSpellInfo()->Id == DARKNESS && player->HasAura(MIND_SHOCK))
            player->m_Events.AddEventAtOffset([player]() { player->RemoveAurasDueToSpell(MIND_SHOCK); }, 1ms);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_dummyfix_priest_mind_blast_reset::HandleDummy, EFFECT_0,
            SPELL_EFFECT_DUMMY);
    }
};

constexpr uint32 WEAK_SPIRITED = 886381;

class spell_dummyfix_priest_leap_of_faith : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_priest_leap_of_faith);

    SpellCastResult CheckCast()
    {
        if (Unit* target = GetExplTargetUnit())
            if (target->HasAura(WEAK_SPIRITED))
                return SPELL_FAILED_BAD_TARGETS;
        return SPELL_CAST_OK;
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_dummyfix_priest_leap_of_faith::CheckCast);
    }
};

class spell_dummyfix_priest_angel_bolt : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_priest_angel_bolt);

    bool Validate(SpellInfo const* info) override
    {
        return ValidateSpellInfo({ uint32(info->Effects[EFFECT_0].MiscValue) });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        DamageInfo* damage = eventInfo.GetDamageInfo();
        return damage && damage->GetDamage() && eventInfo.GetProcTarget() && damage->GetSpellInfo() &&
            damage->GetSpellInfo()->Id != uint32(GetSpellInfo()->Effects[EFFECT_0].MiscValue);
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        int32 const amount = int32(CalculatePct(eventInfo.GetDamageInfo()->GetDamage(), aurEff->GetAmount()));
        if (amount > 0)
            GetTarget()->CastCustomSpell(uint32(GetSpellInfo()->Effects[EFFECT_0].MiscValue), SPELLVALUE_BASE_POINT0,
                amount, eventInfo.GetProcTarget(), true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_priest_angel_bolt::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_priest_angel_bolt::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

constexpr uint32 SPIRIT_FROST_BLOCKER = 271351;
constexpr uint32 SPIRIT_FROST = 271316;

class spell_dummyfix_priest_spirit_frost : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_priest_spirit_frost);

    void HandleBlocker(AuraEffect const* aurEff, ProcEventInfo& )
    {
        PreventDefaultAction();
        Unit* target = GetTarget();
        if (target->HasAura(SPIRIT_FROST_BLOCKER))
        {
            target->RemoveAurasDueToSpell(SPIRIT_FROST_BLOCKER);
            target->CastSpell(target, SPIRIT_FROST, true, nullptr, aurEff);
        }
        else
            target->CastSpell(target, SPIRIT_FROST_BLOCKER, true, nullptr, aurEff);
    }

    void HandleGrant(AuraEffect const* , ProcEventInfo& )
    {
        PreventDefaultAction();
    }

    void Register() override
    {
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_priest_spirit_frost::HandleBlocker, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_priest_spirit_frost::HandleGrant, EFFECT_1,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

struct PreservationRule
{
    uint32 Channel;
    uint32 FinalTick;
};

constexpr std::array<PreservationRule, 3> PRESERVATION = {{
    { 276250, 276270 },
    { 888571, 888594 },
    { 1576669, 276270 },
}};

class spell_dummyfix_priest_prayer_of_preservation : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_priest_prayer_of_preservation);

    void HandlePeriodic(AuraEffect const* aurEff)
    {
        int32 const total = aurEff->GetTotalTicks();
        Unit* caster = GetCaster();
        if (!caster || total <= 0 || aurEff->GetTickNumber() < uint32(total))
            return;
        for (PreservationRule const& rule : PRESERVATION)
            if (rule.Channel == GetId())
                caster->CastSpell(caster, rule.FinalTick, true, nullptr, aurEff);
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_dummyfix_priest_prayer_of_preservation::HandlePeriodic, EFFECT_1,
            SPELL_AURA_PERIODIC_TRIGGER_SPELL);
    }
};

constexpr uint32 MADNESS_OF_THE_OLD_GODS_TALENT = 272960;
constexpr uint32 MADNESS_OF_THE_OLD_GODS = 272952;

class spell_dummyfix_priest_tentacle_madness : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_priest_tentacle_madness);

    void HandleAfterCast()
    {
        Unit* caster = GetCaster();
        if (caster->HasAura(MADNESS_OF_THE_OLD_GODS_TALENT))
            caster->CastSpell(caster, MADNESS_OF_THE_OLD_GODS, true);
    }

    void Register() override
    {
        AfterCast += SpellCastFn(spell_dummyfix_priest_tentacle_madness::HandleAfterCast);
    }
};

constexpr uint32 SCREAMS_OF_THE_PAST = 982441;

bool KnowsAnyRank(Player const* player, uint32 spell)
{
    for (SpellInfo const* rank = sSpellMgr->GetSpellInfo(sSpellMgr->GetFirstSpellInChain(spell)); rank;
         rank = rank->GetNextRankSpell())
        if (player->HasSpell(rank->Id))
            return true;
    return false;
}

class spell_dummyfix_priest_screams_of_the_past : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_priest_screams_of_the_past);

    bool _taught = false;

    void HandleApply(AuraEffect const* aurEff, AuraEffectHandleModes )
    {
        Player* player = GetTarget()->ToPlayer();
        uint32 const required = uint32(GetSpellInfo()->Effects[aurEff->GetEffIndex()].MiscValue);
        if (!player || player->HasSpell(SCREAMS_OF_THE_PAST) || !sSpellMgr->GetSpellInfo(required) ||
            !KnowsAnyRank(player, required))
            return;
        player->learnSpell(SCREAMS_OF_THE_PAST, true);
        _taught = true;
    }

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        Player* player = GetTarget()->ToPlayer();
        if (!player || !_taught)
            return;
        _taught = false;
        player->removeSpell(SCREAMS_OF_THE_PAST, SPEC_MASK_ALL, true);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_dummyfix_priest_screams_of_the_past::HandleApply, EFFECT_0,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummyfix_priest_screams_of_the_past::HandleRemove, EFFECT_0,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

constexpr uint32 FROST_RESERVE = 81522;
constexpr uint32 SHAMAN_WATER_SHIELD_FLAG1 = 0x00000020;

Aura* WaterShield(Unit const* unit)
{
    AuraEffect* regen = unit->GetAuraEffect(SPELL_AURA_MOD_POWER_REGEN, SPELLFAMILY_SHAMAN, 0, SHAMAN_WATER_SHIELD_FLAG1, 0);
    return regen ? regen->GetBase() : nullptr;
}

bool IsDirectFrostDamage(SpellInfo const* info)
{
    return info && (info->GetSchoolMask() & SPELL_SCHOOL_MASK_FROST) && info->HasEffect(SPELL_EFFECT_SCHOOL_DAMAGE);
}

void FrostReserveBonus(Unit* attacker, int32& damage, SpellInfo const* info)
{
    if (!IsDirectFrostDamage(info))
        return;
    AuraEffect const* reserve = attacker->GetAuraEffect(FROST_RESERVE, EFFECT_0);
    Aura const* shield = reserve ? WaterShield(attacker) : nullptr;
    if (shield && shield->GetCharges() > 0)
        AddPct(damage, reserve->GetAmount() * shield->GetCharges());
}

class spell_dummyfix_priest_frost_reserve : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_priest_frost_reserve);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        DamageInfo* damage = eventInfo.GetDamageInfo();
        return damage && IsDirectFrostDamage(damage->GetSpellInfo());
    }

    void HandleProc(AuraEffect const* , ProcEventInfo& )
    {
        PreventDefaultAction();
        if (Aura* shield = WaterShield(GetTarget()))
            if (shield->GetCharges() > 0)
                shield->DropCharge();
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_priest_frost_reserve::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_priest_frost_reserve::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

constexpr uint32 PREDATORS_SWIFTNESS = 69369;
constexpr uint32 PREDATORY_NATURE_ENCHANT = 979050;
constexpr uint32 PREDATORY_NATURE_STACK = 979051;
constexpr uint32 PREDATORY_NATURE_FULL = 979055;

void PredatoryNature(Unit* unit)
{
    Aura const* stacks = unit->GetAura(PREDATORY_NATURE_STACK);
    bool const full = stacks && stacks->GetStackAmount() >= stacks->GetSpellInfo()->StackAmount;
    unit->CastSpell(unit, PREDATORY_NATURE_STACK, true);
    if (!full)
        return;
    Unit* target = nullptr;
    if (Player* player = unit->ToPlayer())
        target = ObjectAccessor::GetUnit(*player, player->GetTarget());
    unit->CastSpell(target ? target : unit, PREDATORY_NATURE_FULL, true);
}

constexpr uint32 GLYPH_OF_MIND_FLAY = 118221;
constexpr uint32 GLYPH_OF_SMITE = 118230;
constexpr uint32 GLYPH_OF_POWER_WORD_SHIELD = 118165;
constexpr uint32 GLYPH_OF_GUARDIAN_SPIRIT = 118731;
constexpr uint32 GLYPH_OF_SW_DEATH = 118197;
constexpr uint32 GLYPH_OF_SW_DEATH_REBORN = 1155682;
constexpr uint32 STOCK_GLYPH_OF_MIND_FLAY = 55687;
constexpr uint32 STOCK_GLYPH_OF_SMITE = 55692;
constexpr uint32 STOCK_GLYPH_OF_POWER_WORD_SHIELD = 55672;
constexpr uint32 STOCK_GLYPH_OF_GUARDIAN_SPIRIT = 63231;
constexpr uint32 STOCK_GLYPH_OF_SW_DEATH = 55682;
constexpr uint32 GLYPH_OF_POWER_WORD_SHIELD_HEAL = 56160;
constexpr uint32 GUARDIAN_SPIRIT = 47788;
constexpr std::array<uint32, 2> SW_DEATH_BACKLASH = { 32409, 1132409 };

constexpr uint32 MOLTEN_CORE = 71165;
constexpr uint32 MIND_CORE_TALENT = 283042;
constexpr uint32 MIND_CORE = 283040;
constexpr uint32 FINGERS_OF_FROST = 74396;
constexpr uint32 FINGERS_OF_DEATH_TALENT = 274179;
constexpr uint32 FINGERS_OF_DEATH = 274171;

constexpr uint32 DISPERSION = 47585;
constexpr std::array<uint32, 2> BLINDING_DISPERSION = { 283428, 954634 };
constexpr uint32 BLINDING_DISPERSION_NOVA = 283429;

constexpr uint32 BITING_COLD_TALENT = 282134;
constexpr uint32 BITING_COLD_ENCHANT = 81526;
constexpr uint32 BITING_COLD_STACK = 990270;
constexpr int32 BITING_COLD_PCT = 33;
constexpr uint32 MAGE_DEEP_FREEZE_FLAG1 = 0x00100000;
constexpr uint32 MAGE_DEEP_FREEZE_DAMAGE_FLAG2 = 0x00000020;

void BitingCold(Unit* attacker, SpellInfo const* info)
{
    Player* mage = attacker->ToPlayer();
    if (!mage)
        return;
    bool const enchant = mage->HasAura(BITING_COLD_ENCHANT);
    if (!enchant && !mage->HasAura(BITING_COLD_TALENT))
        return;
    if (info->SpellFamilyName == SPELLFAMILY_MAGE && (info->SpellFamilyFlags[2] & MAGE_DEEP_FREEZE_DAMAGE_FLAG2))
    {
        std::vector<std::pair<uint32, int32>> cuts;
        for (auto const& [spellId, cooldown] : mage->GetSpellCooldownMap())
        {
            SpellInfo const* freeze = sSpellMgr->GetSpellInfo(spellId);
            if (freeze && freeze->SpellFamilyName == SPELLFAMILY_MAGE && (freeze->SpellFamilyFlags[1] & MAGE_DEEP_FREEZE_FLAG1))
                cuts.emplace_back(spellId, int32(CalculatePct(std::max(freeze->RecoveryTime, freeze->CategoryRecoveryTime),
                    BITING_COLD_PCT)));
        }
        for (auto const& [spellId, cut] : cuts)
            if (cut > 0)
                mage->ModifySpellCooldown(spellId, -cut);
    }
    if (enchant && info->CastTimeEntry && info->CastTimeEntry->CastTime > 0)
        mage->CastSpell(mage, BITING_COLD_STACK, true);
}

bool IsPowerWordShield(SpellInfo const* info)
{
    return IsPriestSpell(info, 0, 0x1) && (info->SpellFamilyFlags[2] & 0x400);
}

class dummyfix_priest_unit_hooks : public UnitScript
{
public:
    dummyfix_priest_unit_hooks() : UnitScript("dummyfix_priest_unit_hooks", true,
        { UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN, UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK, UNITHOOK_ON_DAMAGE,
          UNITHOOK_ON_AURA_APPLY, UNITHOOK_ON_AURA_REMOVE }) { }

    void ModifySpellDamageTaken(Unit* target, Unit* attacker, int32& damage, SpellInfo const* info) override
    {
        if (!target || !attacker || !info || damage <= 0 || attacker == target)
            return;
        ObjectGuid const caster = attacker->GetGUID();
        if (IsPriestSpell(info, 0, PRIEST_MIND_FLAY_FLAG0))
        {
            if (AuraEffect const* glyph = OwnGlyph(attacker, { GLYPH_OF_MIND_FLAY }, STOCK_GLYPH_OF_MIND_FLAY, EFFECT_0))
                if (target->GetAuraEffect(SPELL_AURA_PERIODIC_DAMAGE, SPELLFAMILY_PRIEST, PRIEST_SWP_FLAG0, 0, 0, caster))
                    AddPct(damage, glyph->GetAmount());
        }
        else if (IsPriestSpell(info, 0, PRIEST_SMITE_FLAG0))
        {
            if (AuraEffect const* glyph = OwnGlyph(attacker, { GLYPH_OF_SMITE }, STOCK_GLYPH_OF_SMITE, EFFECT_0))
                if (target->GetAuraEffect(SPELL_AURA_PERIODIC_DAMAGE, SPELLFAMILY_PRIEST, PRIEST_HOLY_FIRE_FLAG0, 0, 0,
                    caster))
                    AddPct(damage, glyph->GetAmount());
        }
        else if (IsPriestSpell(info, 1, PRIEST_SW_DEATH_FLAG1))
        {
            if (AuraEffect const* glyph = OwnGlyph(attacker, { GLYPH_OF_SW_DEATH, GLYPH_OF_SW_DEATH_REBORN },
                STOCK_GLYPH_OF_SW_DEATH, EFFECT_1))
            {
                AuraEffect const* threshold = glyph->GetBase()->GetEffect(EFFECT_0);
                float const below = (threshold ? float(threshold->GetAmount()) : 35.0f) - target->GetHealthPct();
                if (below > 0.0f)
                    AddPct(damage, glyph->GetAmount() * below);
            }
        }
        else if (IsPriestSpell(info, 0, PRIEST_MIND_BLAST_FLAG0) && attacker->HasAura(MIND_SHOCK))
            AddPct(damage, MIND_SHOCK_DAMAGE_PCT);

        if (attacker->IsPlayer())
        {
            ShadowBoltHealsBeacon(attacker, damage, info);
            BitingCold(attacker, info);
            FrostReserveBonus(attacker, damage, info);
        }
    }

    void ModifyPeriodicDamageAurasTick(Unit* target, Unit* attacker, uint32& damage, SpellInfo const* info) override
    {
        if (!target || target != attacker || !info || !damage || !IsOneOf(info->Id, SW_DEATH_BACKLASH))
            return;
        if (AuraEffect const* glyph = OwnGlyph(target, { GLYPH_OF_SW_DEATH, GLYPH_OF_SW_DEATH_REBORN },
            STOCK_GLYPH_OF_SW_DEATH, EFFECT_2))
            damage = uint32(uint64(damage) * uint32(std::max(0, 100 - glyph->GetAmount())) / 100);
    }

    void OnDamage(Unit* , Unit* victim, uint32& damage) override
    {
        if (victim && damage)
            CountTemporalShieldDamage(victim, damage);
    }

    void OnAuraApply(Unit* unit, Aura* aura) override
    {
        if (!unit || !aura)
            return;
        uint32 const source = sSpellMgr->GetSpellTwinSource(aura->GetId());
        if (source == MOLTEN_CORE && unit->HasAura(MIND_CORE_TALENT))
            unit->CastSpell(unit, MIND_CORE, true);
        if (source == FINGERS_OF_FROST && unit->HasAura(FINGERS_OF_DEATH_TALENT))
            unit->CastSpell(unit, FINGERS_OF_DEATH, true);
        if (IsPowerWordShield(aura->GetSpellInfo()))
        {
            Unit* caster = aura->GetCaster();
            AuraEffect const* absorb = aura->GetEffect(EFFECT_0);
            if (!caster || !absorb)
                return;
            if (AuraEffect const* glyph = OwnGlyph(caster, { GLYPH_OF_POWER_WORD_SHIELD },
                STOCK_GLYPH_OF_POWER_WORD_SHIELD, EFFECT_0))
            {
                int32 heal = glyph->GetAmount() * absorb->GetAmount() / 100;
                if (heal > 0)
                    caster->CastCustomSpell(unit, GLYPH_OF_POWER_WORD_SHIELD_HEAL, &heal, nullptr, nullptr, true, nullptr,
                        absorb);
            }
        }
    }

    void OnAuraRemove(Unit* unit, AuraApplication* aurApp, AuraRemoveMode mode) override
    {
        if (!unit || !aurApp)
            return;
        Aura const* aura = aurApp->GetBase();
        uint32 const source = sSpellMgr->GetSpellTwinSource(aura->GetId());
        if (source == PREDATORS_SWIFTNESS && aura->GetDuration() > 0 &&
            (mode == AURA_REMOVE_BY_DEFAULT || mode == AURA_REMOVE_BY_EXPIRE) && unit->HasAura(PREDATORY_NATURE_ENCHANT))
            PredatoryNature(unit);
        if (source == DISPERSION && mode != AURA_REMOVE_BY_DEATH)
            for (uint32 talent : BLINDING_DISPERSION)
                if (unit->HasAura(talent))
                {
                    unit->CastSpell(unit, BLINDING_DISPERSION_NOVA, true);
                    break;
                }
        if (source == GUARDIAN_SPIRIT && mode == AURA_REMOVE_BY_EXPIRE)
        {
            Player* priest = aura->GetCaster() ? aura->GetCaster()->ToPlayer() : nullptr;
            if (!priest || !priest->HasSpellCooldown(aura->GetId()))
                return;
            if (AuraEffect const* glyph = OwnGlyph(priest, { GLYPH_OF_GUARDIAN_SPIRIT }, STOCK_GLYPH_OF_GUARDIAN_SPIRIT,
                EFFECT_0))
            {
                int32 const reset = glyph->GetAmount() * IN_MILLISECONDS;
                int32 const remaining = int32(priest->GetSpellCooldownDelay(aura->GetId()));
                if (remaining > reset)
                    priest->ModifySpellCooldown(aura->GetId(), reset - remaining);
            }
        }
    }
};
}

void ApplyAscensionDummyFixPriestContracts(SpellInfo* )
{
}

void AddAscensionDummyFixPriestScripts()
{
    RegisterSpellScript(spell_dummyfix_priest_shadow_word_gore);
    RegisterSpellScript(spell_dummyfix_priest_beacon_of_shadow_cast);
    RegisterSpellScript(spell_dummyfix_priest_beacon_of_shadow);
    RegisterSpellScript(spell_dummyfix_priest_temporal_shield);
    RegisterSpellScript(spell_dummyfix_priest_vampire_lord);
    RegisterSpellScript(spell_dummyfix_priest_void_shift);
    RegisterSpellScript(spell_dummyfix_priest_devour_mind_extend);
    RegisterSpellScript(spell_dummyfix_priest_power_word_barrier);
    RegisterSpellScript(spell_dummyfix_priest_mind_blast_reset);
    RegisterSpellScript(spell_dummyfix_priest_leap_of_faith);
    RegisterSpellScript(spell_dummyfix_priest_angel_bolt);
    RegisterSpellScript(spell_dummyfix_priest_spirit_frost);
    RegisterSpellScript(spell_dummyfix_priest_prayer_of_preservation);
    RegisterSpellScript(spell_dummyfix_priest_tentacle_madness);
    RegisterSpellScript(spell_dummyfix_priest_screams_of_the_past);
    RegisterSpellScript(spell_dummyfix_priest_frost_reserve);
    new dummyfix_priest_unit_hooks();
}
