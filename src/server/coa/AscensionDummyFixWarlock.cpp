/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionDummyFixes.h"
#include "AllSpellScript.h"
#include "CellImpl.h"
#include "DBCStores.h"
#include "GameTime.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "Group.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "PlayerScript.h"
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
#include <list>
#include <unordered_map>
#include <vector>

namespace
{
constexpr uint32 WARLOCK_DRAIN_LIFE_FLAG = 0x00000008;
constexpr uint32 WARLOCK_RAIN_OF_FIRE_FLAG = 0x00000020;
constexpr uint32 WARLOCK_INCINERATE_FLAG_1 = 0x00000040;
constexpr uint32 WARLOCK_CONFLAGRATE_FLAG_1 = 0x00800000;
constexpr uint32 MAGE_FLAMESTRIKE_FLAG = 0x00000004;
constexpr uint32 PRIEST_HOLY_FIRE_FLAG = 0x00100000;

bool IsWarlockSpell(SpellInfo const* info, uint8 index, uint32 flag)
{
    return info && info->SpellFamilyName == SPELLFAMILY_WARLOCK && (info->SpellFamilyFlags[index] & flag);
}

constexpr uint32 GULDANS_CHOSEN = 277151;
constexpr uint32 GULDANS_CHOSEN_REBORN = 1578704;
constexpr std::array<uint32, 6> BACKDRAFT_BUFFS = { 54274, 54276, 54277, 1154274, 1154276, 1154277 };

class spell_dummyfix_warlock_guldans_chosen : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_warlock_guldans_chosen);

    void PrepareProc(ProcEventInfo& )
    {
        Unit* warlock = GetUnitOwner();
        if (!warlock)
            return;
        bool const backdraft = std::find(BACKDRAFT_BUFFS.begin(), BACKDRAFT_BUFFS.end(), GetId()) != BACKDRAFT_BUFFS.end();
        if (warlock->HasAura(GULDANS_CHOSEN) || (backdraft && warlock->HasAura(GULDANS_CHOSEN_REBORN)))
            PreventDefaultAction();
    }

    void Register() override
    {
        DoPrepareProc += AuraProcFn(spell_dummyfix_warlock_guldans_chosen::PrepareProc);
    }
};

constexpr uint32 ABSOLUTE_HELLFIRE_MARK = 284790;
constexpr uint32 ABSOLUTE_HELLFIRE_DAMAGE = 284788;
constexpr std::array<uint32, 2> MAGE_METEOR = { 101466, 101469 };

class spell_dummyfix_warlock_absolute_hellfire : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_warlock_absolute_hellfire);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        if (!info || !damage || !damage->GetDamage())
            return false;
        if (info->SpellFamilyName == SPELLFAMILY_MAGE && (info->SpellFamilyFlags[0] & MAGE_FLAMESTRIKE_FLAG))
            return true;
        return std::find(MAGE_METEOR.begin(), MAGE_METEOR.end(), info->Id) != MAGE_METEOR.end();
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_warlock_absolute_hellfire::CheckProc);
    }
};

void AbsoluteHellfireTick(Unit* target, Unit* attacker, SpellInfo const* info)
{
    if (!target || !attacker || !IsWarlockSpell(info, 0, WARLOCK_RAIN_OF_FIRE_FLAG) || info->Id == ABSOLUTE_HELLFIRE_DAMAGE ||
        !info->HasEffect(SPELL_EFFECT_SCHOOL_DAMAGE) || !target->HasAura(ABSOLUTE_HELLFIRE_MARK, attacker->GetGUID()))
        return;
    ObjectGuid const targetGuid = target->GetGUID();
    attacker->m_Events.AddEventAtOffset([attacker, targetGuid]()
    {
        if (Unit* marked = ObjectAccessor::GetUnit(*attacker, targetGuid))
            if (marked->IsAlive())
                attacker->CastSpell(marked, ABSOLUTE_HELLFIRE_DAMAGE, true);
    }, 1ms);
}

struct TargetAuraBonus
{
    uint32 Aura;
    SpellFamilyNames Family;
    uint8 FlagIndex;
    uint32 Flag;
    bool Periodic;
    SpellFamilyNames TargetFamily;
    uint8 TargetFlagIndex;
    uint32 TargetFlag;
    bool OwnTargetAura;
    uint8 Effect;
};

constexpr uint32 WARLOCK_CORRUPTION_FLAG = 0x00000002;
constexpr std::array<TargetAuraBonus, 6> TARGET_AURA_BONUSES = {{
    { 81301, SPELLFAMILY_WARLOCK, 1, WARLOCK_INCINERATE_FLAG_1, false, SPELLFAMILY_MAGE, 0, MAGE_FLAMESTRIKE_FLAG, false, 0 },
    { 982113, SPELLFAMILY_WARLOCK, 1, WARLOCK_CONFLAGRATE_FLAG_1, true, SPELLFAMILY_PRIEST, 0, PRIEST_HOLY_FIRE_FLAG, true, 0 },
    { 966092, SPELLFAMILY_WARLOCK, 1, 0x00000080, false, SPELLFAMILY_WARLOCK, 0, WARLOCK_CORRUPTION_FLAG, true, 1 },
    { 966092, SPELLFAMILY_WARLOCK, 0, 0x00000001, false, SPELLFAMILY_WARLOCK, 0, WARLOCK_CORRUPTION_FLAG, true, 1 },
    { 966092, SPELLFAMILY_WARLOCK, 0, 0x00000080, false, SPELLFAMILY_WARLOCK, 0, WARLOCK_CORRUPTION_FLAG, true, 1 },
    { 966092, SPELLFAMILY_PRIEST, 0, 0x00002000, false, SPELLFAMILY_WARLOCK, 0, WARLOCK_CORRUPTION_FLAG, true, 1 },
}};

bool TargetHasFamilyAura(Unit const* target, SpellFamilyNames family, uint8 index, uint32 flag, ObjectGuid caster)
{
    for (auto const& [id, application] : target->GetAppliedAuras())
    {
        Aura const* aura = application->GetBase();
        SpellInfo const* info = aura->GetSpellInfo();
        if (info->SpellFamilyName == family && (info->SpellFamilyFlags[index] & flag) &&
            (!caster || aura->GetCasterGUID() == caster))
            return true;
    }
    return false;
}

