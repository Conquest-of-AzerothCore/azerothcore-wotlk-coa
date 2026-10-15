/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionTemplar.h"
#include "AscensionTemplarData.h"
#include "DBCStores.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include <algorithm>
#include <cmath>

namespace
{
constexpr uint32 SPELL_RECENTLY_PARRIED_OR_DODGED = 681170;
}

namespace AscensionTemplar
{
void ApplyContracts(SpellInfo* info)
{
    if (!info || info->SpellFamilyName != 25)
        return;
    uint32 id = info->Id;
    auto dummy = [info](uint8 index) {
        info->Effects[index].ApplyAuraName = SPELL_AURA_DUMMY;
        info->Effects[index].TriggerSpell = 0;
    };
    auto routed = [info, dummy]() {
        for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
            if (info->Effects[i].ApplyAuraName == 42 || info->Effects[i].ApplyAuraName == 354 ||
                info->Effects[i].ApplyAuraName == 231)
                dummy(i);
        info->ProcCharges = 0;
    };
    for (uint32 sid : TemplarEvents)
        if (id == sid)
            routed();
    for (uint32 sid : TemplarCastDrivers)
        if (id == sid)
        {
            routed();
            info->ProcFlags = 0;
        }
    for (uint32 sid : {704576, 706426, 804903, 804904, 804922, 804924, 805332})
        if (id == sid)
        {
            info->StackAmount = 10;
            info->ProcFlags = 0;
            routed();
            if (id == 804924)
                info->Effects[1].Effect = 0;
        }
    if (id == 704576 || id == 706426)
        info->DurationEntry = sSpellDurationStore.LookupEntry(8);
    if (id == 804904)
        info->Effects[2].SpellClassMask[0] = 0;
    if (Family(info, 0, 4194304) && info->Effects[1].ApplyAuraName == SPELL_AURA_MOD_DAMAGE_FROM_CASTER &&
        info->Effects[1].SpellClassMask == flag96(8, 75497472, 0))
        info->Effects[1].SpellClassMask[1] |= 2048;
    if (id == 707755)
        for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
            dummy(i);
    if (id == 300513)
        info->Effects[2].ApplyAuraName = SPELL_AURA_PREVENTS_FLEEING;
    if (id == 707111)
        info->Effects[0].Effect = info->Effects[1].Effect = 0;
    if (id == 92109 || id == 803149)
    {
        for (auto& effect : info->Effects)
            if (effect.ApplyAuraName != SPELL_AURA_PROC_TRIGGER_SPELL ||
                effect.TriggerSpell != SPELL_RECENTLY_PARRIED_OR_DODGED)
                effect.Effect = 0;
        auto& effect = info->Effects[0];
        effect.Effect = SPELL_EFFECT_APPLY_AURA;
        effect.ApplyAuraName = SPELL_AURA_SCHOOL_ABSORB;
        effect.MiscValue = SPELL_SCHOOL_MASK_ALL;
        effect.TargetA = SpellImplicitTargetInfo(TARGET_UNIT_CASTER);
        effect.TargetB = SpellImplicitTargetInfo();
        info->DurationEntry = sSpellDurationStore.LookupEntry(21);
        info->ProcFlags = 0;
    }
    if (id == 803237)
    {
        info->Effects[0].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
        info->Effects[0].BasePoints = -1;
        info->Attributes |= SPELL_ATTR0_AURA_IS_DEBUFF;
    }
    if (id == 801482)
        dummy(1);
    if (id == 300524 && info->Effects[1].ApplyAuraName == SPELL_AURA_ADD_PCT_MODIFIER &&
        info->Effects[1].TargetA.GetTarget() == TARGET_UNIT_NEARBY_ENEMY)
    {
        info->Effects[1].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_CASTER);
        info->Effects[1].TargetB = SpellImplicitTargetInfo();
    }
    if ((id == 560650 || id == 561346) && info->Effects[0].ApplyAuraName == SPELL_AURA_MOD_CRIT_PCT &&
        info->Effects[0].MiscValue == SPELLMOD_CRITICAL_CHANCE && info->Effects[0].SpellClassMask)
    {
        info->Effects[0].ApplyAuraName = SPELL_AURA_ADD_FLAT_MODIFIER;
    }
    if (id == 520034 && info->Effects[0].ApplyAuraName == SPELL_AURA_MOD_DAMAGE_DONE_VERSUS_AURASTATE &&
        info->Effects[0].MiscValue == AURA_STATE_HEALTH_ABOVE_75_PERCENT && !info->Effects[0].SpellClassMask)
    {
        info->Effects[0].SpellClassMask = flag96(0, 67108864, 0);
        info->Effects[0].MiscValueB = ASCENSION_CLASSMASK_AURASTATE_DAMAGE;
    }
    if (id == 705284 && info->Effects[0].ApplyAuraName == SPELL_AURA_ADD_PCT_MODIFIER &&
        info->Effects[0].MiscValue == SPELLMOD_DAMAGE && !info->Effects[2].Effect)
    {
        info->Effects[0].SpellClassMask[0] |= 2;
        SpellEffectInfo& dot = info->Effects[2];
        dot.Effect = SPELL_EFFECT_APPLY_AURA;
        dot.ApplyAuraName = SPELL_AURA_ADD_PCT_MODIFIER;
        dot.BasePoints = info->Effects[0].BasePoints;
        dot.DieSides = info->Effects[0].DieSides;
        dot.MiscValue = SPELLMOD_DOT;
        dot.SpellClassMask = flag96(0, 2048, 0);
        dot.TargetA = SpellImplicitTargetInfo(TARGET_UNIT_CASTER);
        dot.TargetB = SpellImplicitTargetInfo();
    }
    if (id == 801481 && info->Effects[1].TriggerSpell == 801482)
    {
        info->ProcFlags = 0;
        info->ProcCharges = 0;
    }
    if (id == 712678 || id == 712437)
        for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
            if (info->Effects[i].Effect)
                dummy(i);
    if (id == 520442)
        info->Effects[0].MiscValue = SPELLMOD_CRIT_DAMAGE_BONUS;
    if (id == 806522)
        info->Effects[1].SpellClassMask = flag96(0, 8388608, 0);
    if (id == 806523)
    {
        dummy(0);
        info->ProcFlags = 0;
        info->ProcCharges = 0;
    }
    if (Named(info, 804929))
        for (auto& effect : info->Effects)
            if (effect.Effect == SPELL_EFFECT_TRIGGER_SPELL && effect.TriggerSpell == 801832)
                effect.Effect = 0;
    if (id == 801832 || id == 807035 || Family(info, 0, 262144) || id == 807890)
        for (auto& effect : info->Effects)
            if (effect.Effect && effect.TargetA.GetTarget() == TARGET_UNIT_TARGET_ENEMY && !effect.ChainTarget)
                effect.ChainTarget = 1;
    if (id == 801202)
        dummy(0), dummy(1);
    if (id == 803843 || id == 807903 || id == 803219)
        dummy(0);
    if (id == 801461)
        dummy(1), dummy(2);
    if (id >= 803890 && id <= 803893)
        info->Effects[1].BasePoints = int32(id - 803890);
    if (id == 300515)
        info->Effects[1].BasePoints = 5;
    if (id == 801409)
        info->DurationEntry = sSpellDurationStore.LookupEntry(8);
    if (id == 807004)
        dummy(0), dummy(1);
    if (id == 806353)
        info->Effects[1].Effect = 0;
    if (id == 805390)
        info->ProcFlags = 0;
    if (id == 563270)
        info->Effects[1].Effect = 0;
    if (id == 563269)
        info->Effects[1].Effect = 0;
    if (id == 500689)
        info->Effects[1].Effect = info->Effects[2].Effect = 0;
    if (id == 524617)
        dummy(0), dummy(2);
    if (id == 527269 || id == 520695 || id == 803160 || id == 573020)
    {
        info->Effects[0].TargetA =
            SpellImplicitTargetInfo(id == 803160 ? TARGET_UNIT_TARGET_ALLY : TARGET_UNIT_TARGET_ENEMY);
        info->Effects[0].TargetB = SpellImplicitTargetInfo();
    }
    if (id == 680398 || id == 524619)
    {
        info->Effects[0].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_DEST_AREA_ENEMY);
        info->Effects[0].TargetB = SpellImplicitTargetInfo();
    }
    if (id == 301340)
    {
        info->Effects[0].BasePoints = 19;
        info->Effects[0].MiscValue = 0;
        info->Effects[1].Effect = 0;
    }
    if (id == 527272)
    {
        dummy(0);
        info->AuraInterruptFlags &= ~AURA_INTERRUPT_FLAG_CAST;
    }
    if (id == 527270)
    {
        dummy(0);
        dummy(1);
        info->Effects[2].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
        info->Effects[2].Amplitude = 500;
        info->Effects[2].TriggerSpell = 0;
    }
    if (id == 527269)
        info->Effects[0].BasePoints = 64;
    if (id == 1397742)
        info->Effects[1].Effect = 0;
    if (id == 524740 && info->Effects[1].TriggerSpell == 520842 &&
        info->Effects[0].TargetB.GetTarget() == TARGET_UNIT_DEST_AREA_ENEMY)
    {
        info->AscensionIgnoreAbsorbAndResistance = true;
        info->Effects[1].TargetA = info->Effects[0].TargetA;
        info->Effects[1].TargetB = info->Effects[0].TargetB;
        info->Effects[1].RadiusEntry = info->Effects[0].RadiusEntry;
        info->SpellFamilyFlags[1] |= 67108864;
    }
    if (id == 801450)
        info->AttributesEx3 |= SPELL_ATTR3_REQUIRES_OFF_HAND_WEAPON;
    for (uint32 sid : TemplarCopies)
        if (id == sid)
        {
            info->AttributesEx2 |= SPELL_ATTR2_CANT_CRIT;
            info->AttributesEx3 |= SPELL_ATTR3_IGNORE_CASTER_MODIFIERS;
            info->AttributesEx4 |= SPELL_ATTR4_IGNORE_DAMAGE_TAKEN_MODIFIERS;
            info->AttributesCu |= SPELL_ATTR0_CU_IGNORE_ARMOR;
            info->ProcFlags = 0;
        }
    if (id == 527269 || id == 520695 || id == 803160 || id == 573020 || id == 680398 || id == 524619 ||
        id == 92109 || id == 803149 || id == 524740 || id == 300524)
        info->_InitializeExplicitTargetMask();
}
}

