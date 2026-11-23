/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionDummyFixes.h"
#include "Containers.h"
#include "Creature.h"
#include "GameTime.h"
#include "Item.h"
#include "ItemTemplate.h"
#include "Pet.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "TemporarySummon.h"
#include "UnitScript.h"
#include <algorithm>
#include <array>
#include <functional>
#include <list>
#include <string_view>
#include <vector>

namespace
{
constexpr std::array<uint32, 3> BEAST_SHOT_CDR = { 983040, 983039, 983038 };

class spell_dummyfix_hunter_beast_shot_randomizer : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_hunter_beast_shot_randomizer);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ BEAST_SHOT_CDR[0], BEAST_SHOT_CDR[1], BEAST_SHOT_CDR[2] });
    }

    void HandleDummy(SpellEffIndex )
    {
        if (Unit* caster = GetCaster())
            caster->CastSpell(caster, Acore::Containers::SelectRandomContainerElement(BEAST_SHOT_CDR), true);
    }

    void Register() override
    {
        OnEffectHit += SpellEffectFn(spell_dummyfix_hunter_beast_shot_randomizer::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

constexpr std::array<uint32, 5> COMPANION_VISUALS = { 81424, 81425, 81426, 81427, 81428 };

std::vector<Creature*> TamedPets(Unit* owner)
{
    std::vector<Creature*> pets;
    if (Player* player = owner->ToPlayer())
        if (Pet* pet = player->GetPet())
            if (pet->IsInWorld())
                pets.push_back(pet);
    if (Unit* charm = owner->GetCharm())
        if (Creature* creature = charm->ToCreature())
            if (creature->IsInWorld() && std::find(pets.begin(), pets.end(), creature) == pets.end())
                pets.push_back(creature);
    return pets;
}

bool HasOtherCompanionVisual(Unit const* pet, uint32 visual)
{
    return std::any_of(COMPANION_VISUALS.begin(), COMPANION_VISUALS.end(),
        [pet, visual](uint32 other) { return other != visual && pet->HasAura(other); });
}

class spell_dummyfix_hunter_companion : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_hunter_companion);

    bool Validate(SpellInfo const* info) override
    {
        int32 const school = info->Effects[EFFECT_0].MiscValue;
        return school > SPELL_SCHOOL_NORMAL && school < MAX_SPELL_SCHOOL &&
            ValidateSpellInfo({ info->Effects[EFFECT_0].TriggerSpell });
    }

    void HandleTick(AuraEffect const* aurEff)
    {
        PreventDefaultAction();
        Unit* owner = GetTarget();
        uint32 const visual = aurEff->GetSpellInfo()->Effects[EFFECT_0].TriggerSpell;
        SpellSchools const school = SpellSchools(aurEff->GetMiscValue());
        for (Creature* pet : TamedPets(owner))
        {
            if (HasOtherCompanionVisual(pet, visual))
                continue;
            if (!pet->HasAura(visual, owner->GetGUID()))
                owner->AddAura(visual, pet);
            pet->SetMeleeDamageSchool(school);
        }
    }

    void HandleRemove(AuraEffect const* aurEff, AuraEffectHandleModes )
    {
        Unit* owner = GetTarget();
        uint32 const visual = aurEff->GetSpellInfo()->Effects[EFFECT_0].TriggerSpell;
        for (Creature* pet : TamedPets(owner))
        {
            if (!pet->HasAura(visual, owner->GetGUID()))
                continue;
            pet->RemoveAurasDueToSpell(visual, owner->GetGUID());
            pet->SetMeleeDamageSchool(SpellSchools(pet->GetCreatureTemplate()->dmgschool));
        }
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_dummyfix_hunter_companion::HandleTick, EFFECT_0,
            SPELL_AURA_PERIODIC_DUMMY);
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummyfix_hunter_companion::HandleRemove, EFFECT_0,
            SPELL_AURA_PERIODIC_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_dummyfix_hunter_molten_ammo : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_hunter_molten_ammo);

    bool Validate(SpellInfo const* info) override
    {
        return ValidateSpellInfo({ uint32(info->Effects[EFFECT_0].MiscValue) });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        Unit* target = eventInfo.GetActionTarget();
        return damage && damage->GetDamage() && target && target != GetTarget() && target->IsAlive();
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* target = eventInfo.GetActionTarget();
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        if (!target || !damage)
            return;
        int32 amount = int32(CalculatePct(damage->GetDamage(), aurEff->GetAmount()));
        if (amount <= 0)
            return;
        GetTarget()->CastCustomSpell(target, uint32(aurEff->GetMiscValue()), &amount, nullptr, nullptr, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_hunter_molten_ammo::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_hunter_molten_ammo::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

constexpr uint32 TUNDRA_TRACKER = 277488;
constexpr uint32 TUNDRA_TRACKER_TRIGGER = 277494;
constexpr uint8 TUNDRA_TRACKER_CONSUME = 9;
constexpr uint32 HUNTER_STEADY_SHOT_FLAG1 = 0x00000001;
constexpr std::array<uint32, 10> FINGERS_OF_FROST_TALENTS = { 44543, 44545, 414888, 844543, 844545, 978421, 1144543,
    1144545, 1244543, 1244545 };

bool KnowsFingersOfFrost(Unit const* unit)
{
    Player const* player = unit->ToPlayer();
    return player && std::any_of(FINGERS_OF_FROST_TALENTS.begin(), FINGERS_OF_FROST_TALENTS.end(),
        [player](uint32 talent) { return player->HasSpell(talent) || player->HasAura(talent); });
}

class spell_dummyfix_hunter_tundra_tracker : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_hunter_tundra_tracker);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ TUNDRA_TRACKER, TUNDRA_TRACKER_TRIGGER });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        return info && info->SpellFamilyName == SPELLFAMILY_HUNTER && info->DmgClass == SPELL_DAMAGE_CLASS_RANGED;
    }

    void HandleProc(AuraEffect const* , ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* hunter = GetTarget();
        uint32 const add = (eventInfo.GetSpellInfo()->SpellFamilyFlags[1] & HUNTER_STEADY_SHOT_FLAG1) ? 3 : 1;
        Aura* tracker = hunter->GetAura(TUNDRA_TRACKER, hunter->GetGUID());
        if (!tracker)
        {
            hunter->CastSpell(hunter, TUNDRA_TRACKER, true);
            tracker = hunter->GetAura(TUNDRA_TRACKER, hunter->GetGUID());
            if (!tracker)
                return;
            if (add > 1)
                tracker->SetStackAmount(uint8(add));
        }
        else
        {
            int32 const duration = tracker->GetDuration();
            uint32 const cap = std::max<uint32>(1, tracker->GetSpellInfo()->StackAmount);
            tracker->SetStackAmount(uint8(std::min<uint32>(tracker->GetStackAmount() + add, cap)));
            tracker->SetDuration(duration);
        }
        if (tracker->GetStackAmount() < TUNDRA_TRACKER_CONSUME)
            return;
        tracker->Remove();
        if (KnowsFingersOfFrost(hunter))
            hunter->CastSpell(hunter, TUNDRA_TRACKER_TRIGGER, true);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_hunter_tundra_tracker::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_hunter_tundra_tracker::HandleProc, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

constexpr uint32 SEETHING_FLAMES_DAMAGE = 84758;

class spell_dummyfix_hunter_seething_flames : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_hunter_seething_flames);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ SEETHING_FLAMES_DAMAGE });
    }

    void HandleTick(AuraEffect const* aurEff)
    {
        PreventDefaultAction();
        Unit* caster = GetCaster();
        Unit* target = GetTarget();
        SpellInfo const* damage = sSpellMgr->GetSpellInfo(SEETHING_FLAMES_DAMAGE);
        if (!caster || !target || !damage || !target->IsAlive())
            return;
        float const power = caster->GetTotalAttackPowerValue(RANGED_ATTACK) +
            float(caster->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_FIRE));
        int32 const amount = std::max(1, damage->Effects[EFFECT_0].CalcValue(caster) + int32(power * 0.0285f));
        CustomSpellValues values;
        values.AddSpellMod(SPELLVALUE_BASE_POINT0, amount);
        SpellCastTargets targets;
        targets.SetUnitTarget(target);
        targets.SetDst(*target);
        caster->CastSpell(targets, damage, &values, TRIGGERED_FULL_MASK, nullptr, aurEff);
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_dummyfix_hunter_seething_flames::HandleTick, EFFECT_0,
            SPELL_AURA_PERIODIC_DUMMY);
    }
};

