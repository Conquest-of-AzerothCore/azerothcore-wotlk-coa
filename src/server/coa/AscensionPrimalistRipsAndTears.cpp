/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Pet.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellInfo.h"

namespace
{
enum RipsAndTearsSpells : uint32
{
    RipsAndTears = 800141,
    RipsRage = 521233,
    RipsFocus = 521231
};

class primalist_rips_and_tears : public UnitScript
{
public:
    primalist_rips_and_tears() : UnitScript("primalist_rips_and_tears", true,
        {UNITHOOK_ON_PERIODIC_DAMAGE_RESULT}) { }

    void OnPeriodicDamageResult(Unit*, Unit* caster, uint32 damage, SpellInfo const* info) override
    {
        if (!caster || !caster->IsAlive() || !damage || !info)
            return;
        Player* owner = caster->ToPlayer();
        if (owner && info->SpellFamilyName != 37)
            return;
        if (!owner)
        {
            Pet* pet = caster->ToPet();
            owner = pet ? pet->GetOwner() : nullptr;
            if (!owner || owner->GetPet() != pet)
                return;
        }
        if (owner->getClass() != CLASS_WILDWALKER || !owner->IsAlive() ||
            !owner->HasAura(RipsAndTears, owner->GetGUID()))
            return;
        owner->CastSpell(owner, RipsRage, TRIGGERED_FULL_MASK);
        if (Pet* pet = owner->GetPet(); pet && pet->IsAlive())
            owner->CastSpell(pet, RipsFocus, TRIGGERED_FULL_MASK);
    }
};
}

void AddSC_AscensionPrimalistRipsAndTears()
{
    new primalist_rips_and_tears();
}