namespace
{
using namespace AscensionTemplar;
float Mitigation(Player* player, Unit* attacker, uint32 school)
{
    float factor = 1.0f;
    if ((school & SPELL_SCHOOL_MASK_NORMAL) && player->HasAura(801461))
    {
        bool versusPlayer = attacker && attacker->GetCharmerOrOwnerPlayerOrPlayerItself();
        int32 reduction = Amount(801461, versusPlayer ? EFFECT_2 : EFFECT_1, player);
        factor *= std::max(0.0f, 1.0f + float(reduction) / 100.0f);
    }
    if ((school & SPELL_SCHOOL_MASK_MAGIC) && player->HasAura(801202) &&
        (player->HealthAbovePct(80) || player->HealthBelowPct(20)))
        factor *= .8f;
    uint32 copies = HopeCount(player);
    factor *= std::max(0.0f, 1.0f - float(copies) * (player->HasAura(803219) ? .15f : .1f));
    return factor;
}
constexpr uint32 SPELL_TRANQUIL_STATE = 850010;
constexpr int32 TRANQUIL_STATE_PLAYER_DURATION = 8000;
class templar_scaling : public UnitScript
{
  public:
    templar_scaling()
        : UnitScript("templar_scaling", true,
                     {UNITHOOK_MODIFY_SPELL_EFFECT_BASE_VALUE, UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN,
                      UNITHOOK_MODIFY_MELEE_DAMAGE, UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK,
                      UNITHOOK_ON_AURA_APPLY})
    {
    }
    void OnAuraApply(Unit* unit, Aura* aura) override
    {
        if (unit && unit->IsPlayer() && aura && aura->GetId() == SPELL_TRANQUIL_STATE &&
            aura->GetMaxDuration() > TRANQUIL_STATE_PLAYER_DURATION)
        {
            aura->SetMaxDuration(TRANQUIL_STATE_PLAYER_DURATION);
            aura->SetDuration(TRANQUIL_STATE_PLAYER_DURATION);
        }
    }
    void ModifySpellEffectBaseValue(Unit const* caster, SpellInfo const* info, uint8 index, float& value) override
    {
        Player* player = Owner(caster);
        if (!player || !info)
            return;
        if (info->Id == 527269 && index == 0)
            value = float(Amount(527270, 2, player));
        if (info->Id == 803160 && index == 0)
            value = float(Amount(player->HasAura(803844) ? 803844 : 803159, 0, player));
        for (auto const& row : TemplarCoefficients)
            if (row.spell == info->Id && row.effect == index)
            {
                float power = float(row.heal ? player->SpellBaseHealingBonusDone(SpellSchoolMask(row.school))
                                             : player->SpellBaseDamageBonusDone(SpellSchoolMask(row.school)));
                value += row.ap * player->GetTotalAttackPowerValue(BASE_ATTACK) + row.sp * std::max(0.0f, power) +
                         row.stamina * player->GetStat(STAT_STAMINA) + row.agility * player->GetStat(STAT_AGILITY);
                value = std::clamp(value, 0.0f, float(INT32_MAX / 2));
            }
        if (info->Id == 806352 && index == 0)
            value += .25f * player->GetUInt32Value(PLAYER_FIELD_COMBAT_RATING_1 + CR_PARRY);
    }
    void ModifySpellDamageTaken(Unit* target, Unit* attacker, int32& damage, SpellInfo const* info) override
    {
        if (Player* player = Owner(target))
            if (info && !info->HasAttribute(SPELL_ATTR4_IGNORE_DAMAGE_TAKEN_MODIFIERS))
                damage = int32(damage * Mitigation(player, attacker, info->SchoolMask));
    }
    void ModifyMeleeDamage(Unit* target, Unit* attacker, uint32& damage) override
    {
        if (Player* player = Owner(target))
            damage = uint32(damage * Mitigation(player, attacker, SPELL_SCHOOL_MASK_NORMAL));
    }
    void ModifyPeriodicDamageAurasTick(Unit* target, Unit* attacker, uint32& damage, SpellInfo const* info) override
    {
        Player* player = Owner(target);
        if (!player || !info || info->HasAttribute(SPELL_ATTR4_IGNORE_DAMAGE_TAKEN_MODIFIERS))
            return;
        damage = uint32(damage * Mitigation(player, attacker, info->SchoolMask));
        if (AuraEffect const* ward = player->GetAuraEffect(301283, EFFECT_1))
            if ((ward->GetMiscValue() & info->SchoolMask) &&
                (info->HasAura(SPELL_AURA_PERIODIC_DAMAGE) || info->HasAura(SPELL_AURA_PERIODIC_DAMAGE_PERCENT) ||
                 info->HasAura(SPELL_AURA_PERIODIC_LEECH)))
                damage = uint32(damage * std::max(0.0f, 1.0f + float(ward->GetAmount()) / 100.0f));
    }
};
}
void AddSC_AscensionTemplarContracts()
{
    new templar_scaling();
}
