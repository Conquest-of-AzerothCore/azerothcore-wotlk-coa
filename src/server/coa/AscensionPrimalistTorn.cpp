/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "SpellInfo.h"

namespace
{
constexpr uint32 TornToShredsBleed = 560313;

class primalist_torn_damage : public UnitScript
{
public:
    primalist_torn_damage() : UnitScript("primalist_torn_damage",
        true, {UNITHOOK_MODIFY_SPELL_EFFECT_BASE_VALUE}) { }

    void ModifySpellEffectBaseValue(Unit const* caster, SpellInfo const* info, uint8 index,
        float& value) override
    {
        if (!caster || !caster->IsPlayer() || caster->getClass() != CLASS_WILDWALKER ||
            info->Id != TornToShredsBleed || index != EFFECT_0 ||
            info->Effects[EFFECT_0].ApplyAuraName != SPELL_AURA_PERIODIC_DAMAGE)
            return;

        if (uint32 ticks = info->GetMaxTicks())
            value /= float(ticks);
    }
};
}

void AddSC_AscensionPrimalistTorn()
{
    new primalist_torn_damage();
}
