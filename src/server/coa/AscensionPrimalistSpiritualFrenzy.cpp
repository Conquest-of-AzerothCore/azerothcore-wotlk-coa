/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "CellImpl.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "ObjectAccessor.h"
#include "Pet.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellScript.h"

#include <algorithm>
#include <list>
#include <vector>

namespace
{
enum SpiritualFrenzySpells : uint32
{
    SpiritualFrenzy = 707367,
    FrenziedPet = 707369
};

class aura_ascension_spiritual_frenzy : public AuraScript
{
    PrepareAuraScript(aura_ascension_spiritual_frenzy);

    bool Check(ProcEventInfo& event)
    {
        Player* owner = GetTarget()->ToPlayer();
        return owner && owner->getClass() == CLASS_WILDWALKER && owner->IsAlive() &&
            event.GetActor() == owner && owner->GetPet() && owner->GetPet()->IsAlive();
    }

    void Remove(AuraEffect const*, AuraEffectHandleModes)
    {
        if (Player* owner = GetTarget()->ToPlayer())
            if (Pet* pet = owner->GetPet())
                pet->RemoveAurasDueToSpell(FrenziedPet);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_spiritual_frenzy::Check);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_spiritual_frenzy::Remove,
            EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL);
    }
};

class aura_ascension_spiritual_frenzy_pet : public AuraScript
{
    PrepareAuraScript(aura_ascension_spiritual_frenzy_pet);
    bool _cleaving = false;

    bool Check(ProcEventInfo& event)
    {
        Pet* pet = GetTarget()->ToPet();
        Player* owner = pet && pet->GetOwner() ? pet->GetOwner()->ToPlayer() : nullptr;
        DamageInfo const* damage = event.GetDamageInfo();
        return !_cleaving && pet && pet->IsAlive() && owner && owner->getClass() == CLASS_WILDWALKER &&
            owner->IsAlive() && owner->HasAura(SpiritualFrenzy, owner->GetGUID()) &&
            event.GetActor() == pet && !event.GetSpellInfo() && damage && damage->GetDamage() &&
            (event.GetTypeMask() & PROC_FLAG_DONE_MELEE_AUTO_ATTACK);
    }

    void Cleave(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        Unit* pet = GetTarget();
        std::list<Unit*> units;
        float radius = pet->GetCombatReach() + NOMINAL_MELEE_RANGE;
        Acore::AnyUnitInObjectRangeCheck check(pet, radius);
        Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> search(pet, units, check);
        Cell::VisitObjects(pet, search, radius);
        units.remove_if([pet, &event](Unit* unit)
        {
            return unit == event.GetActionTarget() || !unit->IsAlive() || !pet->InSamePhase(unit) ||
                !pet->IsValidAttackTarget(unit) || !pet->IsWithinMeleeRange(unit) || !pet->IsWithinLOSInMap(unit);
        });
        units.sort([pet](Unit* left, Unit* right)
        {
            float lhs = pet->GetExactDistSq(left);
            float rhs = pet->GetExactDistSq(right);
            return lhs != rhs ? lhs < rhs : left->GetGUID() < right->GetGUID();
        });
        std::vector<ObjectGuid> targets;
        uint32 additional = uint32(std::clamp(effect->GetAmount() - 1, 0, 3));
        for (Unit* unit : units)
        {
            if (targets.size() == additional)
                break;
            targets.push_back(unit->GetGUID());
        }
        _cleaving = true;
        for (ObjectGuid guid : targets)
            if (Unit* unit = ObjectAccessor::GetUnit(*pet, guid); pet->IsAlive() && unit && unit->IsAlive())
                pet->AttackerStateUpdate(unit, BASE_ATTACK, true);
        _cleaving = false;
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_spiritual_frenzy_pet::Check);
        OnEffectProc += AuraEffectProcFn(aura_ascension_spiritual_frenzy_pet::Cleave, EFFECT_0, SPELL_AURA_DUMMY);
    }
};
}

void AddSC_AscensionPrimalistSpiritualFrenzy()
{
    RegisterSpellScript(aura_ascension_spiritual_frenzy);
    RegisterSpellScript(aura_ascension_spiritual_frenzy_pet);
}