int32 TargetAuraBonusPct(Unit const* target, Unit const* attacker, SpellInfo const* info, bool periodic)
{
    if (!target || !attacker || !info)
        return 0;
    int32 pct = 0;
    for (TargetAuraBonus const& bonus : TARGET_AURA_BONUSES)
    {
        if (bonus.Periodic != periodic || info->SpellFamilyName != bonus.Family ||
            !(info->SpellFamilyFlags[bonus.FlagIndex] & bonus.Flag))
            continue;
        AuraEffect const* effect = attacker->GetAuraEffect(bonus.Aura, bonus.Effect);
        if (!effect || !TargetHasFamilyAura(target, bonus.TargetFamily, bonus.TargetFlagIndex, bonus.TargetFlag,
            bonus.OwnTargetAura ? attacker->GetGUID() : ObjectGuid::Empty))
            continue;
        pct += effect->GetAmount();
    }
    return pct;
}

constexpr uint32 DARK_HARVEST_ENCHANT = 1180950;
constexpr uint32 DARK_HARVEST = 1180951;
constexpr uint8 DARK_HARVEST_KILL_STACKS = 3;

int32 DarkHarvestPct(Unit const* attacker, SpellInfo const* info)
{
    if (!attacker || !IsWarlockSpell(info, 0, WARLOCK_DRAIN_LIFE_FLAG))
        return 0;
    Aura const* harvest = attacker->GetAura(DARK_HARVEST);
    if (!harvest)
        return 0;
    return harvest->GetSpellInfo()->Effects[EFFECT_0].CalcValue() * int32(harvest->GetStackAmount());
}

void DarkHarvestKill(Player* killer, Unit* killed)
{
    if (!killer || !killed || !killer->HasAura(DARK_HARVEST_ENCHANT) || !killer->isHonorOrXPTarget(killed))
        return;
    Aura* harvest = killer->GetAura(DARK_HARVEST);
    int32 add = DARK_HARVEST_KILL_STACKS;
    if (!harvest)
    {
        killer->CastSpell(killer, DARK_HARVEST, true);
        harvest = killer->GetAura(DARK_HARVEST);
        --add;
    }
    if (harvest && add > 0)
        harvest->ModStackAmount(add);
}

constexpr uint32 DRUNKEN_BRAWLER_RAGE = 81308;

class spell_dummyfix_warlock_drunken_brawler : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_warlock_drunken_brawler);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ DRUNKEN_BRAWLER_RAGE });
    }

    void HandlePeriodic(AuraEffect const* aurEff)
    {
        PreventDefaultAction();
        Player* player = GetTarget()->ToPlayer();
        if (!player || !player->GetDrunkValue())
            return;
        if (player->GetWeaponForAttack(BASE_ATTACK) || player->GetWeaponForAttack(OFF_ATTACK) ||
            player->GetWeaponForAttack(RANGED_ATTACK))
            return;
        player->CastSpell(player, DRUNKEN_BRAWLER_RAGE, true, nullptr, aurEff);
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_dummyfix_warlock_drunken_brawler::HandlePeriodic, EFFECT_0,
            SPELL_AURA_PERIODIC_DUMMY);
    }
};

struct CrossoverRule
{
    uint32 Aura;
    uint32 RankOne;
    uint32 Granted;
};

constexpr std::array<CrossoverRule, 2> CROSSOVERS = {{
    { 1318693, 1118692, 1118693 },
    { 1353759, 1153754, 1153759 },
}};

CrossoverRule const* CrossoverByAura(uint32 id)
{
    for (CrossoverRule const& rule : CROSSOVERS)
        if (rule.Aura == id)
            return &rule;
    return nullptr;
}

class spell_dummyfix_warlock_crossover : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_warlock_crossover);

    bool _granted = false;

    bool Validate(SpellInfo const* info) override
    {
        CrossoverRule const* rule = CrossoverByAura(info->Id);
        return rule && ValidateSpellInfo({ rule->RankOne, rule->Granted });
    }

    void HandleApply(AuraEffect const* , AuraEffectHandleModes )
    {
        CrossoverRule const* rule = CrossoverByAura(GetId());
        Unit* target = GetTarget();
        if (!rule || !target->IsPlayer() || target->HasAura(rule->RankOne) || target->HasAura(rule->Granted))
            return;
        if (target->AddAura(rule->Granted, target))
            _granted = true;
    }

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        CrossoverRule const* rule = CrossoverByAura(GetId());
        if (!rule || !_granted)
            return;
        _granted = false;
        GetTarget()->RemoveAurasDueToSpell(rule->Granted);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_dummyfix_warlock_crossover::HandleApply, EFFECT_0,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummyfix_warlock_crossover::HandleRemove, EFFECT_0,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_dummyfix_warlock_soulbound_split : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_warlock_soulbound_split);

    void HandleSplit(AuraEffect* , DamageInfo& , uint32& splitAmount)
    {
        Unit* demon = GetCaster();
        if (!demon || !demon->IsAlive())
        {
            splitAmount = 0;
            return;
        }
        splitAmount = uint32(float(splitAmount) * demon->GetHealthPct() / 100.0f);
    }

    void Register() override
    {
        OnEffectSplit += AuraEffectSplitFn(spell_dummyfix_warlock_soulbound_split::HandleSplit, EFFECT_0);
    }
};

constexpr uint32 DEEP_FREEZE = 44572;
constexpr uint32 DEEP_FREEZE_STUN = 844572;
constexpr uint32 DEEP_FREEZE_DAMAGE = 71757;
constexpr uint32 CHILLING_BLOWS_ENCHANT = 81213;
constexpr uint32 CHILLING_BLOWS_CDR = 281537;
constexpr uint32 CHILLING_BLOWS_HASTE = 281538;
constexpr int32 CHILLING_BLOWS_ENCHANT_CDR_MS = 10500;
constexpr std::array<uint32, 10> FROSTBRAND_ATTACK = { 8034, 8037, 10458, 16352, 16353, 1108034, 1108037, 1110458,
    1116352, 1116353 };

