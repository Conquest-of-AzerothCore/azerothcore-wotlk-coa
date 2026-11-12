# 0196. Count how often a strike's aura takes hold on the caster

- Status: accepted
- Date: 2026-11-12

## Context

Holy Constitution 706323 "increases your chance to resist disease effects by $s2%" (Effect[1], SPELL_AURA_MOD_DEBUFF_
RESISTANCE, disease, +30). `Unit::MagicSpellHitResult` adds that amount to the resist chance of a magic spell whose
effects are all auras, when its Dispel matches. The claims (234, 235) had only a readback and a free-text label. A
resist is a rate: the share of disease strikes that do not take hold.

## Considered options

1. Read a miss log. Rejected: the harness keeps no `SMSG_SPELLLOGMISS`.
2. Each trial, read whether the strike's aura is on the caster, then remove it, and judge the arms' difference of
   resisted shares in points. Chosen.

## Decision

- `taken_hit` takes `judge: "resist_rate"` with `expected_points`: arms `control` and `treatment`; each trial sets the
  arm's auras, the striker casts `strike_spell` at the caster, 300 ms later the scenario reads the strike's aura on the
  caster and removes it. The judge takes 100 for a trial whose aura is absent, 0 otherwise, and compares the
  difference of the arms' means with `expected_points` inside the larger of 5% of it and 2 points.
- Entries with `parts` (ADR 0195) pool `resist_rate` parts as they pool `hit_ratio` parts; `generate` stamps `parts`
  into every expectation of a pooled entry.

## Consequences

- The strike must be a magic-class disease (DmgClass 1): `Unit::SpellHitResult` sends a melee- or ranged-class spell
  to `MeleeSpellHitResult` (Unit.cpp:4166-4170), which never reads aura 178. Death Plague 55604 and Putrid Bite 30113
  are melee-class (DmgClass 2), so the first counted pair (20261112-000437, -000508: 13.3% / 12.3% and 14.9% / 14.9%
  resisted without and with the talent) measured melee misses, dodges and parries, not the claim. That was an
  incorrect test, found by the review (lean/ext2-review.md, I4), not a defect.
- With Tetanus 8014 (Dispel 3 disease, DmgClass 1 magic, one SPELL_AURA_MOD_STAT effect, family 0): step one, 800
  trials per arm (20261112-003655), +32.1 points (99% +27.5 to +36.8), not judged; pooled proof, 28 parts x 800 =
  22,400 per arm, one counted pair (20261112-003747, -003837): +29.90 (+29.02 to +30.79) and +30.62 (+29.74 to
  +31.50) points against +30, inside +-2 in both. Claims 234 and 235 are behaviour proven.
- A rate judged to +-2 points needs many trials: about 17,500 per arm for a 30-point difference near 4% and 34%.
- No existing scenario changes.
- Tests: `test_behaviours.TakenResistRateTests`.
