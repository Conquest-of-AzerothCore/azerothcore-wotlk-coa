# 0138. Hit-ratio fixtures, site purchase, and the Judgement factor on Titanstrike's leech damage

- Status: accepted
- Date: 2026-11-11
- Supersedes: the Pious Sweep consequence of ADR 0137 ("about 2000 trials per arm would be needed against 166")

## Context

Chunk 2 of lean Templar batch 1 (`lean/batch1-c2-brief.md`), second half, had three problems:

- Damage bonuses on Holy spells could not be resolved by `hit_ratio`. Non-critical Chastise hits spread from 269 to
  408 against a 34-point die, and Titanstrike, Scourgebane and Condemn were as wide. The spread comes from the
  dummy's level-based magic resistance: `Unit::GetEffectiveResistChance` with `UsesLinearMonsterResistance`
  (`Unit.cpp:118-122`, `2582-2622`) gives partial resists, which no trial count within one scenario overcomes.
- Physical bonuses were limited by the spell's die.
- Tithe 804781 states a price and a place, and no existing kind reaches either.

## Considered options

1. Raise the trial count. Rejected: the band needs about 2000 trials per arm, and 166 fit in one scenario.
2. Remove the resistance and lift the stat part of the formula, both in both arms. Chosen:
   - the `fixture` field sets attack power and spell power;
   - the entry sets aura 823764 (`SPELL_AURA_MOD_TARGET_RESISTANCE` -9999 on the magic schools; its second effect is
     a family 33 modifier that no Templar spell matches).

   The ratio of the two arms is unchanged: resists and flat power act in both arms alike.
3. For Tithe: a `site_purchase` kind (teleport, purse, cast, `knows_spell` of the reward). Chosen.

## Decision

- `hit_ratio` gains:
  - `fixture`, flat player stats;
  - `warmup`, casts at the start of each arm, so a stacking damage over time is read at full stacks.
- `cast_applies_aura` gains `cast_spell` and `cast_target`, for an aura granted by casting another spell.
- `site_purchase` has four arms:
  - `outside`: away from every site, with the price, not learned (the control);
  - `paid`: at the first site, learned;
  - `spent`: at the second site with one copper short, not learned;
  - `topped_up`: after one copper more, learned.

  Readings are judged exactly.
- Server fix, backed by the tooltip as independent evidence: "Increases the damage of Scourgebane, Scarlet Hammer,
  and Titanstrike by $s1% on enemies below 20% health".
  - `AscensionTemplarAbilities.cpp:140-142` multiplies the launch-time damage in `OnSpellCalculatedTarget`.
  - Titanstrike's damage is `SPELL_EFFECT_HEALTH_LEECH`, handled at hit (`Spell::EffectHealthLeech`), so its launch
    damage is 0 and the factor never reached it. The diagnostic run read -3.5% against +25%.
  - `templar_scaling::ModifySpellDamageTaken` now applies the factor to a Titanstrike leech hit when the attacker
    holds Judgement and the target is below 20% health.

## Consequences

- Pious Sweep 76 and 77, One-Punch Man 190 and Judgement 28 are behaviour proven on two runs. Their 99% half-widths
  are at most 0.26 points.
- The Judgement Titanstrike entry is the regression check of the fix.
- Tithe 369 is behaviour proven. The "to empower your entire party" claim of 370 stays unproven: no reward spell's
  party effect is measured.
