/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionWitchHunterCompletion.h"
#include "AscensionWitchHunterCoefficients.h"
#include "CellImpl.h"
#include "DBCStores.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "Log.h"
#include "Pet.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>

namespace AscensionWitchHunter
{
Player* Owner(Unit* unit)
{
    Player* player = unit ? unit->ToPlayer() : nullptr;
    return player && player->getClass() == CLASS_WITCH_HUNTER ? player : nullptr;
}

Unit* Hound(Player* player)
{
    Unit* pet = player ? player->GetGuardianPet() : nullptr;
    return pet && pet->GetEntry() == 50124 && pet->GetOwnerGUID() == player->GetGUID() && pet->IsAlive() ? pet
                                                                                                         : nullptr;
}

std::list<Unit*> Nearby(Unit* center, float range)
{
    std::list<Unit*> units;
    if (!center || !center->IsInWorld())
        return units;
    Acore::AnyUnitInObjectRangeCheck check(center, range);
    Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> search(center, units, check);
    Cell::VisitObjects(center, search, range);
    units.remove_if([center](Unit* unit) { return !unit->IsAlive() || !center->InSamePhase(unit); });
    return units;
}

void Cast(Unit* caster, Unit* target, uint32 id)
{
    if (caster && target && target->IsAlive())
        caster->CastSpell(target, id, true);
}

void Reset(Player* player, uint32 id)
{
    if (player)
    {
        id = player->GetTemporarySpellReplacement(id);
        player->RemoveSpellCooldown(id, true);
        if (SpellInfo const* info = sSpellMgr->GetSpellInfo(id))
            if (info->MaxCharges)
                player->RestoreSpellCharge(id, info->MaxCharges);
    }
}

void Replacement(Player* player, uint32 word, uint32 mask, uint32 child)
{
    if (!player->HasSpell(child))
        player->learnSpell(child, true);
    for (auto const& [id, state] : player->GetSpellMap())
        if (state->State != PLAYERSPELL_REMOVED && Family(sSpellMgr->GetSpellInfo(id), word, mask) && id != child &&
            !player->IsTemporarySpellReplacementStandIn(id))
            player->SetTemporarySpellReplacement(id, child);
}

void ClearReplacement(Player* player, uint32 word, uint32 mask)
{
    for (auto const& [id, state] : player->GetSpellMap())
        if (state->State != PLAYERSPELL_REMOVED && Family(sSpellMgr->GetSpellInfo(id), word, mask))
            player->SetTemporarySpellReplacement(id, 0);
}

void ConvertCreatureTypeDamage(SpellInfo* info, uint8 index)
{
    SpellEffectInfo& effect = info->Effects[index];
    if (effect.Effect != SPELL_EFFECT_APPLY_AURA || effect.ApplyAuraName != SPELL_AURA_OVERRIDE_CLASS_SCRIPTS ||
        effect.MiscValue != ASCENSION_CLASSMASK_CREATURE_DAMAGE || effect.MiscValueB <= 0 || !effect.SpellClassMask)
    {
        LOG_ERROR("coa", "Skipped unexpected Witch Hunter creature damage record {}", info->Id);
        return;
    }
    effect.ApplyAuraName = SPELL_AURA_MOD_DAMAGE_DONE_VERSUS;
    std::swap(effect.MiscValue, effect.MiscValueB);
}

void ApplyContracts(SpellInfo* info)
{
    if (!info || info->SpellFamilyName != 21)
        return;
    uint32 id = info->Id;
    if (id == 802272)
    {
        info->AttributesCu &= ~SPELL_ATTR0_CU_FORCE_AURA_SAVING;
        info->AttributesCu |= SPELL_ATTR0_CU_AURA_CANNOT_BE_SAVED;
    }
    if (id == 680376 || id == 681562 || id == 681563 || id == 681564)
    {
        info->Effects[EFFECT_0].TargetA = SpellImplicitTargetInfo(TARGET_DEST_DEST);
        info->CasterAuraSpell = 802272;
        info->_InitializeExplicitTargetMask();
    }
    if (id == 562026 && info->Effects[EFFECT_1].TriggerSpell == 562027)
        info->Effects[EFFECT_1].Effect = 0;
    if (id == 681486 && info->Effects[EFFECT_2].ApplyAuraName == SPELL_AURA_ADD_PCT_MODIFIER &&
        info->Effects[EFFECT_2].MiscValue == SPELLMOD_DOT &&
        info->Effects[EFFECT_2].SpellClassMask == flag96(0, 268436480, 0))
    {
        info->Effects[EFFECT_2].MiscValue = SPELLMOD_DAMAGE;
        info->Effects[EFFECT_2].SpellClassMask = flag96(1024, 0, 0);
    }
    if (Family(info, 1, 4194304))
    {
        info->InterruptFlags |= SPELL_INTERRUPT_FLAG_MOVEMENT;
        info->ChannelInterruptFlags |= AURA_INTERRUPT_FLAG_MOVE;
    }
    if ((id == 807364 || id == 805751) && info->IsChanneled())
        info->AttributesEx5 &= ~SPELL_ATTR5_ALLOW_ACTION_DURING_CHANNEL;
    if (id == 574149 || id == 574163)
        ConvertCreatureTypeDamage(info, EFFECT_1);
    if (id == 804026)
        ConvertCreatureTypeDamage(info, EFFECT_0);
    if (id == 800697)
        info->Effects[EFFECT_1].ChainTarget = info->Effects[EFFECT_0].ChainTarget;
    if (id == 804194 && info->Effects[EFFECT_1].ApplyAuraName == SPELL_AURA_MOD_ARMOR_PENETRATION_PCT)
        info->Effects[EFFECT_1].ApplyAuraName = SPELL_AURA_ASCENSION_MOD_IGNORE_ARMOR_PCT;
    if (id == 707535)
    {
        info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_MOD_SPELL_DAMAGE_OF_STAT_PERCENT;
        info->Effects[EFFECT_0].MiscValueB = STAT_AGILITY;
    }
    if (id == 805533 || id == 807907)
        info->Effects[EFFECT_2].MiscValue = STAT_AGILITY;
    if (id == 681327 || Noctis(info))
        info->TargetAuraState = info->CasterAuraState = 0;
    if (id == 802006)
        info->Effects[EFFECT_2].TriggerSpell = 680386;
    if (Dusk(info) || id == 680230)
        info->AttributesEx3 &= ~SPELL_ATTR3_REQUIRES_OFF_HAND_WEAPON;
    if (Heartseeking(info))
        info->Effects[EFFECT_2].TriggerSpell = 807316;
    if (Quickdraw(info) && info->Effects[EFFECT_2].TriggerSpell == 680235)
        info->Effects[EFFECT_2].Effect = SPELL_EFFECT_TRIGGER_SPELL;
    if (id == 503662)
        info->CasterAuraSpell = 0;
    if (id == 300872)
        info->Effects[EFFECT_1].Effect = 0;
    if (id == 524854 || id == 680505)
        info->Effects[id == 524854 ? EFFECT_2 : EFFECT_0].ApplyAuraName = SPELL_AURA_MOD_DAMAGE_PERCENT_TAKEN;
    if (id == 504478 || id == 500569)
        info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_DUMMY;
    if (id == 804192 || id == 680275)
    {
        info->Effects[EFFECT_2].ApplyAuraName = SPELL_AURA_DUMMY;
        if (id == 804192)
            for (SpellEffectInfo& effect : info->Effects)
                if (effect.IsAura())
                {
                    effect.Effect = SPELL_EFFECT_APPLY_AURA;
                    effect.TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ALLY);
                }
    }
    if (id == 504478 || id == 706241)
        info->ProcCharges = 0;
    if (id == 706241)
    {
        info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_DUMMY;
        info->Effects[EFFECT_0].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_CASTER);
    }
    if (id == 680498)
        info->Effects[EFFECT_1].ApplyAuraName = SPELL_AURA_DUMMY;
    if (id == 680519)
        info->Effects[EFFECT_0].Effect = 0;
    if (id == 805347)
        info->Effects[EFFECT_2].Effect = 0;
    if (id == 520271)
        info->Effects[EFFECT_1].Effect = 0;
    if (id == 681098)
        info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_DUMMY;
    if (id == 524669)
    {
        info->StackAmount = 1;
        info->Effects[EFFECT_1].Effect = 0;
    }
    if (id == 681392 || id == 681489)
    {
        info->Effects[EFFECT_0].Effect = SPELL_EFFECT_WEAPON_PERCENT_DAMAGE;
        info->Effects[EFFECT_0].BasePoints = 99;
        info->Effects[EFFECT_0].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ENEMY);
        info->DmgClass = SPELL_DAMAGE_CLASS_MELEE;
        info->AttributesEx3 |= SPELL_ATTR3_REQUIRES_OFF_HAND_WEAPON;
    }
    if (id == 681415 || id == 681524)
        info->Effects[EFFECT_1].Effect = 0;
    if (id == 681524)
        info->SchoolMask = 33;
    if (id == 681270)
        info->Effects[EFFECT_1].Effect = 0;
    if (id == 573266 || id == 800528)
        for (SpellEffectInfo& effect : info->Effects)
            if (effect.IsAura())
            {
                effect.Effect = SPELL_EFFECT_APPLY_AURA;
                effect.TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ALLY);
            }
    if (id == 686020)
        info->Effects[EFFECT_0].ValueMultiplier = 0.9f;
    if (id == 574335 || id == 574337)
        info->Effects[EFFECT_0].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ALLY);
    if (id == 706332)
        info->Effects[EFFECT_0].Effect = 0;
    if (id == 805770)
    {
        info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_DUMMY;
        info->Effects[EFFECT_2].Effect = 0;
        info->CasterAuraSpell = 805771;
    }
    if (id == 805771)
        info->DurationEntry = sSpellDurationStore.LookupEntry(1);
    if (id == 680492 || id == 807733)
    {
        SpellEffectInfo& absorb = info->Effects[id == 680492 ? EFFECT_0 : EFFECT_1];
        absorb.ApplyAuraName = SPELL_AURA_SCHOOL_ABSORB;
        absorb.MiscValue = SPELL_SCHOOL_MASK_ALL;
    }
    if (id == 805766)
    {
        info->StackAmount = 1;
        info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_MOD_DAMAGE_PERCENT_TAKEN;
    }
    if (id == 704570)
        info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_MOD_DAMAGE_PERCENT_TAKEN;
    if (id == 501380)
    {
        info->Mechanic = MECHANIC_KNOCKOUT;
        info->Effects[EFFECT_0].Effect = SPELL_EFFECT_APPLY_AURA;
        info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_MOD_CONFUSE;
        info->Effects[EFFECT_0].Mechanic = MECHANIC_KNOCKOUT;
        info->AuraInterruptFlags |= AURA_INTERRUPT_FLAG_TAKE_DAMAGE;
    }
    if (id == 562225)
    {
        for (SpellEffectInfo& effect : info->Effects)
            effect.ApplyAuraName = SPELL_AURA_DUMMY;
        info->Effects[EFFECT_1].ApplyAuraName = SPELL_AURA_MOD_STEALTH_DETECT;
        info->Effects[EFFECT_1].MiscValue = 0;
    }
    if (id == 804068)
    {
        info->StackAmount = 1;
        info->Effects[EFFECT_2].Effect = 0;
    }
    if (id == 804073)
        for (uint8 i : {uint8(EFFECT_0), uint8(EFFECT_1)})
        {
            SpellEffectInfo& effect = info->Effects[i];
            effect.Effect = SPELL_EFFECT_APPLY_AURA;
            effect.ApplyAuraName =
                i == 0 ? SPELL_AURA_MELEE_ATTACK_POWER_ATTACKER_BONUS : SPELL_AURA_RANGED_ATTACK_POWER_ATTACKER_BONUS;
            effect.BasePoints = 149;
            effect.DieSides = 1;
            effect.TriggerSpell = 0;
            effect.TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ENEMY);
        }
    if (Desecrate(info))
    {
        info->CasterAuraState = 0;
        info->CasterAuraSpell = 803166;
    }
    if (id == 681485)
        info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_DUMMY;
    if (Family(info, 0, 65536))
        info->Effects[EFFECT_1].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ENEMY);
    if (id == 681452 || id == 681457 || id == 681179 || id == 681177 || id == 681447)
        for (SpellEffectInfo& effect : info->Effects)
            if (effect.IsEffect())
            {
                effect.TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ENEMY);
                effect.TargetB = SpellImplicitTargetInfo();
            }
    if (id == 520865)
        info->Effects[EFFECT_1].Effect = 0;
    if (id == 805756)
    {
        info->Effects[EFFECT_1].ApplyAuraName = SPELL_AURA_DUMMY;
        info->Effects[EFFECT_2].Effect = 0;
    }
    if (id == 805757)
    {
        info->Effects[EFFECT_0].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_DEST_AREA_ALLY);
        info->Effects[EFFECT_0].TargetB = SpellImplicitTargetInfo(TARGET_DEST_DYNOBJ_ALLY);
        info->AttributesCu &= ~SPELL_ATTR0_CU_NEGATIVE_EFF0;
    }
    if (id == 500102)
        info->Effects[EFFECT_1].Effect = 0;
    if (id == 504713)
        info->ProcCharges = 0;
    if (id == 504790)
    {
        info->Effects[EFFECT_2].ApplyAuraName = SPELL_AURA_ASCENSION_MOD_CRIT_CHANCE;
        info->Effects[EFFECT_2].MiscValue = 127;
    }
    if (id == 681327 || id == 680237 || id == 680539 || id == 681390 || id == 500161 || id == 500566)
        info->ProcCharges = 0;
    for (WitchCoefficient const& coefficient : WitchCoefficients)
        if (coefficient.id == id)
            info->Effects[coefficient.effect].BonusMultiplier = 0.0f;
    for (uint32 child : {803502, 520271, 704342, 574335, 574337, 681270, 680532, 807262, 567570})
        if (id == child)
            for (SpellEffectInfo& effect : info->Effects)
                effect.BonusMultiplier = 0.0f;
    if (id == 574335 || id == 574337 || id == 681270 || id == 680532 || id == 807262 || id == 567570)
    {
        info->AttributesEx2 |= SPELL_ATTR2_CANT_CRIT;
        info->AttributesEx3 |= SPELL_ATTR3_IGNORE_CASTER_MODIFIERS;
        info->AttributesEx4 |= SPELL_ATTR4_IGNORE_DAMAGE_TAKEN_MODIFIERS;
        info->AttributesCu |= SPELL_ATTR0_CU_IGNORE_ARMOR;
    }
    if (id == 807198)
        info->Effects[EFFECT_1].Effect = 0;
    if (id == 804185)
        for (SpellEffectInfo& effect : info->Effects)
            if (effect.IsAura())
                effect.ApplyAuraName = SPELL_AURA_DUMMY;
    if (id == 802281)
    {
        info->Effects[EFFECT_2].Effect = 0;
        info->AuraInterruptFlags |= AURA_INTERRUPT_FLAG_TAKE_DAMAGE | AURA_INTERRUPT_FLAG_DIRECT_DAMAGE;
    }
    if (id == 805773 || id == 92093)
        for (SpellEffectInfo& effect : info->Effects)
            if (effect.IsAura(SPELL_AURA_PROC_TRIGGER_SPELL))
                effect.ApplyAuraName = SPELL_AURA_DUMMY;
    for (uint32 talent : {705455, 500101, 681100, 705490, 524812, 500055, 681156, 680513, 582310, 504645, 500567,
                          705450, 706365, 707891, 503669, 705463, 705480})
        if (id == talent)
            info->ProcFlags = 0;
}
}

