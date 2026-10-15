/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionReaperPainmail.h"
#include "Player.h"
#include "Spell.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include <algorithm>
#include <array>

namespace
{
constexpr uint32 REAPER_SPELL_FAMILY = 36;
constexpr uint32 SPELL_PAINMAIL_TALENT = 801325;
constexpr uint32 SPELL_PAINMAIL_STACK_HELPER = 800171;
constexpr uint32 SPELL_PAINMAIL = 801324;
constexpr uint32 SPELL_PAINMAIL_HEAL = 805969;
constexpr uint32 SPELL_PAINMAIL_COOLDOWN = 807380;
constexpr uint32 SPELL_BOLSTERED_FORM = 680337;
constexpr std::array<uint32, 21> PAINMAIL_ATTACKS =
{
    500357, 504056, 504057, 504058, 504557, 505151, 573302, 573303,
    803992, 503286, 503287, 503288, 503289, 503324, 503531,
    500517, 500518, 500519, 500520, 500521, 500646
};

bool IsPainmailAttack(SpellInfo const* info)
{
    return info && info->SpellFamilyName == REAPER_SPELL_FAMILY &&
        std::find(PAINMAIL_ATTACKS.begin(), PAINMAIL_ATTACKS.end(), info->Id) != PAINMAIL_ATTACKS.end() &&
        ((info->Effects[EFFECT_0].Effect == SPELL_EFFECT_WEAPON_PERCENT_DAMAGE &&
            info->Effects[EFFECT_1].Effect == SPELL_EFFECT_NORMALIZED_WEAPON_DMG) ||
            (info->Effects[EFFECT_0].Effect == SPELL_EFFECT_NORMALIZED_WEAPON_DMG &&
                info->Effects[EFFECT_1].Effect == SPELL_EFFECT_WEAPON_PERCENT_DAMAGE)) &&
        !info->Effects[EFFECT_2].Effect;
}

bool HasPainmailContract()
{
    SpellInfo const* talent = sSpellMgr->GetSpellInfo(SPELL_PAINMAIL_TALENT);
    SpellInfo const* stack = sSpellMgr->GetSpellInfo(SPELL_PAINMAIL_STACK_HELPER);
    SpellInfo const* aura = sSpellMgr->GetSpellInfo(SPELL_PAINMAIL);
    SpellInfo const* heal = sSpellMgr->GetSpellInfo(SPELL_PAINMAIL_HEAL);
    SpellInfo const* cooldown = sSpellMgr->GetSpellInfo(SPELL_PAINMAIL_COOLDOWN);
    if (!talent || !stack || !aura || !heal || !cooldown ||
        talent->SpellFamilyName != REAPER_SPELL_FAMILY || talent->ProcFlags ||
        !talent->Effects[EFFECT_1].IsAura(SPELL_AURA_PROC_TRIGGER_SPELL) ||
        talent->Effects[EFFECT_1].TriggerSpell != SPELL_PAINMAIL_STACK_HELPER ||
        stack->Effects[EFFECT_0].Effect != SPELL_EFFECT_ASCENSION_MODIFY_AURA_STACKS ||
        stack->Effects[EFFECT_0].MiscValue != 1 || stack->Effects[EFFECT_0].TriggerSpell != SPELL_PAINMAIL ||
        aura->SpellFamilyName != REAPER_SPELL_FAMILY || aura->StackAmount != 8 || aura->GetDuration() != 15000 ||
        !heal->Effects[EFFECT_0].Effect || !cooldown->Effects[EFFECT_0].Effect)
        return false;

    for (uint8 i : { EFFECT_1, EFFECT_2 })
    {
        SpellEffectInfo const& effect = aura->Effects[i];
        if (!effect.IsAura(SPELL_AURA_PERIODIC_TRIGGER_SPELL_WITH_VALUE) || effect.Amplitude != 15000 ||
            effect.DieSides != 1 || effect.BasePoints != (i == EFFECT_1 ? 1 : -501) ||
            effect.TriggerSpell != (i == EFFECT_1 ? SPELL_PAINMAIL_HEAL : SPELL_PAINMAIL_COOLDOWN) ||
            effect.TargetA.GetTarget() != TARGET_UNIT_CASTER || effect.TargetB.GetTarget())
            return false;
    }

    return heal->Effects[EFFECT_0].Effect == SPELL_EFFECT_HEAL_PCT &&
        cooldown->Effects[EFFECT_0].Effect == SPELL_EFFECT_ASCENSION_MODIFY_COOLDOWN &&
        cooldown->Effects[EFFECT_0].MiscValue == SPELL_BOLSTERED_FORM &&
        !cooldown->Effects[EFFECT_0].MiscValueB &&
        heal->Effects[EFFECT_0].TargetA.GetTarget() == TARGET_UNIT_CASTER &&
        cooldown->Effects[EFFECT_0].TargetA.GetTarget() == TARGET_UNIT_CASTER;
}
}

void HandleAscensionReaperPainmailHit(Spell* spell, Player* player,
    Unit* target, uint8 missInfo, uint32 damage)
{
    if (!spell || !player || player != spell->GetCaster() || player->getClass() != CLASS_REAPER ||
        !player->IsAlive() || !target || target == player || player->IsFriendlyTo(target) ||
        missInfo != SPELL_MISS_NONE || !damage || !player->HasAura(SPELL_PAINMAIL_TALENT) ||
        !IsPainmailAttack(spell->GetSpellInfo()) || !HasPainmailContract())
        return;

    if (Aura* aura = player->GetAura(SPELL_PAINMAIL, player->GetGUID()))
    {
        uint8 maximum = aura->GetSpellInfo()->CalcMaxAuraStacks(player);
        if (aura->GetStackAmount() < maximum)
            aura->SetStackAmount(aura->GetStackAmount() + 1);
        return;
    }

    player->CastSpell(player, SPELL_PAINMAIL, TRIGGERED_FULL_MASK);
}