constexpr uint32 WAXING_MOON_EXPLOSION = 983848;

class spell_dummyfix_hunter_waxing_moon : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_hunter_waxing_moon);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ WAXING_MOON_EXPLOSION });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        Unit* target = eventInfo.GetActionTarget();
        return GetStackAmount() >= std::max<uint32>(1, GetSpellInfo()->StackAmount) && target && target != GetTarget() &&
            target->IsAlive();
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        if (Unit* target = eventInfo.GetActionTarget())
            GetTarget()->CastSpell(target, WAXING_MOON_EXPLOSION, true, nullptr, aurEff);
        Unit* owner = GetTarget();
        uint32 const id = GetId();
        owner->m_Events.AddEventAtOffset([owner, id]() { owner->RemoveAurasDueToSpell(id); }, 1ms);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_hunter_waxing_moon::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_hunter_waxing_moon::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

struct StackGrantRule
{
    uint32 Enchant;
    uint32 Stack;
    uint32 Grant;
};

constexpr std::array<StackGrantRule, 2> FEL_ENERGY = {{
    { 84806, 983897, 983899 },
    { 84805, 983900, 84810 },
}};

StackGrantRule const* FelEnergyRule(uint32 enchant)
{
    for (StackGrantRule const& rule : FEL_ENERGY)
        if (rule.Enchant == enchant)
            return &rule;
    return nullptr;
}

