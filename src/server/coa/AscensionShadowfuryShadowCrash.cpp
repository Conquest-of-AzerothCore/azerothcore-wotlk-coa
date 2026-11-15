/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"

namespace
{
enum ShadowCrashSpells : uint32
{
    ShadowCrashMissile = 273459,
    ScrollShadowCrash = 273455,
    TalentShadowCrash = 977714,
    ScrollShadowCrashEnchant = 273458,
    ScrollPureShadow = 273456,
    TalentPureShadow = 977713,
    TalentPureShadowStacks = 977715
};

bool FullyStacked(Unit* caster, uint32 spellId)
{
    Aura* aura = caster->GetAura(spellId);
    return aura && aura->GetStackAmount() >= aura->GetSpellInfo()->StackAmount;
}

class shadowfury_shadow_crash_metadata : public GlobalScript
{
public:
    shadowfury_shadow_crash_metadata() : GlobalScript("shadowfury_shadow_crash_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id == ScrollShadowCrash || info->Id == TalentShadowCrash)
            info->AttributesCu |= SPELL_ATTR0_CU_SHARE_DAMAGE;
        for (SpellEffectInfo& effect : info->Effects)
            if (effect.Effect == SPELL_EFFECT_TRIGGER_MISSILE && effect.TriggerSpell == ShadowCrashMissile)
                effect.Effect = 0;
    }
};

class shadowfury_shadow_crash : public AllSpellScript
{
public:
    shadowfury_shadow_crash() : AllSpellScript("shadowfury_shadow_crash", {ALLSPELLHOOK_ON_CAST}) { }

    void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const* info, bool) override
    {
        if (!caster->IsPlayer() || info->Effects[EFFECT_2].TriggerSpell != ShadowCrashMissile ||
            !spell->m_targets.HasDst())
            return;

        uint32 crash = 0;
        if (caster->HasAura(ScrollShadowCrashEnchant) && FullyStacked(caster, ScrollPureShadow))
            crash = ScrollShadowCrash;
        else if (caster->HasAura(TalentPureShadow) && FullyStacked(caster, TalentPureShadowStacks))
            crash = TalentShadowCrash;
        if (!crash)
            return;

        SpellCastTargets targets;
        targets.SetDst(*spell->m_targets.GetDstPos());
        caster->CastSpell(targets, sSpellMgr->GetSpellInfo(crash), nullptr, TRIGGERED_FULL_MASK);
    }
};
}

void AddSC_AscensionShadowfuryShadowCrash()
{
    new shadowfury_shadow_crash_metadata();
    new shadowfury_shadow_crash();
}