bool PermanentlyStunImmune(Unit const* target)
{
    Creature const* creature = target->ToCreature();
    return creature && creature->HasMechanicTemplateImmunity(1ULL << MECHANIC_STUN);
}

class spell_dummyfix_warlock_chilling_blows : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_warlock_chilling_blows);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        if (!info || !damage || !damage->GetDamage() || !eventInfo.GetActionTarget())
            return false;
        if (info->Id == DEEP_FREEZE_DAMAGE)
            return GetId() != CHILLING_BLOWS_ENCHANT;
        return std::find(FROSTBRAND_ATTACK.begin(), FROSTBRAND_ATTACK.end(), info->Id) != FROSTBRAND_ATTACK.end();
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* caster = GetTarget();
        Unit* target = eventInfo.GetActionTarget();
        if (eventInfo.GetSpellInfo()->Id == DEEP_FREEZE_DAMAGE)
        {
            caster->CastSpell(caster, CHILLING_BLOWS_HASTE, true, nullptr, aurEff);
            return;
        }
        if (Aura* stun = target->GetAura(DEEP_FREEZE_STUN, caster->GetGUID()))
        {
            int32 const duration = stun->GetDuration() + aurEff->GetAmount();
            stun->SetMaxDuration(std::max(stun->GetMaxDuration(), duration));
            stun->SetDuration(duration);
            return;
        }
        if (!PermanentlyStunImmune(target))
            return;
        if (GetId() == CHILLING_BLOWS_ENCHANT)
        {
            if (Player* player = caster->ToPlayer())
                player->ModifySpellCooldown(DEEP_FREEZE, -CHILLING_BLOWS_ENCHANT_CDR_MS);
        }
        else
            caster->CastSpell(caster, CHILLING_BLOWS_CDR, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_warlock_chilling_blows::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_warlock_chilling_blows::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

struct EquilibriumRule
{
    uint32 Aura;
    std::array<uint32, 3> Essences;
    uint32 Reward;
    uint32 Cooldown;
    bool AllSchoolsPerCast;
};

constexpr std::array<EquilibriumRule, 2> EQUILIBRIUM = {{
    { 285174, { 285178, 285179, 285180 }, 285183, 0, true },
    { 983228, { 983229, 983230, 983231 }, 983236, 983237, false },
}};
constexpr std::array<SpellSchoolMask, 3> EQUILIBRIUM_SCHOOLS = { SPELL_SCHOOL_MASK_FIRE, SPELL_SCHOOL_MASK_FROST,
    SPELL_SCHOOL_MASK_NATURE };

EquilibriumRule const* EquilibriumByAura(uint32 id)
{
    for (EquilibriumRule const& rule : EQUILIBRIUM)
        if (rule.Aura == id)
            return &rule;
    return nullptr;
}

class spell_dummyfix_warlock_elemental_equilibrium : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_warlock_elemental_equilibrium);

    bool Validate(SpellInfo const* info) override
    {
        EquilibriumRule const* rule = EquilibriumByAura(info->Id);
        return rule && ValidateSpellInfo({ rule->Essences[0], rule->Essences[1], rule->Essences[2], rule->Reward });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        EquilibriumRule const* rule = EquilibriumByAura(GetId());
        if (!rule || !info || !damage || !damage->GetDamage() || (eventInfo.GetTypeMask() & PROC_FLAG_DONE_PERIODIC))
            return false;
        if (rule->Cooldown && GetTarget()->HasAura(rule->Cooldown))
            return false;
        return info->GetSchoolMask() & (SPELL_SCHOOL_MASK_FIRE | SPELL_SCHOOL_MASK_FROST | SPELL_SCHOOL_MASK_NATURE);
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        EquilibriumRule const* rule = EquilibriumByAura(GetId());
        Unit* caster = GetTarget();
        uint32 const schools = eventInfo.GetSpellInfo()->GetSchoolMask();
        for (std::size_t i = 0; i < EQUILIBRIUM_SCHOOLS.size(); ++i)
        {
            if (!(schools & EQUILIBRIUM_SCHOOLS[i]))
                continue;
            caster->CastSpell(caster, rule->Essences[i], true, nullptr, aurEff);
            if (!rule->AllSchoolsPerCast)
                break;
        }
        for (uint32 essence : rule->Essences)
            if (!caster->HasAura(essence))
                return;
        for (uint32 essence : rule->Essences)
            caster->RemoveAurasDueToSpell(essence);
        caster->CastSpell(caster, rule->Reward, true, nullptr, aurEff);
        if (rule->Cooldown)
            caster->CastSpell(caster, rule->Cooldown, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_warlock_elemental_equilibrium::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_warlock_elemental_equilibrium::HandleProc, EFFECT_0,
            SPELL_AURA_DUMMY);
    }
};

constexpr uint32 WARLOCK_IMMOLATE_FLAG = 0x00000004;

class spell_dummyfix_warlock_immolating_backdraft : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_warlock_immolating_backdraft);

    static uint32 BackdraftBuff(Unit const* warlock)
    {
        uint32 best = 0;
        for (AuraEffect const* effect : warlock->GetAuraEffectsByType(SPELL_AURA_PROC_TRIGGER_SPELL))
        {
            uint32 const trigger = effect->GetSpellInfo()->Effects[effect->GetEffIndex()].TriggerSpell;
            auto const found = std::find(BACKDRAFT_BUFFS.begin(), BACKDRAFT_BUFFS.end(), trigger);
            if (found != BACKDRAFT_BUFFS.end() && (!best || *found > best))
                best = *found;
        }
        return best;
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        return IsWarlockSpell(eventInfo.GetSpellInfo(), 0, WARLOCK_IMMOLATE_FLAG) && BackdraftBuff(GetTarget());
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& )
    {
        PreventDefaultAction();
        if (uint32 const buff = BackdraftBuff(GetTarget()))
            GetTarget()->CastSpell(GetTarget(), buff, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_warlock_immolating_backdraft::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_warlock_immolating_backdraft::HandleProc, EFFECT_0,
            SPELL_AURA_DUMMY);
    }
};

constexpr uint32 NECROMANCERS_TOUCH = 275963;
constexpr uint32 NECROMANCERS_TOUCH_DEBUFF = 275966;
constexpr uint32 NPC_RISEN_GHOUL = 26125;

