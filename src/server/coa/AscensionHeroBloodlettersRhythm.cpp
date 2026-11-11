/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
#include <iterator>

namespace
{
constexpr uint32 BloodlettersRhythmBuff = 288961;
constexpr uint32 DeathKnightSpellFamily = 15;
constexpr int32 FullCostPct = 100;
constexpr uint32 FreeStrikes[] = {
    49998, 49999, 45463, 49923, 49924,
    55050, 55258, 55259, 55260, 55261, 55262,
    56815
};

bool IsRhythmFull(Aura const* rhythm)
{
    return rhythm && rhythm->GetStackAmount() >= rhythm->GetSpellInfo()->StackAmount;
}

bool IsFreeStrike(SpellInfo const* info)
{
    uint32 const source = sSpellMgr->GetSpellTwinSource(info->Id);
    return std::find(std::begin(FreeStrikes), std::end(FreeStrikes), source) != std::end(FreeStrikes);
}

class hero_bloodletters_rhythm_free_strike : public GlobalScript
{
public:
    hero_bloodletters_rhythm_free_strike() : GlobalScript("hero_bloodletters_rhythm_free_strike",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR, GLOBALHOOK_ON_SPELL_MOD_FAMILY_MASK}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        SpellEffectInfo& effect = info->Effects[EFFECT_0];
        if (info->Id != BloodlettersRhythmBuff || info->SpellFamilyName != DeathKnightSpellFamily ||
            info->StackAmount < 2 || !effect.IsAura(SPELL_AURA_DUMMY))
            return;

        int32 const costCutPerStack = (FullCostPct + int32(info->StackAmount) - 1) / int32(info->StackAmount);
        effect.ApplyAuraName = SPELL_AURA_ADD_PCT_MODIFIER;
        effect.BasePoints = -costCutPerStack - 1;
        effect.DieSides = 1;
        effect.MiscValue = SPELLMOD_COST;
        effect.SpellClassMask = flag96(0x1000010, 0x20000000, 0);
        info->ProcFlags = 0;
    }

    void OnSpellModFamilyMask(SpellInfo const* affect, SpellInfo const* check,
        SpellModifier const* mod, bool& affected) override
    {
        if (affect->Id != BloodlettersRhythmBuff)
            return;
        affected = IsFreeStrike(check) && IsRhythmFull(mod->ownerAura);
    }
};

class spell_hero_bloodletters_rhythm_strike : public SpellScript
{
    PrepareSpellScript(spell_hero_bloodletters_rhythm_strike);

    void Capture()
    {
        spendsRhythm = IsRhythmFull(GetCaster()->GetAura(BloodlettersRhythmBuff));
    }

    void Consume()
    {
        if (spendsRhythm)
            GetCaster()->RemoveAurasDueToSpell(BloodlettersRhythmBuff);
    }

    void Register() override
    {
        BeforeCast += SpellCastFn(spell_hero_bloodletters_rhythm_strike::Capture);
        AfterCast += SpellCastFn(spell_hero_bloodletters_rhythm_strike::Consume);
    }

    bool spendsRhythm = false;
};
}

void AddSC_AscensionHeroBloodlettersRhythm()
{
    new hero_bloodletters_rhythm_free_strike();
    RegisterSpellScript(spell_hero_bloodletters_rhythm_strike);
}