class spell_dummyfix_hunter_fel_energy : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_hunter_fel_energy);

    TimePoint _ready{};

    bool Validate(SpellInfo const* info) override
    {
        StackGrantRule const* rule = FelEnergyRule(info->Id);
        return rule && ValidateSpellInfo({ rule->Stack, rule->Grant });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        HealInfo const* heal = eventInfo.GetHealInfo();
        return GameTime::Now() >= _ready && ((damage && damage->GetDamage()) || (heal && heal->GetHeal()));
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& )
    {
        PreventDefaultAction();
        StackGrantRule const* rule = FelEnergyRule(GetId());
        if (!rule || aurEff->GetSpellInfo()->Effects[aurEff->GetEffIndex()].TriggerSpell != rule->Stack ||
            GameTime::Now() < _ready)
            return;
        _ready = GameTime::Now() + 1s;
        Unit* owner = GetTarget();
        owner->CastSpell(owner, rule->Stack, true, nullptr, aurEff);
        Aura* stacks = owner->GetAura(rule->Stack, owner->GetGUID());
        if (!stacks || stacks->GetStackAmount() < std::max<uint32>(1, stacks->GetSpellInfo()->StackAmount))
            return;
        owner->CastSpell(owner, rule->Grant, true, nullptr, aurEff);
        owner->RemoveAurasDueToSpell(rule->Stack, owner->GetGUID());
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_hunter_fel_energy::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_hunter_fel_energy::HandleProc, EFFECT_ALL,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class spell_dummyfix_hunter_focused_burst : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_hunter_focused_burst);

    bool Validate(SpellInfo const* info) override
    {
        return ValidateSpellInfo({ info->Effects[EFFECT_1].TriggerSpell });
    }

    void HandleTick(AuraEffect const* aurEff)
    {
        PreventDefaultAction();
        Unit* caster = GetCaster();
        Unit* target = GetTarget();
        SpellInfo const* missile = sSpellMgr->GetSpellInfo(aurEff->GetSpellInfo()->Effects[aurEff->GetEffIndex()].TriggerSpell);
        if (!caster || !target || !missile || !target->IsAlive())
            return;
        int32 const scale = std::max<int32>(0, 100 - 10 * int32(aurEff->GetTickNumber()));
        CustomSpellValues values;
        for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
        {
            SpellEffectInfo const& effect = missile->Effects[i];
            if (effect.Effect == SPELL_EFFECT_WEAPON_PERCENT_DAMAGE || effect.Effect == SPELL_EFFECT_NORMALIZED_WEAPON_DMG ||
                effect.Effect == SPELL_EFFECT_WEAPON_DAMAGE || effect.Effect == SPELL_EFFECT_WEAPON_DAMAGE_NOSCHOOL ||
                effect.Effect == SPELL_EFFECT_SCHOOL_DAMAGE)
                values.AddSpellMod(SpellValueMod(SPELLVALUE_BASE_POINT0 + i), effect.CalcValue(caster) * scale / 100);
        }
        caster->CastCustomSpell(missile, values, target, TRIGGERED_FULL_MASK, nullptr, aurEff);
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_dummyfix_hunter_focused_burst::HandleTick, EFFECT_1,
            SPELL_AURA_PERIODIC_TRIGGER_SPELL);
    }
};

