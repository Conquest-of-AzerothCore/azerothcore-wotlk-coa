/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Log.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"
#include <algorithm>
#include <limits>

namespace
{
enum RangerArcherySpells : uint32
{
    SPELL_ADVANTAGE = 804329,
    SPELL_ELUDE = 801345,
    SPELL_PIERCED = 705033,
    SPELL_PIERCED_BLEED = 782754,
    SPELL_MASTERFUL_ARCHERY_TRIGGER = 573450,
    SPELL_MASTERFUL_ARCHERY_BUFF = 680471,
    SPELL_HEADSHOTS_ONLY_BUFF = 573202,
    SPELL_BRUTAL_SHOT = 570014,
    SPELL_SKIRMISH_BRUTAL_SHOT_CRITICAL = 803335,
    SPELL_INCENDIARY_SHOT = 524870,
    SPELL_INCENDIARY_ARROWS = 524869,
    SPELL_INCENDIARY_EXPLOSION = 570182,
    SPELL_HAWKEYE = 800358,
    SPELL_HAWKEYE_ARROW = 801192
};

enum RangerArcheryChains : uint32
{
    CHAIN_SKULLPIERCER = 802036,
    CHAIN_PRECISION_SHOT = 500075,
    CHAIN_HUNTING_SHOT = 801191
};

constexpr uint32 RANGER_FAMILY = 27;
constexpr uint32 PRECISION_SHOT_FLAG = 8388608;
constexpr uint32 BRUTAL_SHOT_FLAG = 128;
constexpr int32 PIERCED_LINGERING_PCT = 35;
constexpr int32 PIERCED_LINGERING_TICKS = 2;
constexpr uint8 PRECISION_SHOT_BUFF_CHARGES = 1;
constexpr uint8 INCENDIARY_ARROWS_CHARGES = 3;

int32 ClampedPct(uint64 value, int32 pct)
{
    if (pct <= 0)
        return 0;
    return int32(std::min<uint64>(value * uint64(pct) / 100, uint64(std::numeric_limits<int32>::max())));
}

bool IsRangerSpell(SpellInfo const* info)
{
    return info && info->SpellFamilyName == RANGER_FAMILY;
}

bool IsPiercingShot(SpellInfo const* info)
{
    uint32 chain = sSpellMgr->GetFirstSpellInChain(info->Id);
    return IsRangerSpell(info) && (chain == CHAIN_SKULLPIERCER || chain == CHAIN_PRECISION_SHOT);
}

bool IsIncendiarySpender(Spell const* spell)
{
    SpellInfo const* info = spell->GetSpellInfo();
    return !spell->IsTriggered() && IsRangerSpell(info) && info->CasterAuraSpell == SPELL_ADVANTAGE &&
        sSpellMgr->GetFirstSpellInChain(info->Id) != SPELL_INCENDIARY_SHOT;
}

void ApplyPierced(Player* player, Unit* target, uint32 damage)
{
    if (!player->GetAuraEffect(SPELL_PIERCED, EFFECT_0))
        return;
    int32 dealt = int32(std::min<uint64>(damage, uint64(std::numeric_limits<int32>::max())));
    player->CastCustomSpell(SPELL_PIERCED_BLEED, SPELLVALUE_BASE_POINT0, dealt, target, TRIGGERED_FULL_MASK);
}

void TriggerIncendiaryExplosion(Spell* spell, Player* player, Unit* target, uint32 damage)
{
    Aura* arrows = player->GetAura(SPELL_INCENDIARY_ARROWS, player->GetGUID());
    SpellInfo const* explosion = sSpellMgr->GetSpellInfo(SPELL_INCENDIARY_EXPLOSION);
    if (!arrows || !explosion || spell->GetScriptValue(SPELL_INCENDIARY_ARROWS))
        return;
    AuraEffect const* share = arrows->GetEffect(EFFECT_0);
    if (!share)
        return;

    spell->SetScriptValue(SPELL_INCENDIARY_ARROWS, 1);
    SpellCastTargets targets;
    targets.SetUnitTarget(target);
    targets.SetDst(target->GetPosition());
    CustomSpellValues values;
    values.AddSpellMod(SPELLVALUE_BASE_POINT0, ClampedPct(damage, share->GetAmount()));
    player->CastSpell(targets, explosion, &values, TRIGGERED_FULL_MASK);
    arrows->DropCharge();
}

class aura_ascension_ranger_pierced_bleed : public AuraScript
{
    PrepareAuraScript(aura_ascension_ranger_pierced_bleed);

