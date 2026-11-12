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

- Holy Constitution's disease resist, Death Plague 55604 (disease, magic, a periodic damage and a slow aura), 2 parts
  of 450 trials per arm: resisted 13.3% and 14.9% without 706323, 12.3% and 14.9% with it, in both runs of one counted
  pair. The stated +30 points lies outside the 99% interval: an alert. Putrid Bite 30113 read the same in a diagnostic.
  The aura's amount reads 30 on the caster. The cause is not located; it is a finding for the mentor, not a fix.
- A rate judged to +-2 points needs many trials: about 17,500 per arm for a 30-point difference near 4% and 34%. An
  alert whose interval excludes the band needs far fewer.
- No existing scenario changes.
- Tests: `test_behaviours.TakenResistRateTests`.