uint32 LoneWolfBuff(uint32 talent)
{
    return talent == 52783 ? 998785 : talent == 52785 ? 998786 : 0;
}

class spell_dummyfix_hunter_lone_wolf : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_hunter_lone_wolf);

    bool Validate(SpellInfo const* info) override
    {
        return LoneWolfBuff(info->Id) && ValidateSpellInfo({ LoneWolfBuff(info->Id) });
    }

    void Sync()
    {
        Unit* owner = GetTarget();
        uint32 const buff = LoneWolfBuff(GetId());
        bool const alone = TamedPets(owner).empty();
        bool const has = owner->HasAura(buff, owner->GetGUID());
        if (alone && !has)
            owner->CastSpell(owner, buff, true);
        else if (!alone && has)
            owner->RemoveAurasDueToSpell(buff, owner->GetGUID());
    }

    void HandleApply(AuraEffect const* , AuraEffectHandleModes )
    {
        Sync();
    }

    void HandleTick(AuraEffect const* )
    {
        PreventDefaultAction();
        Sync();
    }

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        GetTarget()->RemoveAurasDueToSpell(LoneWolfBuff(GetId()), GetTarget()->GetGUID());
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_dummyfix_hunter_lone_wolf::HandleApply, EFFECT_0,
            SPELL_AURA_PERIODIC_DUMMY, AURA_EFFECT_HANDLE_REAL);
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_dummyfix_hunter_lone_wolf::HandleTick, EFFECT_0,
            SPELL_AURA_PERIODIC_DUMMY);
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummyfix_hunter_lone_wolf::HandleRemove, EFFECT_0,
            SPELL_AURA_PERIODIC_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

constexpr uint32 FORBIDDEN_POWERS = 271998;
constexpr uint32 SHADOW_POWERS = 271983;

class spell_dummyfix_hunter_forbidden_technique_dance : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_hunter_forbidden_technique_dance);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ FORBIDDEN_POWERS, SHADOW_POWERS });
    }

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        Unit* target = GetTarget();
        if (GetTargetApplication()->GetRemoveMode() == AURA_REMOVE_BY_DEATH || !target->IsAlive() ||
            !target->HasAura(FORBIDDEN_POWERS))
            return;
        target->CastSpell(target, SHADOW_POWERS, true);
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummyfix_hunter_forbidden_technique_dance::HandleRemove, EFFECT_0,
            SPELL_AURA_ANY, AURA_EFFECT_HANDLE_REAL);
    }
};

constexpr uint32 TALONSHRIKE = 277790;
constexpr uint32 TALONSHRIKE_BUFF = 277791;

bool WieldsSingleTwoHander(Unit const* unit)
{
    Player const* player = unit->ToPlayer();
    if (!player)
        return false;
    Item const* main = player->GetItemByPos(INVENTORY_SLOT_BAG_0, EQUIPMENT_SLOT_MAINHAND);
    Item const* off = player->GetItemByPos(INVENTORY_SLOT_BAG_0, EQUIPMENT_SLOT_OFFHAND);
    return main && !off && main->GetTemplate()->InventoryType == INVTYPE_2HWEAPON;
}

