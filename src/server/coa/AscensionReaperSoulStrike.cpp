/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionReaperSoulStrike.h"
#include "Player.h"
#include "Spell.h"
#include "SpellMgr.h"
#include <algorithm>
#include <limits>

namespace
{
constexpr uint32 REAPER_SPELL_FAMILY = 36;
constexpr uint32 SPELL_SOUL_STRIKE_FIRST = 500517;
constexpr uint32 SPELL_SOUL_STRIKE_FIFTH = 500521;
constexpr uint32 SPELL_SOUL_STRIKE_SIXTH = 500646;
constexpr uint32 SPELL_SOUL_STRIKE_LEECH_PERCENT = 573293;
constexpr uint32 SPELL_SOUL_STRIKE_MISSING_HEALTH_PERCENT = 500574;
constexpr uint32 SPELL_SOUL_STRIKE_HEAL = 500522;
constexpr uint8 SOUL_STRIKE_HEAL_EVENT = 18;

bool IsSoulStrike(SpellInfo const* info)
{
    return info && info->SpellFamilyName == REAPER_SPELL_FAMILY &&
        info->SpellFamilyFlags == flag96(0, 2048, 0) &&
        ((info->Id >= SPELL_SOUL_STRIKE_FIRST && info->Id <= SPELL_SOUL_STRIKE_FIFTH) ||
            info->Id == SPELL_SOUL_STRIKE_SIXTH) &&
        info->Effects[EFFECT_0].Effect == SPELL_EFFECT_WEAPON_PERCENT_DAMAGE &&
        info->Effects[EFFECT_1].Effect == SPELL_EFFECT_NORMALIZED_WEAPON_DMG &&
        !info->Effects[EFFECT_2].Effect;
}

bool IsSoulStrikeHealingContract(SpellInfo const* leech, SpellInfo const* missing, SpellInfo const* heal)
{
    return leech && missing && heal &&
        leech->SpellFamilyName == REAPER_SPELL_FAMILY &&
        leech->SpellFamilyFlags == flag96(0, 0, 64) &&
        leech->Effects[EFFECT_0].IsAura(AuraType(354)) &&
        leech->Effects[EFFECT_0].BasePoints == 79 && leech->Effects[EFFECT_0].DieSides == 1 &&
        leech->Effects[EFFECT_0].TriggerSpell == SPELL_SOUL_STRIKE_HEAL &&
        missing->SpellFamilyName == REAPER_SPELL_FAMILY &&
        missing->SpellFamilyFlags == flag96(0, 0, 2097152) &&
        missing->Effects[EFFECT_0].Effect == SPELL_EFFECT_HEAL_PCT &&
        missing->Effects[EFFECT_0].BasePoints == 9 && missing->Effects[EFFECT_0].DieSides == 1 &&
        heal->SpellFamilyName == REAPER_SPELL_FAMILY &&
        !heal->SpellFamilyFlags && heal->DmgClass == SPELL_DAMAGE_CLASS_NONE &&
        heal->Effects[EFFECT_0].Effect == SPELL_EFFECT_HEAL &&
        heal->Effects[EFFECT_0].TargetA.GetTarget() == TARGET_UNIT_CASTER &&
        !heal->Effects[EFFECT_0].TargetB.GetTarget() &&
        !heal->Effects[EFFECT_0].BonusMultiplier && !sSpellMgr->GetSpellBonusData(heal->Id) &&
        !heal->Effects[EFFECT_1].Effect && !heal->Effects[EFFECT_2].Effect &&
        heal->HasAttribute(SPELL_ATTR2_CANT_CRIT) && heal->HasAttribute(SPELL_ATTR3_IGNORE_CASTER_MODIFIERS);
}
}

void HandleAscensionReaperSoulStrikeHit(Spell* spell, Player* player,
    Unit* target, uint8 missInfo)
{
    if (!spell || !player || player != spell->GetCaster() || player->getClass() != CLASS_REAPER ||
        !player->IsAlive() || !target || target == player ||
        player->IsFriendlyTo(target) || missInfo != SPELL_MISS_NONE || !IsSoulStrike(spell->GetSpellInfo()))
        return;

    SpellInfo const* leech = sSpellMgr->GetSpellInfo(SPELL_SOUL_STRIKE_LEECH_PERCENT);
    SpellInfo const* missing = sSpellMgr->GetSpellInfo(SPELL_SOUL_STRIKE_MISSING_HEALTH_PERCENT);
    SpellInfo const* heal = sSpellMgr->GetSpellInfo(SPELL_SOUL_STRIKE_HEAL);
    if (!IsSoulStrikeHealingContract(leech, missing, heal) ||
        !spell->TryMarkScriptEventHandled(SOUL_STRIKE_HEAL_EVENT))
        return;

    uint32 leechPercent = uint32(std::max(0, leech->Effects[EFFECT_0].CalcValue(player)));
    uint32 missingPercent = uint32(std::max(0, missing->Effects[EFFECT_0].CalcValue(player)));
    uint32 missingHealth = player->GetMaxHealth() - std::min(player->GetHealth(), player->GetMaxHealth());
    uint64 amount = uint64(spell->GetScriptHealthLeechDamage()) * leechPercent / 100 +
        uint64(missingHealth) * missingPercent / 100;
    amount = std::min(amount, uint64(std::numeric_limits<int32>::max()));

    if (amount)
        player->CastCustomSpell(SPELL_SOUL_STRIKE_HEAL, SPELLVALUE_BASE_POINT0,
            int32(amount), player, TRIGGERED_FULL_MASK);
}