Player* NecromancersTouchOwner(Unit const* attacker)
{
    if (!attacker || !attacker->IsCreature())
        return nullptr;
    if (attacker->IsCharmed())
    {
        Unit* charmer = attacker->GetCharmer();
        return charmer ? charmer->ToPlayer() : nullptr;
    }
    if (attacker->GetEntry() == NPC_RISEN_GHOUL)
    {
        Unit* owner = attacker->GetOwner();
        return owner ? owner->ToPlayer() : nullptr;
    }
    return nullptr;
}

void NecromancersTouch(Unit* attacker, Unit* victim)
{
    Player* warlock = NecromancersTouchOwner(attacker);
    if (!warlock || !victim || victim == warlock || !warlock->HasAura(NECROMANCERS_TOUCH))
        return;
    ObjectGuid const victimGuid = victim->GetGUID();
    warlock->m_Events.AddEventAtOffset([warlock, victimGuid]()
    {
        if (Unit* target = ObjectAccessor::GetUnit(*warlock, victimGuid))
            if (target->IsAlive())
                warlock->CastSpell(target, NECROMANCERS_TOUCH_DEBUFF, true);
    }, 1ms);
}

constexpr uint32 PYROCLASMIC_SHADOWS = 276551;
constexpr uint32 PYROCLASMIC_SHADOWS_VALUES = 276548;
constexpr std::array<uint32, 5> PYROCLASM_BUFFS = { 18093, 63243, 63244, 1118093, 1163243 };
constexpr uint32 WARLOCK_SHADOW_BOLT_FLAG = 0x00000001;
constexpr uint32 WARLOCK_CHAOS_BOLT_FLAG_1 = 0x00020000;

int32 PyroclasmicShadowsPct(Unit const* target, Unit const* attacker, SpellInfo const* info)
{
    if (!target || !attacker || !attacker->HasAura(PYROCLASMIC_SHADOWS))
        return 0;
    if (!IsWarlockSpell(info, 0, WARLOCK_SHADOW_BOLT_FLAG) && !IsWarlockSpell(info, 1, WARLOCK_CHAOS_BOLT_FLAG_1))
        return 0;
    if (std::none_of(PYROCLASM_BUFFS.begin(), PYROCLASM_BUFFS.end(), [attacker](uint32 id) { return attacker->HasAura(id); }))
        return 0;
    SpellInfo const* values = sSpellMgr->GetSpellInfo(PYROCLASMIC_SHADOWS_VALUES);
    if (!values)
        return 0;
    return values->Effects[target->IsControlledByPlayer() ? EFFECT_1 : EFFECT_0].CalcValue();
}

struct TwoSchoolRule
{
    uint32 Aura;
    SpellSchools First;
    SpellSchools Second;
};

constexpr std::array<TwoSchoolRule, 21> TWO_SCHOOL = {{
    { 84589, SPELL_SCHOOL_NORMAL, SPELL_SCHOOL_ARCANE },
    { 84655, SPELL_SCHOOL_FIRE, SPELL_SCHOOL_ARCANE },
    { 84623, SPELL_SCHOOL_SHADOW, SPELL_SCHOOL_NATURE },
    { 84593, SPELL_SCHOOL_FIRE, SPELL_SCHOOL_HOLY },
    { 84579, SPELL_SCHOOL_NORMAL, SPELL_SCHOOL_HOLY },
    { 84635, SPELL_SCHOOL_SHADOW, SPELL_SCHOOL_FROST },
    { 84629, SPELL_SCHOOL_HOLY, SPELL_SCHOOL_FROST },
    { 84659, SPELL_SCHOOL_FROST, SPELL_SCHOOL_ARCANE },
    { 84617, SPELL_SCHOOL_NATURE, SPELL_SCHOOL_HOLY },
    { 84581, SPELL_SCHOOL_NORMAL, SPELL_SCHOOL_FIRE },
    { 84631, SPELL_SCHOOL_FIRE, SPELL_SCHOOL_FROST },
    { 84583, SPELL_SCHOOL_NATURE, SPELL_SCHOOL_NORMAL },
    { 84585, SPELL_SCHOOL_NORMAL, SPELL_SCHOOL_FROST },
    { 84653, SPELL_SCHOOL_HOLY, SPELL_SCHOOL_ARCANE },
    { 84641, SPELL_SCHOOL_SHADOW, SPELL_SCHOOL_HOLY },
    { 84619, SPELL_SCHOOL_NATURE, SPELL_SCHOOL_FIRE },
    { 84611, SPELL_SCHOOL_SHADOW, SPELL_SCHOOL_FIRE },
    { 84649, SPELL_SCHOOL_SHADOW, SPELL_SCHOOL_ARCANE },
    { 84625, SPELL_SCHOOL_NATURE, SPELL_SCHOOL_ARCANE },
    { 84587, SPELL_SCHOOL_SHADOW, SPELL_SCHOOL_NORMAL },
    { 84621, SPELL_SCHOOL_NATURE, SPELL_SCHOOL_FROST },
}};

constexpr std::array<uint32, MAX_SPELL_SCHOOL> SCHOOL_BUFF = { 286100, 286101, 286102, 286103, 286104, 286105, 286106 };

TwoSchoolRule const* TwoSchoolByAura(uint32 id)
{
    for (TwoSchoolRule const& rule : TWO_SCHOOL)
        if (rule.Aura == id)
            return &rule;
    return nullptr;
}

bool IsDamagingSpell(SpellInfo const* info)
{
    for (SpellEffectInfo const& effect : info->Effects)
    {
        switch (effect.Effect)
        {
            case SPELL_EFFECT_SCHOOL_DAMAGE:
            case SPELL_EFFECT_WEAPON_DAMAGE:
            case SPELL_EFFECT_WEAPON_DAMAGE_NOSCHOOL:
            case SPELL_EFFECT_NORMALIZED_WEAPON_DMG:
            case SPELL_EFFECT_WEAPON_PERCENT_DAMAGE:
            case SPELL_EFFECT_HEALTH_LEECH:
                return true;
            default:
                break;
        }
        if (effect.IsAura(SPELL_AURA_PERIODIC_DAMAGE) || effect.IsAura(SPELL_AURA_PERIODIC_LEECH) ||
            effect.IsAura(SPELL_AURA_PERIODIC_DAMAGE_PERCENT))
            return true;
    }
    return false;
}