class spell_dummyfix_hunter_talonshrike : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_hunter_talonshrike);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ TALONSHRIKE_BUFF });
    }

    void Sync()
    {
        Unit* owner = GetTarget();
        bool const wants = WieldsSingleTwoHander(owner);
        bool const has = owner->HasAura(TALONSHRIKE_BUFF, owner->GetGUID());
        if (wants && !has)
            owner->CastSpell(owner, TALONSHRIKE_BUFF, true);
        else if (!wants && has)
            owner->RemoveAurasDueToSpell(TALONSHRIKE_BUFF, owner->GetGUID());
    }

    void HandleApply(AuraEffect const* , AuraEffectHandleModes )
    {
        Sync();
    }

    void HandleTick(AuraEffect const* )
    {
        PreventDefaultAction();
        Sync();
    }

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        GetTarget()->RemoveAurasDueToSpell(TALONSHRIKE_BUFF, GetTarget()->GetGUID());
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_dummyfix_hunter_talonshrike::HandleApply, EFFECT_0,
            SPELL_AURA_PERIODIC_DUMMY, AURA_EFFECT_HANDLE_REAL);
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_dummyfix_hunter_talonshrike::HandleTick, EFFECT_0,
            SPELL_AURA_PERIODIC_DUMMY);
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummyfix_hunter_talonshrike::HandleRemove, EFFECT_0,
            SPELL_AURA_PERIODIC_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

constexpr uint32 HUNTER_MARK_FLAG0 = 0x00000400;

class spell_dummyfix_hunter_big_game_shot : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_hunter_big_game_shot);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        Unit* target = eventInfo.GetActionTarget();
        return target && target != GetTarget() &&
            target->GetAuraEffect(SPELL_AURA_MOD_STALKED, SPELLFAMILY_HUNTER, HUNTER_MARK_FLAG0, 0, 0, GetTarget()->GetGUID());
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_hunter_big_game_shot::CheckProc);
    }
};

constexpr uint32 DEADLY_BITE_BLEED = 272355;

class spell_dummyfix_hunter_deadly_bite : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_hunter_deadly_bite);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ DEADLY_BITE_BLEED });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        Unit* target = eventInfo.GetActionTarget();
        return damage && damage->GetDamage() && target && target != GetTarget() && target->IsAlive();
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* hunter = GetTarget();
        Unit* target = eventInfo.GetActionTarget();
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        if (!target || !damage)
            return;
        int32 const add = int32(CalculatePct(damage->GetDamage(), aurEff->GetAmount()));
        if (add <= 0)
            return;
        int32 remaining = 0;
        if (AuraEffect const* bleed = target->GetAuraEffect(DEADLY_BITE_BLEED, EFFECT_1, hunter->GetGUID()))
            remaining = bleed->GetAmount() * std::max<int32>(0, bleed->GetTotalTicks() - int32(bleed->GetTickNumber()));
        hunter->CastSpell(target, DEADLY_BITE_BLEED, true, nullptr, aurEff);
        if (AuraEffect* bleed = target->GetAuraEffect(DEADLY_BITE_BLEED, EFFECT_1, hunter->GetGUID()))
            bleed->ChangeAmount(std::max(1, (remaining + add) / std::max<int32>(1, bleed->GetTotalTicks())));
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_hunter_deadly_bite::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_hunter_deadly_bite::HandleProc, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

constexpr uint32 BINDING_SHOT_ARROW = 840081;
constexpr uint32 BINDING_SHOT_STUN = 1133047;
constexpr float BINDING_SHOT_TETHER = 5.0f;

class spell_dummyfix_hunter_binding_shot : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_hunter_binding_shot);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ BINDING_SHOT_STUN });
    }

    void HandleTick(AuraEffect const* )
    {
        PreventDefaultAction();
        Unit* target = GetTarget();
        ObjectGuid const owner = GetCasterGUID();
        std::list<Creature*> arrows;
        target->GetCreatureListWithEntryInGrid(arrows, BINDING_SHOT_ARROW, 40.0f);
        Creature* arrow = nullptr;
        for (Creature* candidate : arrows)
        {
            TempSummon const* summon = candidate->ToTempSummon();
            if ((candidate->GetOwnerGUID() == owner || (summon && summon->GetSummonerGUID() == owner)) &&
                (!arrow || target->GetExactDist2d(candidate) < target->GetExactDist2d(arrow)))
                arrow = candidate;
        }
        if (!arrow || target->GetExactDist2d(arrow) <= BINDING_SHOT_TETHER)
            return;
        if (Unit* caster = GetCaster())
            caster->CastSpell(target, BINDING_SHOT_STUN, true);
        else
            target->CastSpell(target, BINDING_SHOT_STUN, true);
        Remove();
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_dummyfix_hunter_binding_shot::HandleTick, EFFECT_1,
            SPELL_AURA_PERIODIC_DUMMY);
    }
};