namespace
{
using namespace AscensionWitchHunter;

class witch_hunter_resources : public PlayerScript
{
  public:
    witch_hunter_resources()
        : PlayerScript("witch_hunter_resources", {PLAYERHOOK_ON_PLAYER_HAS_ACTIVE_POWER_TYPE})
    {
    }

    bool OnPlayerHasActivePowerType(Player const* player, Powers power) override
    {
        return player && player->getClass() == CLASS_WITCH_HUNTER && power == POWER_RAGE;
    }
};

class witch_hunter_scaling : public UnitScript
{
  public:
    witch_hunter_scaling() : UnitScript("witch_hunter_scaling", true, {UNITHOOK_MODIFY_SPELL_EFFECT_BASE_VALUE}) {}

    void ModifySpellEffectBaseValue(Unit const* caster, SpellInfo const* info, uint8 index, float& value) override
    {
        Player* player = caster ? caster->GetCharmerOrOwnerPlayerOrPlayerItself() : nullptr;
        if (!player || player->getClass() != CLASS_WITCH_HUNTER)
            return;
        for (WitchCoefficient const& c : WitchCoefficients)
            if (c.id == info->Id && c.effect == index)
            {
                float sp = c.school == 34 ? std::max(player->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_HOLY),
                                                     player->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_SHADOW))
                                          : player->SpellBaseDamageBonusDone(SpellSchoolMask(c.school));
                value += player->GetTotalAttackPowerValue(BASE_ATTACK) * c.ap +
                         player->GetTotalAttackPowerValue(RANGED_ATTACK) * c.rap + std::max(0.0f, sp) * c.sp;
            }
        if (Noctis(info) && !index)
            value += player->GetUInt32Value(PLAYER_FIELD_COMBAT_RATING_1 + CR_PARRY);
        if (info->Id == 681099 && !index)
            value += player->GetStat(STAT_STAMINA) * 2.0f;
        if (info->Id == 802138 && index == 2)
            value += player->GetStat(STAT_STAMINA) * 7.0f;
    }
};

class spell_ascension_witch_hunter_copy : public SpellScript
{
    PrepareSpellScript(spell_ascension_witch_hunter_copy);

    void Hit(SpellEffIndex index)
    {
        int32 value = std::max(0, GetSpellValue()->EffectBasePoints[index] + 1);
        if (GetSpellInfo()->Effects[index].Effect == SPELL_EFFECT_HEAL)
            SetHitHeal(value);
        else if (GetSpellInfo()->Effects[index].Effect == SPELL_EFFECT_SCHOOL_DAMAGE)
            SetHitDamage(value);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_witch_hunter_copy::Hit, EFFECT_ALL, SPELL_EFFECT_ANY);
    }
};
}

void AddAscensionWitchHunterCompletionScripts()
{
    new witch_hunter_scaling();
    new witch_hunter_resources();
    RegisterSpellScript(spell_ascension_witch_hunter_copy);
}