    int32 _dealt = 0;

    bool Validate(SpellInfo const* spellInfo) override
    {
        return spellInfo->Id == SPELL_PIERCED_BLEED && IsRangerSpell(spellInfo) &&
            spellInfo->Effects[EFFECT_0].IsAura(SPELL_AURA_PERIODIC_DAMAGE) &&
            spellInfo->HasAttribute(SPELL_ATTR5_EXTRA_INITIAL_PERIOD) && ValidateSpellInfo({ SPELL_PIERCED });
    }

    int32 ImmediateShare() const
    {
        Unit* caster = GetCaster();
        AuraEffect const* talent = caster ? caster->GetAuraEffect(SPELL_PIERCED, EFFECT_0) : nullptr;
        return talent ? ClampedPct(uint64(_dealt), talent->GetAmount()) : 0;
    }

    int32 LingeringShare() const
    {
        return ClampedPct(uint64(_dealt), PIERCED_LINGERING_PCT) / PIERCED_LINGERING_TICKS;
    }

    void Calculate(AuraEffect const*, int32& amount, bool& canBeRecalculated)
    {
        canBeRecalculated = true;
        _dealt = std::max(0, amount);
        amount = ImmediateShare();
    }

    void Tick(AuraEffect const* effect)
    {
        GetAura()->GetEffect(effect->GetEffIndex())->SetAmount(effect->GetTickNumber() <= 1 ? ImmediateShare() :
            LingeringShare());
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_ascension_ranger_pierced_bleed::Calculate, EFFECT_0,
            SPELL_AURA_PERIODIC_DAMAGE);
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_ascension_ranger_pierced_bleed::Tick, EFFECT_0,
            SPELL_AURA_PERIODIC_DAMAGE);
    }
};

class ranger_archery_hits : public AllSpellScript
{
public:
    ranger_archery_hits() : AllSpellScript("ranger_archery_hits",
        {ALLSPELLHOOK_CAN_PREPARE, ALLSPELLHOOK_ON_HIT_RESULT}) { }

    bool CanPrepare(Spell* spell, SpellCastTargets const*, AuraEffect const*) override
    {
        SpellInfo const* info = spell->GetSpellInfo();
        if (info->Id != SPELL_MASTERFUL_ARCHERY_TRIGGER || !IsRangerSpell(info))
            return true;
        Unit* caster = spell->GetCaster();
        return caster && caster->HasAura(SPELL_ELUDE);
    }

    void OnSpellHitResult(Spell* spell, Unit* target, uint8 miss, uint32 damage, uint32, bool critical) override
    {
        Player* player = spell->GetCaster()->ToPlayer();
        if (!player || player->getClass() != CLASS_RANGER || miss != SPELL_MISS_NONE || !damage || !target ||
            target == player || !target->IsAlive() || !IsRangerSpell(spell->GetSpellInfo()))
            return;
        if (critical && IsPiercingShot(spell->GetSpellInfo()))
            ApplyPierced(player, target, damage);
        if (IsIncendiarySpender(spell))
            TriggerIncendiaryExplosion(spell, player, target, damage);
    }
};

class aura_ascension_ranger_hawkeye : public AuraScript
{
    PrepareAuraScript(aura_ascension_ranger_hawkeye);

    bool Validate(SpellInfo const* spellInfo) override
    {
        SpellEffectInfo const& volley = spellInfo->Effects[EFFECT_0];
        return spellInfo->Id == SPELL_HAWKEYE && IsRangerSpell(spellInfo) && spellInfo->IsPassive() &&
            volley.Effect == SPELL_EFFECT_APPLY_AREA_AURA_ENEMY &&
            volley.IsAura(SPELL_AURA_PERIODIC_TRIGGER_SPELL) &&
            volley.TriggerSpell == SPELL_HAWKEYE_ARROW && ValidateSpellInfo({SPELL_HAWKEYE_ARROW});
    }

    bool IsMarkedEnemy(Unit* target)
    {
        Unit* ranger = GetUnitOwner();
        if (!target || !ranger || !ranger->IsPlayer() || ranger->ToPlayer()->getClass() != CLASS_RANGER)
            return false;
        return target == ranger ||
            (!ranger->IsFriendlyTo(target) && target->GetAuraOfRankedSpell(CHAIN_HUNTING_SHOT, ranger->GetGUID()));
    }