class spell_dummyfix_hunter_rapid_recuperation : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_hunter_rapid_recuperation);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ 56654, 58882 });
    }

    void HandleRapidFire(AuraEffect const* , ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        if (!info || !(info->SpellFamilyFlags[0] & 0x00000020))
            PreventDefaultAction();
    }

    void HandleRapidKilling(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        SpellInfo const* info = eventInfo.GetSpellInfo();
        if (!info || !(info->SpellFamilyFlags[1] & 0x01000000))
            return;
        uint32 const regen = aurEff->GetAmount() >= 2 ? 58882 : 56654;
        GetTarget()->CastSpell(GetTarget(), regen, true, nullptr, aurEff);
    }

    void Register() override
    {
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_hunter_rapid_recuperation::HandleRapidFire, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_hunter_rapid_recuperation::HandleRapidKilling, EFFECT_1,
            SPELL_AURA_DUMMY);
    }
};

std::vector<uint32> CoolingHunterSpells(Player const* player, std::function<bool(SpellInfo const*)> const& match)
{
    std::vector<uint32> ids;
    for (auto const& [id, cooldown] : player->GetSpellCooldownMap())
        if (SpellInfo const* info = sSpellMgr->GetSpellInfo(id))
            if (info->SpellFamilyName == SPELLFAMILY_HUNTER && match(info))
                ids.push_back(id);
    return ids;
}

class spell_dummyfix_hunter_deadly_aim : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_hunter_deadly_aim);

    void HandleDummy(SpellEffIndex )
    {
        Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        if (!player)
            return;
        flag96 const mask = GetSpellInfo()->Effects[EFFECT_0].SpellClassMask;
        for (uint32 id : CoolingHunterSpells(player, [&mask](SpellInfo const* info) { return bool(info->SpellFamilyFlags & mask); }))
            player->RemoveSpellCooldown(id, true);
    }

    void Register() override
    {
        OnEffectHit += SpellEffectFn(spell_dummyfix_hunter_deadly_aim::HandleDummy, EFFECT_ALL, SPELL_EFFECT_DUMMY);
    }
};

constexpr int32 PARATROOPER_CDR_MS = 10500;

class spell_dummyfix_hunter_paratrooper : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_hunter_paratrooper);

    TimePoint _ready{};

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        Unit* target = eventInfo.GetActionTarget();
        return GameTime::Now() >= _ready && target && target != GetTarget() && !target->IsPlayer() &&
            !target->IsControlledByPlayer() && GetTarget()->IsPlayer();
    }

    void HandleProc(AuraEffect const* , ProcEventInfo& )
    {
        PreventDefaultAction();
        Player* player = GetTarget()->ToPlayer();
        if (!player || GameTime::Now() < _ready)
            return;
        _ready = GameTime::Now() + 1s;
        auto const named = [](SpellInfo const* info)
        {
            char const* name = info->SpellName[LOCALE_enUS];
            return name && (std::string_view(name) == "Disengage" || std::string_view(name) == "Paratrooper");
        };
        for (uint32 id : CoolingHunterSpells(player, named))
            player->ModifySpellCooldown(id, -PARATROOPER_CDR_MS);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_hunter_paratrooper::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_hunter_paratrooper::HandleProc, EFFECT_1, SPELL_AURA_DUMMY);
    }
};

constexpr uint32 SPOT_WEAKNESS_REBORN = 1589722;
constexpr uint32 HUNTER_KILL_SHOT_FLAG1 = 0x00800000;
constexpr uint32 BULLSEYE = 272132;
constexpr std::array<uint32, 2> PIERCING_SHOTS_BLEEDS = { 63468, 1163468 };

class dummyfix_hunter_unit_hooks : public UnitScript
{
public:
    dummyfix_hunter_unit_hooks() : UnitScript("dummyfix_hunter_unit_hooks", true,
        { UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN, UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK }) { }