class spell_dummyfix_warlock_two_school : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_warlock_two_school);

    bool Validate(SpellInfo const* info) override
    {
        return TwoSchoolByAura(info->Id) && ValidateSpellInfo(SCHOOL_BUFF);
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        TwoSchoolRule const* rule = TwoSchoolByAura(GetId());
        if (!rule || !info || !IsDamagingSpell(info) || !(eventInfo.GetSpellPhaseMask() & PROC_SPELL_PHASE_CAST))
            return false;
        return info->GetSchoolMask() & ((1 << rule->First) | (1 << rule->Second));
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        TwoSchoolRule const* rule = TwoSchoolByAura(GetId());
        uint32 const schools = eventInfo.GetSpellInfo()->GetSchoolMask();
        Unit* caster = GetTarget();
        if (schools & (1 << rule->First))
            caster->CastSpell(caster, SCHOOL_BUFF[rule->Second], true, nullptr, aurEff);
        if (schools & (1 << rule->Second))
            caster->CastSpell(caster, SCHOOL_BUFF[rule->First], true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_warlock_two_school::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_warlock_two_school::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

constexpr uint32 STANCE_DANCE = 81216;
constexpr uint32 BLOODRAGE_BUFF = 29131;

class dummyfix_warlock_shapeshift_hooks : public UnitScript
{
public:
    dummyfix_warlock_shapeshift_hooks() : UnitScript("dummyfix_warlock_shapeshift_hooks", true,
        { UNITHOOK_ON_UNIT_SET_SHAPESHIFT_FORM }) { }

    void OnUnitSetShapeshiftForm(Unit* unit, uint8 form) override
    {
        if (!unit || (form != FORM_BATTLESTANCE && form != FORM_DEFENSIVESTANCE && form != FORM_BERSERKERSTANCE))
            return;
        AuraEffect const* dance = unit->GetAuraEffect(STANCE_DANCE, EFFECT_0);
        Aura* bloodrage = unit->GetAura(BLOODRAGE_BUFF);
        if (!dance || !bloodrage)
            return;
        int32 const duration = bloodrage->GetDuration() + dance->GetAmount();
        bloodrage->SetMaxDuration(std::max(bloodrage->GetMaxDuration(), duration));
        bloodrage->SetDuration(duration);
    }
};

struct LearnWith
{
    uint32 Aura;
    uint32 Required;
    uint32 Taught;
};

constexpr std::array<LearnWith, 3> LEARN_WITH = {{
    { 84410, 5484, 300167 },
    { 997020, 50796, 997021 },
    { 982330, 686, 982331 },
}};

LearnWith const* LearnWithByAura(uint32 id)
{
    for (LearnWith const& rule : LEARN_WITH)
        if (rule.Aura == id)
            return &rule;
    return nullptr;
}

bool KnowsAnyRank(Player const* player, uint32 spell)
{
    for (SpellInfo const* rank = sSpellMgr->GetSpellInfo(sSpellMgr->GetFirstSpellInChain(spell)); rank;
         rank = rank->GetNextRankSpell())
        if (player->HasSpell(rank->Id))
            return true;
    return false;
}

class spell_dummyfix_warlock_learn_with : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_warlock_learn_with);

    bool _taught = false;

    bool Validate(SpellInfo const* info) override
    {
        LearnWith const* rule = LearnWithByAura(info->Id);
        return rule && ValidateSpellInfo({ rule->Required, rule->Taught });
    }

    void HandleApply(AuraEffect const* , AuraEffectHandleModes )
    {
        LearnWith const* rule = LearnWithByAura(GetId());
        Player* player = GetTarget()->ToPlayer();
        if (!rule || !player || player->HasSpell(rule->Taught) || !KnowsAnyRank(player, rule->Required))
            return;
        player->learnSpell(rule->Taught, true);
        _taught = true;
    }

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        LearnWith const* rule = LearnWithByAura(GetId());
        Player* player = GetTarget()->ToPlayer();
        if (!rule || !player || !_taught)
            return;
        _taught = false;
        player->removeSpell(rule->Taught, SPEC_MASK_ALL, true);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_dummyfix_warlock_learn_with::HandleApply, EFFECT_0, SPELL_AURA_DUMMY,
            AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummyfix_warlock_learn_with::HandleRemove, EFFECT_0,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

constexpr uint32 UNSTABLE_VOID = 977711;
constexpr uint32 BACKDRAFT_FINAL_RANK = 47260;
constexpr std::array<uint32, 3> STOCK_BACKDRAFT_BUFFS = { 54274, 54276, 54277 };
constexpr float UNSTABLE_VOID_CRIT = 20.0f;

bool UnstableVoidActive(Unit const* unit)
{
    Player const* player = unit ? unit->ToPlayer() : nullptr;
    return player && player->HasAura(UNSTABLE_VOID) && player->HasSpell(BACKDRAFT_FINAL_RANK);
}

class spell_dummyfix_warlock_unstable_void : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_warlock_unstable_void);

    void CalcAmount(AuraEffect const* , int32& amount, bool& )
    {
        if (UnstableVoidActive(GetUnitOwner()))
            amount = 0;
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_dummyfix_warlock_unstable_void::CalcAmount, EFFECT_ALL,
            SPELL_AURA_ADD_PCT_MODIFIER);
    }
};

constexpr std::array<uint32, 4> VANISH_RANKS = { 1856, 1857, 26889, 926889 };
constexpr uint32 SHADOW_DANCE = 51713;

