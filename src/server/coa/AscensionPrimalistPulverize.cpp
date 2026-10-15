/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellInfo.h"
#include "SpellMgr.h"

namespace
{
enum PulverizeSpells : uint32
{
    TotemicSmash = 800178,
    Pulverize = 301087,
    SmashArea = 500945
};

class primalist_pulverize_metadata : public GlobalScript
{
public:
    primalist_pulverize_metadata() : GlobalScript("primalist_pulverize_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id == SmashArea && info->SpellFamilyName == 37)
        {
            info->Effects[EFFECT_0].TargetA = SpellImplicitTargetInfo(TARGET_DEST_DEST);
            info->Effects[EFFECT_0].TargetB = SpellImplicitTargetInfo(TARGET_UNIT_DEST_AREA_ENEMY);
        }
    }
};

class primalist_pulverize : public AllSpellScript
{
public:
    primalist_pulverize() : AllSpellScript("primalist_pulverize", {ALLSPELLHOOK_ON_HIT_RESULT}) { }

    void OnSpellHitResult(Spell* spell, Unit* target, uint8 miss, uint32 damage, uint32, bool critical) override
    {
        Unit* caster = spell->GetCaster();
        SpellInfo const* info = spell->GetSpellInfo();
        if (!caster->IsPlayer() || caster->getClass() != CLASS_WILDWALKER || !caster->IsAlive() ||
            info->SpellFamilyName != 37 || sSpellMgr->GetFirstSpellInChain(info->Id) != TotemicSmash ||
            miss != SPELL_MISS_NONE || !damage || !critical || !target ||
            target != spell->m_targets.GetUnitTarget() || !caster->HasAura(Pulverize, caster->GetGUID()) ||
            spell->GetScriptValue(Pulverize))
            return;

        spell->SetScriptValue(Pulverize, 1);
        int32 base = spell->CalculateSpellDamage(EFFECT_1, target);
        CustomSpellValues values;
        values.AddSpellMod(SPELLVALUE_BASE_POINT0, base);
        SpellCastTargets targets;
        targets.SetDst(target->GetPosition());
        caster->CastSpell(targets, sSpellMgr->GetSpellInfo(SmashArea), &values, TRIGGERED_FULL_MASK);
    }
};
}

void AddSC_AscensionPrimalistPulverize()
{
    new primalist_pulverize_metadata();
    new primalist_pulverize();
}
