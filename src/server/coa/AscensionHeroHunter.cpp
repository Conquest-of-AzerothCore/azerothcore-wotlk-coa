/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionHeroHunter.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "Unit.h"

namespace
{
enum HeroHunterSpells : uint32
{
    EntrapmentRank1 = 19184,
    EntrapmentRank2 = 19387,
    EntrapmentRank3 = 19388,
    EntrapmentRoot1 = 19185,
    EntrapmentRoot2 = 64803,
    EntrapmentRoot3 = 64804,
    ImprovedGlaiveTossCapstone = 956033,
    WingClip = 2974
};

constexpr float IMPROVED_GLAIVE_TOSS_SLOW_RANGE = 15.0f;
constexpr uint32 GLAIVE_TOSS_FLAG2 = 0x01000000;
constexpr int32 IMPROVED_GLAIVE_TOSS_EXTRA_JUMPS = 2;

uint32 EntrapmentRoot(uint32 rank)
{
    switch (rank)
    {
        case EntrapmentRank1: return EntrapmentRoot1;
        case EntrapmentRank2: return EntrapmentRoot2;
        case EntrapmentRank3: return EntrapmentRoot3;
        default: return 0;
    }
}
}

class aura_hero_hunter_entrapment : public AuraScript
{
    PrepareAuraScript(aura_hero_hunter_entrapment);

    void HandleProc(AuraEffect const*, ProcEventInfo& eventInfo)
    {
        Unit* target = eventInfo.GetActionTarget();
        uint32 const root = EntrapmentRoot(GetId());
        if (target && root && target != GetTarget())
            GetTarget()->CastSpell(target, root, true);
    }

    void Register() override
    {
        OnEffectProc += AuraEffectProcFn(aura_hero_hunter_entrapment::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

class aura_hero_hunter_improved_glaive_toss : public AuraScript
{
    PrepareAuraScript(aura_hero_hunter_improved_glaive_toss);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        Unit* target = eventInfo.GetActionTarget();
        return target && GetTarget()->GetDistance(target) > IMPROVED_GLAIVE_TOSS_SLOW_RANGE;
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_hero_hunter_improved_glaive_toss::CheckProc);
    }
};

void ApplyAscensionHeroHunterContracts(SpellInfo* spellInfo)
{
    switch (spellInfo->Id)
    {
        case EntrapmentRank2:
            if (!spellInfo->Effects[EFFECT_0].Effect)
                if (SpellInfo const* rank1 = sSpellMgr->GetSpellInfo(EntrapmentRank1))
                    spellInfo->Effects[EFFECT_0] = rank1->Effects[EFFECT_0];
            break;
        case ImprovedGlaiveTossCapstone:
            if (!spellInfo->Effects[EFFECT_2].Effect)
            {
                SpellEffectInfo& jumps = spellInfo->Effects[EFFECT_2];
                jumps.Effect = SPELL_EFFECT_APPLY_AURA;
                jumps.ApplyAuraName = SPELL_AURA_ADD_FLAT_MODIFIER;
                jumps.MiscValue = SPELLMOD_JUMP_TARGETS;
                jumps.BasePoints = IMPROVED_GLAIVE_TOSS_EXTRA_JUMPS - 1;
                jumps.DieSides = 1;
                jumps.TargetA = SpellImplicitTargetInfo(TARGET_UNIT_CASTER);
                jumps.SpellClassMask = flag96(0, 0, GLAIVE_TOSS_FLAG2);
            }
            break;
        case WingClip:
            spellInfo->UseRangedAttackPowerForDamage = true;
            break;
        default:
            break;
    }
}

void AddSC_AscensionHeroHunter()
{
    RegisterSpellScript(aura_hero_hunter_entrapment);
    RegisterSpellScript(aura_hero_hunter_improved_glaive_toss);
}