class spell_dummyfix_warlock_ghastly_wraith : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_warlock_ghastly_wraith);

    void HandleApply(AuraEffect const* , AuraEffectHandleModes )
    {
        Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        if (!player)
            return;
        for (uint32 vanish : VANISH_RANKS)
            if (player->HasSpellCooldown(vanish))
                player->ModifySpellCooldown(vanish, -10000);
        if (player->HasSpellCooldown(SHADOW_DANCE))
            player->ModifySpellCooldown(SHADOW_DANCE, -2000);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_dummyfix_warlock_ghastly_wraith::HandleApply, EFFECT_0,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_dummyfix_warlock_burning_rush : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_warlock_burning_rush);

    void HandlePeriodic(AuraEffect const* aurEff)
    {
        PreventDefaultAction();
        Unit* warlock = GetTarget();
        if (!warlock->IsAlive())
            return;
        uint32 const pct = GetId() == 954806 ? 5 : uint32(std::max(0, aurEff->GetAmount()));
        uint32 const damage = CalculatePct(warlock->GetMaxHealth(), pct);
        if (!damage)
            return;
        Unit::DealDamage(warlock, warlock, damage, nullptr, SELF_DAMAGE, GetSpellInfo()->GetSchoolMask(), GetSpellInfo(),
            false);
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_dummyfix_warlock_burning_rush::HandlePeriodic, EFFECT_2,
            SPELL_AURA_PERIODIC_DUMMY);
    }
};

struct FamilyFlag
{
    SpellFamilyNames Family;
    uint8 Index;
    uint32 Flag;
};

constexpr std::array<FamilyFlag, 5> SOUL_HARVEST_DOTS = {{
    { SPELLFAMILY_WARLOCK, 0, 0x00000002 },
    { SPELLFAMILY_WARLOCK, 0, 0x00000400 },
    { SPELLFAMILY_WARLOCK, 0, 0x00000004 },
    { SPELLFAMILY_PRIEST, 0, 0x00008000 },
    { SPELLFAMILY_PRIEST, 0, 0x02000000 },
}};
constexpr int32 SOUL_HARVEST_PER_TARGET_MS = 3000;
constexpr int32 SOUL_HARVEST_MAX_MS = 24000;
constexpr float SOUL_HARVEST_RANGE = 100.0f;

class spell_dummyfix_warlock_soul_harvest : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_warlock_soul_harvest);

    void HandleApply(AuraEffect const* , AuraEffectHandleModes )
    {
        Unit* warlock = GetTarget();
        std::size_t const kinds = GetId() == 86395 ? SOUL_HARVEST_DOTS.size() : 3;
        std::list<Unit*> enemies;
        Acore::AnyUnfriendlyUnitInObjectRangeCheck check(warlock, warlock, SOUL_HARVEST_RANGE);
        Acore::UnitListSearcher<Acore::AnyUnfriendlyUnitInObjectRangeCheck> searcher(warlock, enemies, check);
        Cell::VisitObjects(warlock, searcher, SOUL_HARVEST_RANGE);
        int32 afflicted = 0;
        for (Unit* enemy : enemies)
            for (std::size_t i = 0; i < kinds; ++i)
                if (TargetHasFamilyAura(enemy, SOUL_HARVEST_DOTS[i].Family, SOUL_HARVEST_DOTS[i].Index,
                    SOUL_HARVEST_DOTS[i].Flag, warlock->GetGUID()))
                {
                    ++afflicted;
                    break;
                }
        if (!afflicted)
            return;
        int32 const duration = std::min(SOUL_HARVEST_MAX_MS, GetMaxDuration() + afflicted * SOUL_HARVEST_PER_TARGET_MS);
        SetMaxDuration(duration);
        SetDuration(duration);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_dummyfix_warlock_soul_harvest::HandleApply, EFFECT_0,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_dummyfix_warlock_blind_rage : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_warlock_blind_rage);

    void HandlePeriodic(AuraEffect const* )
    {
        Unit* target = GetTarget();
        if (!target->HasAuraType(SPELL_AURA_MOD_CONFUSE) && !target->HasAuraWithMechanic(1 << MECHANIC_DISORIENTED))
            PreventDefaultAction();
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_dummyfix_warlock_blind_rage::HandlePeriodic, EFFECT_1,
            SPELL_AURA_PERIODIC_TRIGGER_SPELL);
    }
};

constexpr uint32 GROWING_CORRUPTION = 977925;
constexpr uint32 CORRUPTION_R1 = 172;
constexpr uint32 WARLOCK_SEED_FLAG_1 = 0x00000010;

void GrowingCorruption(Unit* target, AuraApplication* application, AuraRemoveMode mode)
{
    Aura const* aura = application->GetBase();
    if (mode != AURA_REMOVE_BY_DEFAULT || !IsWarlockSpell(aura->GetSpellInfo(), 1, WARLOCK_SEED_FLAG_1) ||
        !target || !target->IsAlive())
        return;
    Player* warlock = aura->GetCaster() ? aura->GetCaster()->ToPlayer() : nullptr;
    if (!warlock || !warlock->HasAura(GROWING_CORRUPTION))
        return;
    uint32 corruption = 0;
    for (SpellInfo const* rank = sSpellMgr->GetSpellInfo(CORRUPTION_R1); rank; rank = rank->GetNextRankSpell())
        if (warlock->HasSpell(rank->Id))
            corruption = rank->Id;
    if (!corruption)
        return;
    ObjectGuid const targetGuid = target->GetGUID();
    warlock->m_Events.AddEventAtOffset([warlock, targetGuid, corruption]()
    {
        if (Unit* seeded = ObjectAccessor::GetUnit(*warlock, targetGuid))
            if (seeded->IsAlive())
                warlock->CastSpell(seeded, corruption, true);
    }, 1ms);
}

constexpr uint32 HELLISH_PURSUIT = 983065;
constexpr uint32 HELLFIRE_PURSUIT_PULSE = 983067;
constexpr uint32 BURNING_RUSH = 954806;
constexpr int32 HELLISH_PURSUIT_CDR_MS = 20500;

constexpr char HellishPursuitPulseKey[] = "AscensionDummyFixWarlock.HellishPursuitPulse";

struct HellishPursuitPulse final : DataMap::Base
{
    uint32 Last = 0;
};

void HellishPursuit(Unit* attacker, SpellInfo const* info)
{
    if (!attacker || !info || info->Id != HELLFIRE_PURSUIT_PULSE || !attacker->HasAura(HELLISH_PURSUIT))
        return;
    Player* player = attacker->ToPlayer();
    if (!player || !player->HasSpellCooldown(BURNING_RUSH))
        return;
    uint32 const now = uint32(GameTime::GetGameTimeMS().count());
    uint32& last = player->CustomData.GetDefault<HellishPursuitPulse>(HellishPursuitPulseKey)->Last;
    if (last && now - last < 500)
        return;
    last = now;
    player->ModifySpellCooldown(BURNING_RUSH, -HELLISH_PURSUIT_CDR_MS);
}