    void ModifySpellDamageTaken(Unit* target, Unit* attacker, int32& damage, SpellInfo const* info) override
    {
        if (!target || !attacker || !info || damage <= 0 || info->SpellFamilyName != SPELLFAMILY_HUNTER ||
            !(info->SpellFamilyFlags[1] & HUNTER_KILL_SHOT_FLAG1) || target->GetHealthPct() <= 20.0f)
            return;
        if (AuraEffect const* weakness = attacker->GetAuraEffect(SPOT_WEAKNESS_REBORN, EFFECT_1))
            if (weakness->GetAmount() > 0)
                damage = std::max(0, damage - int32(CalculatePct(damage, weakness->GetAmount())));
    }

    void ModifyPeriodicDamageAurasTick(Unit* , Unit* attacker, uint32& damage, SpellInfo const* info) override
    {
        if (!attacker || !info || !damage ||
            std::find(PIERCING_SHOTS_BLEEDS.begin(), PIERCING_SHOTS_BLEEDS.end(), info->Id) == PIERCING_SHOTS_BLEEDS.end())
            return;
        if (AuraEffect const* bullseye = attacker->GetAuraEffect(BULLSEYE, EFFECT_1))
            if (bullseye->GetAmount() > 0)
                AddPct(damage, bullseye->GetAmount());
    }
};
}

void ApplyAscensionDummyFixHunterContracts(SpellInfo* spellInfo)
{
    if (!spellInfo)
        return;

    switch (spellInfo->Id)
    {
        case 276669:
            if (spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_DUMMY)
            {
                spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_PROC_TRIGGER_SPELL;
                spellInfo->Effects[EFFECT_0].TriggerSpell = 276632;
            }
            break;
        case 52783:
        case 52785:
            if (spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_DUMMY)
            {
                spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
                spellInfo->Effects[EFFECT_0].Amplitude = 1000;
            }
            break;
        case 277790:
            if (spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_DUMMY)
            {
                spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
                spellInfo->Effects[EFFECT_0].Amplitude = 1000;
            }
            break;
        case 276668:
            if (spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_DUMMY)
            {
                spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_PROC_TRIGGER_SPELL;
                spellInfo->Effects[EFFECT_0].TriggerSpell = 997054;
            }
            break;
        case 982375:
            if (!spellInfo->Effects[EFFECT_1].Effect && spellInfo->Effects[EFFECT_1].ApplyAuraName == SPELL_AURA_PROC_TRIGGER_SPELL)
            {
                spellInfo->Effects[EFFECT_1].Effect = SPELL_EFFECT_APPLY_AURA;
                spellInfo->Effects[EFFECT_1].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_CASTER);
            }
            break;
        default:
            break;
    }
}

void AddAscensionDummyFixHunterScripts()
{
    RegisterSpellScript(spell_dummyfix_hunter_beast_shot_randomizer);
    RegisterSpellScript(spell_dummyfix_hunter_companion);
    RegisterSpellScript(spell_dummyfix_hunter_molten_ammo);
    RegisterSpellScript(spell_dummyfix_hunter_tundra_tracker);
    RegisterSpellScript(spell_dummyfix_hunter_seething_flames);
    RegisterSpellScript(spell_dummyfix_hunter_waxing_moon);
    RegisterSpellScript(spell_dummyfix_hunter_fel_energy);
    RegisterSpellScript(spell_dummyfix_hunter_focused_burst);
    RegisterSpellScript(spell_dummyfix_hunter_lone_wolf);
    RegisterSpellScript(spell_dummyfix_hunter_forbidden_technique_dance);
    RegisterSpellScript(spell_dummyfix_hunter_talonshrike);
    RegisterSpellScript(spell_dummyfix_hunter_big_game_shot);
    RegisterSpellScript(spell_dummyfix_hunter_deadly_bite);
    RegisterSpellScript(spell_dummyfix_hunter_binding_shot);
    RegisterSpellScript(spell_dummyfix_hunter_rapid_recuperation);
    RegisterSpellScript(spell_dummyfix_hunter_deadly_aim);
    RegisterSpellScript(spell_dummyfix_hunter_paratrooper);
    new dummyfix_hunter_unit_hooks();
}
