/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellInfo.h"

namespace
{
enum BramblepatchSpells : uint32
{
    BramblepatchAllies = 807120,
    BramblepatchEnemies = 807859
};

class primalist_bramblepatch_metadata : public GlobalScript
{
public:
    primalist_bramblepatch_metadata() : GlobalScript("primalist_bramblepatch_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->SpellFamilyName != 37)
            return;
        if (info->Id == BramblepatchEnemies)
        {
            for (SpellEffectInfo& effect : info->Effects)
                if (effect.IsAura(SPELL_AURA_EFFECT_IMMUNITY))
                    effect.ApplyAuraName = SPELL_AURA_DUMMY;
        }
        else if (info->Id == BramblepatchAllies &&
            info->Effects[EFFECT_0].IsAura(SPELL_AURA_MOD_DAMAGE_PERCENT_TAKEN))
        {
            info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_EFFECT_IMMUNITY;
            info->Effects[EFFECT_0].MiscValue = SPELL_EFFECT_KNOCK_BACK_DEST;
        }
    }
};

class primalist_bramblepatch_movement : public AllSpellScript
{
public:
    primalist_bramblepatch_movement() : AllSpellScript("primalist_bramblepatch_movement",
        {ALLSPELLHOOK_ON_SPELL_CHECK_CAST}) { }

    void OnSpellCheckCast(Spell* spell, bool, SpellCastResult& result) override
    {
        if (result != SPELL_CAST_OK || !spell->GetCaster()->HasAura(BramblepatchEnemies))
            return;
        for (SpellEffectInfo const& effect : spell->GetSpellInfo()->Effects)
            switch (effect.Effect)
            {
                case SPELL_EFFECT_LEAP:
                case SPELL_EFFECT_JUMP:
                case SPELL_EFFECT_JUMP_DEST:
                case SPELL_EFFECT_CHARGE:
                case SPELL_EFFECT_CHARGE_DEST:
                case SPELL_EFFECT_LEAP_BACK:
                    result = SPELL_FAILED_NOT_HERE;
                    return;
                default:
                    break;
            }
    }
};
}

void AddSC_AscensionPrimalistBramblepatch()
{
    new primalist_bramblepatch_metadata();
    new primalist_bramblepatch_movement();
}