constexpr uint32 DESTRUCTIVE_REACH = 817918;
constexpr float DESTRUCTIVE_REACH_DISTANCE = 20.0f;

class dummyfix_warlock_crit_hooks : public AllSpellScript
{
public:
    dummyfix_warlock_crit_hooks() : AllSpellScript("dummyfix_warlock_crit_hooks", { ALLSPELLHOOK_ON_CRIT_CHANCE }) { }

    void OnSpellCritChance(Spell* spell, Unit* target, float& chance) override
    {
        Unit* caster = spell->GetCaster();
        SpellInfo const* info = spell->GetSpellInfo();
        if (!caster || !target || !info || !caster->IsPlayer())
            return;
        if (AuraEffect const* reach = caster->GetAuraEffect(DESTRUCTIVE_REACH, EFFECT_1))
            if (caster->GetDistance(target) > DESTRUCTIVE_REACH_DISTANCE)
                chance += float(reach->GetAmount());
        if (UnstableVoidActive(caster))
            for (uint32 buff : STOCK_BACKDRAFT_BUFFS)
                if (AuraEffect const* backdraft = caster->GetAuraEffect(buff, EFFECT_0))
                {
                    if (backdraft->IsAffectedOnSpell(info))
                        chance += UNSTABLE_VOID_CRIT;
                    break;
                }
    }
};

constexpr uint32 SOUL_SIPHONER = 81398;
constexpr float SOUL_SIPHONER_RANGE = 40.0f;
constexpr std::size_t SOUL_SIPHONER_TARGETS = 3;

class spell_dummyfix_warlock_soul_siphoner : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_warlock_soul_siphoner);

    void HandleAfterHit()
    {
        Unit* warlock = GetOriginalCaster() ? GetOriginalCaster() : GetCaster();
        Player* player = warlock ? warlock->ToPlayer() : nullptr;
        int32 heal = GetHitHeal();
        if (!player || GetHitUnit() != warlock || heal <= 0 || !player->HasAura(SOUL_SIPHONER))
            return;
        Group* group = player->GetGroup();
        if (!group)
            return;
        std::vector<Player*> members;
        for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
        {
            Player* member = ref->GetSource();
            if (member && member != player && member->IsAlive() && member->IsInMap(player) &&
                member->IsWithinDistInMap(player, SOUL_SIPHONER_RANGE))
                members.push_back(member);
        }
        std::sort(members.begin(), members.end(),
            [](Player const* a, Player const* b) { return a->GetHealthPct() < b->GetHealthPct(); });
        if (members.size() > SOUL_SIPHONER_TARGETS)
            members.resize(SOUL_SIPHONER_TARGETS);
        for (Player* member : members)
            warlock->CastCustomSpell(member, GetSpellInfo()->Id, &heal, nullptr, nullptr, true);
    }

    void Register() override
    {
        AfterHit += SpellHitFn(spell_dummyfix_warlock_soul_siphoner::HandleAfterHit);
    }
};

constexpr uint32 SIPHON_LIFE_HEAL = 63106;
constexpr uint32 GLYPH_OF_SIPHON_LIFE = 56216;

class spell_dummyfix_warlock_siphon_life : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_warlock_siphon_life);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        return damage && damage->GetDamage() && GetTarget()->IsAlive();
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* warlock = GetTarget();
        int32 amount = CalculatePct(int32(eventInfo.GetDamageInfo()->GetDamage()), aurEff->GetAmount());
        if (AuraEffect const* glyph = warlock->GetAuraEffectOfRankedSpellOrTwin(GLYPH_OF_SIPHON_LIFE, EFFECT_0))
            AddPct(amount, glyph->GetAmount());
        amount = std::min(amount, int32(CalculatePct(warlock->GetMaxHealth(), 5)));
        if (amount > 0)
            warlock->CastCustomSpell(SIPHON_LIFE_HEAL, SPELLVALUE_BASE_POINT0, amount, warlock, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_warlock_siphon_life::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_warlock_siphon_life::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

constexpr uint32 DARKMASTER = 983180;

void DarkmasterTouch(Unit* target, Unit* attacker)
{
    if (!attacker || !target || !attacker->IsCreature() || !attacker->IsCharmed())
        return;
    Unit* charmer = attacker->GetCharmer();
    Player* warlock = charmer ? charmer->ToPlayer() : nullptr;
    if (!warlock || target == warlock || !warlock->HasAura(DARKMASTER) || warlock->HasAura(NECROMANCERS_TOUCH))
        return;
    ObjectGuid const targetGuid = target->GetGUID();
    warlock->m_Events.AddEventAtOffset([warlock, targetGuid]()
    {
        if (Unit* victim = ObjectAccessor::GetUnit(*warlock, targetGuid))
            if (victim->IsAlive())
                warlock->CastSpell(victim, NECROMANCERS_TOUCH_DEBUFF, true);
    }, 1ms);
}

class dummyfix_warlock_unit_hooks : public UnitScript
{
public:
    dummyfix_warlock_unit_hooks() : UnitScript("dummyfix_warlock_unit_hooks", true,
        { UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN, UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK, UNITHOOK_ON_AURA_REMOVE,
          UNITHOOK_ON_DAMAGE }) { }

    void OnDamage(Unit* attacker, Unit* victim, uint32& damage) override
    {
        if (damage)
            NecromancersTouch(attacker, victim);
    }

    void ModifySpellDamageTaken(Unit* target, Unit* attacker, int32& damage, SpellInfo const* info) override
    {
        if (damage <= 0)
            return;
        if (int32 const pct = TargetAuraBonusPct(target, attacker, info, false))
            AddPct(damage, pct);
        if (int32 const pct = PyroclasmicShadowsPct(target, attacker, info))
            AddPct(damage, pct);
        AbsoluteHellfireTick(target, attacker, info);
        HellishPursuit(attacker, info);
        DarkmasterTouch(target, attacker);
    }

    void ModifyPeriodicDamageAurasTick(Unit* target, Unit* attacker, uint32& damage, SpellInfo const* info) override
    {
        if (!damage)
            return;
        if (int32 const pct = TargetAuraBonusPct(target, attacker, info, true))
            AddPct(damage, pct);
        if (int32 const pct = DarkHarvestPct(attacker, info))
            AddPct(damage, pct);
    }

    void OnAuraRemove(Unit* unit, AuraApplication* application, AuraRemoveMode mode) override
    {
        GrowingCorruption(unit, application, mode);
        Aura const* aura = application->GetBase();
        if (!IsWarlockSpell(aura->GetSpellInfo(), 0, WARLOCK_DRAIN_LIFE_FLAG))
            return;
        if (Unit* caster = aura->GetCaster())
            if (caster->HasAura(DARK_HARVEST))
                caster->m_Events.AddEventAtOffset([caster]() { caster->RemoveAurasDueToSpell(DARK_HARVEST); }, 1ms);
    }
};

class dummyfix_warlock_player_hooks : public PlayerScript
{
public:
    dummyfix_warlock_player_hooks() : PlayerScript("dummyfix_warlock_player_hooks",
        { PLAYERHOOK_ON_CREATURE_KILL, PLAYERHOOK_ON_PVP_KILL }) { }

    void OnPlayerCreatureKill(Player* killer, Creature* killed) override
    {
        DarkHarvestKill(killer, killed);
    }

    void OnPlayerPVPKill(Player* killer, Player* killed) override
    {
        DarkHarvestKill(killer, killed);
    }
};
}

