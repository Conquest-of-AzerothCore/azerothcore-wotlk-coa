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

// Entrapment 19184/19387/19388: "When your Frost Trap or Snake Trap is triggered you entrap all afflicted targets,
// preventing them from moving for 2/3/4 sec." Spell.dbc carries a dummy aura instead of the trigger aura, so the
// trap activation procs nothing; root each trapped target with the rank's own root.
class aura_hero_hunter_entrapment : public AuraScript
{
    PrepareAuraScript(aura_hero_hunter_entrapment);

    void HandleProc(AuraEffect const* /*aurEff*/, ProcEventInfo& eventInfo)
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

// Improved Glaive Toss capstone: "if you are further than 15 yards away targets hit are slowed by 30% for 3 sec."
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
        // Entrapment rank 2 has no effects in Spell.dbc: give it rank 1's dummy aura so it can proc.
        case EntrapmentRank2:
            if (!spellInfo->Effects[EFFECT_0].Effect)
                if (SpellInfo const* rank1 = sSpellMgr->GetSpellInfo(EntrapmentRank1))
                    spellInfo->Effects[EFFECT_0] = rank1->Effects[EFFECT_0];
            break;
        // Improved Glaive Toss capstone: "Your Glaive Toss jumps to 2 additional nearby targets." Spell.dbc has no
        // effect for it; add the jump-target modifier on Glaive Toss in the empty third slot.
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
        // Wing Clip: "{RAP*0.4+96}" scales from ranged attack power although it is a melee ability.
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