    void Register() override
    {
        DoCheckAreaTarget += AuraCheckAreaTargetFn(aura_ascension_ranger_hawkeye::IsMarkedEnemy);
    }
};

bool IsPrecisionShotBuff(SpellInfo const* info, uint32 spellId, uint8 effect, uint32 stacks)
{
    SpellEffectInfo const& modifier = info->Effects[effect];
    return info->Id == spellId && IsRangerSpell(info) && info->StackAmount == stacks && !info->ProcFlags &&
        modifier.IsAura(SPELL_AURA_ADD_PCT_MODIFIER) && modifier.MiscValue == SPELLMOD_DAMAGE &&
        modifier.SpellClassMask == flag96(0, PRECISION_SHOT_FLAG, 0);
}

void ApplyPrecisionShotBuffCharges(SpellInfo* info)
{
    if (info->Id != SPELL_HEADSHOTS_ONLY_BUFF && info->Id != SPELL_MASTERFUL_ARCHERY_BUFF)
        return;
    if ((IsPrecisionShotBuff(info, SPELL_HEADSHOTS_ONLY_BUFF, EFFECT_0, 10) ||
            IsPrecisionShotBuff(info, SPELL_MASTERFUL_ARCHERY_BUFF, EFFECT_1, 5)) &&
        (!info->ProcCharges || info->ProcCharges == PRECISION_SHOT_BUFF_CHARGES))
        info->ProcCharges = PRECISION_SHOT_BUFF_CHARGES;
    else
        LOG_ERROR("coa", "Skipped unexpected Precision Shot buff record {}", info->Id);
}

void ApplyIncendiaryArrowsCharges(SpellInfo* info)
{
    if (info->Id != SPELL_INCENDIARY_ARROWS)
        return;
    SpellEffectInfo const& share = info->Effects[EFFECT_0];
    if (IsRangerSpell(info) && share.IsAura(AuraType(354)) && share.TriggerSpell == SPELL_INCENDIARY_EXPLOSION &&
        !info->ProcFlags && (!info->ProcCharges || info->ProcCharges == INCENDIARY_ARROWS_CHARGES))
        info->ProcCharges = INCENDIARY_ARROWS_CHARGES;
    else
        LOG_ERROR("coa", "Skipped unexpected Incendiary Arrows record {}", info->Id);
}

void ApplyBrutalShotAttributes(SpellInfo* info)
{
    if (info->Id != SPELL_BRUTAL_SHOT)
        return;
    if (IsRangerSpell(info) && info->SpellFamilyFlags == flag96(BRUTAL_SHOT_FLAG, 0, 0) &&
        info->Effects[EFFECT_0].TargetA.GetTarget() == TARGET_UNIT_CONE_ENEMY_24)
        info->AttributesCu |= SPELL_ATTR0_CU_CONE_LINE | SPELL_ATTR0_CU_IGNORE_ARMOR;
    else
        LOG_ERROR("coa", "Skipped unexpected Brutal Shot record {}", info->Id);
}

void ApplySkirmishCriticalStrikeScope(SpellInfo* info)
{
    if (info->Id != SPELL_SKIRMISH_BRUTAL_SHOT_CRITICAL)
        return;
    SpellEffectInfo& critical = info->Effects[EFFECT_0];
    if (IsRangerSpell(info) && critical.IsAura(SPELL_AURA_ADD_FLAT_MODIFIER) &&
        critical.MiscValue == SPELLMOD_CRITICAL_CHANCE && critical.SpellClassMask[0] == BRUTAL_SHOT_FLAG)
        critical.SpellClassMask = flag96(BRUTAL_SHOT_FLAG, 0, 0);
    else
        LOG_ERROR("coa", "Skipped unexpected Skirmish critical strike record {}", info->Id);
}

class ranger_archery_contracts : public GlobalScript
{
public:
    ranger_archery_contracts() : GlobalScript("ranger_archery_contracts",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (!info)
            return;
        ApplyPrecisionShotBuffCharges(info);
        ApplyIncendiaryArrowsCharges(info);
        ApplyBrutalShotAttributes(info);
        ApplySkirmishCriticalStrikeScope(info);
    }
};
}

void AddSC_AscensionRangerArchery()
{
    RegisterSpellScript(aura_ascension_ranger_pierced_bleed);
    RegisterSpellScript(aura_ascension_ranger_hawkeye);
    new ranger_archery_hits();
    new ranger_archery_contracts();
}
