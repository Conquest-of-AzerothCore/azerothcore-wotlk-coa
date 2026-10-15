/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellInfo.h"
#include "SpellMgr.h"

namespace
{
enum TremorSpells : uint32
{
    SeismicTremor = 680442,
    TremorRage = 681280
};

void EnergizeTremor(Unit* caster, SpellInfo const* info, uint32 damage)
{
    if (caster && caster->IsPlayer() && caster->getClass() == CLASS_WILDWALKER &&
        caster->IsAlive() && damage && info && info->SpellFamilyName == 37 &&
        sSpellMgr->GetFirstSpellInChain(info->Id) == SeismicTremor)
        caster->CastSpell(caster, TremorRage, TRIGGERED_FULL_MASK);
}

class primalist_tremor_direct : public AllSpellScript
{
public:
    primalist_tremor_direct() : AllSpellScript("primalist_tremor_direct",
        {ALLSPELLHOOK_ON_HIT_RESULT}) { }

    void OnSpellHitResult(Spell* spell, Unit*, uint8 miss, uint32 damage, uint32, bool) override
    {
        if (miss == SPELL_MISS_NONE)
            EnergizeTremor(spell->GetCaster(), spell->GetSpellInfo(), damage);
    }
};

class primalist_tremor_periodic : public UnitScript
{
public:
    primalist_tremor_periodic() : UnitScript("primalist_tremor_periodic", true,
        {UNITHOOK_ON_PERIODIC_DAMAGE_RESULT}) { }

    void OnPeriodicDamageResult(Unit*, Unit* caster, uint32 damage, SpellInfo const* info) override
    {
        EnergizeTremor(caster, info, damage);
    }
};
}

void AddSC_AscensionPrimalistTremor()
{
    new primalist_tremor_direct();
    new primalist_tremor_periodic();
}
