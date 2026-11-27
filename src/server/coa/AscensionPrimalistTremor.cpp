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
    TremorRage = 681280,
    TremblingRage = 560135
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

class primalist_tremor_contracts : public GlobalScript
{
public:
    primalist_tremor_contracts() : GlobalScript("primalist_tremor_contracts",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (!info || info->SpellFamilyName != 37)
            return;
        if (info->Id == TremorRage && info->SpellFamilyFlags == flag96(0, 0x8000000, 0))
            info->SpellFamilyFlags = flag96(0, 0, 0x4000);
        if (info->Id == TremblingRage &&
            info->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_ADD_FLAT_MODIFIER &&
            info->Effects[EFFECT_0].MiscValue == SPELLMOD_EFFECT1 &&
            info->Effects[EFFECT_0].SpellClassMask == flag96(0, 0x8000000, 0))
            info->Effects[EFFECT_0].SpellClassMask = flag96(0, 0, 0x4000);
    }
};
}

void AddSC_AscensionPrimalistTremor()
{
    new primalist_tremor_direct();
    new primalist_tremor_periodic();
    new primalist_tremor_contracts();
}