void ApplyAscensionDummyFixWarlockContracts(SpellInfo* spellInfo)
{
    if (!spellInfo)
        return;

    switch (spellInfo->Id)
    {
        case 979779:
            if (spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_DUMMY)
            {
                spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_ASCENSION_OVERRIDE_SPELL;
                spellInfo->Effects[EFFECT_0].BasePoints = 978703;
                spellInfo->Effects[EFFECT_0].MiscValueB = 0;
                spellInfo->Effects[EFFECT_0].DieSides = 0;
                spellInfo->Effects[EFFECT_0].RealPointsPerLevel = 0.0f;
                spellInfo->Effects[EFFECT_0].PointsPerComboPoint = 0.0f;
            }
            break;
        case 982592:
            if (spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_DUMMY)
            {
                spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_ASCENSION_OVERRIDE_SPELL;
                spellInfo->Effects[EFFECT_0].MiscValue = 48181;
                spellInfo->Effects[EFFECT_0].BasePoints = 982593;
                spellInfo->Effects[EFFECT_0].MiscValueB = 0;
                spellInfo->Effects[EFFECT_0].DieSides = 0;
                spellInfo->Effects[EFFECT_0].RealPointsPerLevel = 0.0f;
                spellInfo->Effects[EFFECT_0].PointsPerComboPoint = 0.0f;
            }
            break;
        case 81477:
            if (spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_DUMMY)
            {
                spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_PROC_TRIGGER_SPELL;
                spellInfo->Effects[EFFECT_0].TriggerSpell = 81478;
            }
            break;
        case 283444:
            if (spellInfo->Effects[EFFECT_1].ApplyAuraName == SPELL_AURA_DUMMY)
            {
                spellInfo->Effects[EFFECT_1].ApplyAuraName = SPELL_AURA_ADD_PCT_MODIFIER;
                spellInfo->Effects[EFFECT_1].MiscValue = SPELLMOD_VALUE_MULTIPLIER;
                spellInfo->Effects[EFFECT_1].BasePoints = 125;
                spellInfo->Effects[EFFECT_1].DieSides = 0;
                spellInfo->Effects[EFFECT_1].SpellClassMask = flag96(0, 0, 0x40000000);
            }
            break;
        case 17962:
            if (spellInfo->Effects[EFFECT_1].Effect == SPELL_EFFECT_APPLY_AURA &&
                spellInfo->Effects[EFFECT_1].ApplyAuraName == SPELL_AURA_DUMMY)
            {
                spellInfo->Effects[EFFECT_1].ApplyAuraName = SPELL_AURA_PERIODIC_DAMAGE;
                spellInfo->Effects[EFFECT_1].Amplitude = 2000;
                spellInfo->DurationEntry = sSpellDurationStore.LookupEntry(32);
            }
            break;
        case 1318693:
        case 1353759:
            spellInfo->SpellIconID = 0;
            break;
        default:
            break;
    }
}

void AddAscensionDummyFixWarlockScripts()
{
    RegisterSpellScript(spell_dummyfix_warlock_guldans_chosen);
    RegisterSpellScript(spell_dummyfix_warlock_absolute_hellfire);
    RegisterSpellScript(spell_dummyfix_warlock_drunken_brawler);
    RegisterSpellScript(spell_dummyfix_warlock_crossover);
    RegisterSpellScript(spell_dummyfix_warlock_soulbound_split);
    RegisterSpellScript(spell_dummyfix_warlock_chilling_blows);
    RegisterSpellScript(spell_dummyfix_warlock_elemental_equilibrium);
    RegisterSpellScript(spell_dummyfix_warlock_immolating_backdraft);
    RegisterSpellScript(spell_dummyfix_warlock_two_school);
    RegisterSpellScript(spell_dummyfix_warlock_learn_with);
    RegisterSpellScript(spell_dummyfix_warlock_unstable_void);
    RegisterSpellScript(spell_dummyfix_warlock_ghastly_wraith);
    RegisterSpellScript(spell_dummyfix_warlock_burning_rush);
    RegisterSpellScript(spell_dummyfix_warlock_soul_harvest);
    RegisterSpellScript(spell_dummyfix_warlock_blind_rage);
    RegisterSpellScript(spell_dummyfix_warlock_soul_siphoner);
    RegisterSpellScript(spell_dummyfix_warlock_siphon_life);
    new dummyfix_warlock_crit_hooks();
    new dummyfix_warlock_shapeshift_hooks();
    new dummyfix_warlock_unit_hooks();
    new dummyfix_warlock_player_hooks();
}
