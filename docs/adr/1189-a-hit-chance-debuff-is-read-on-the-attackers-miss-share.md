# 1189. A hit-chance debuff is read on the attackers' miss share

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-22
- Builds on: [ADR 0581](0581-behaviour-kinds-are-modules-discovered-at-run-time.md), the `taken_outcome` judge

## Context

Sun Down 572752 states "…and reduces the target's chance to hit by $s1% for $d." through Solar Flare 807175, whose
Effect[0] is aura 54 (SPELL_AURA_MOD_HIT_CHANCE) at −3 on the enemy, applied every 3000 ms by the 572754 ground that
the expiry of 572752 casts (`AscensionSunClericAuras.cpp:179-183`). The claim was blocked: no metric reads an enemy
unit's `m_modMeleeHitChance`. `HandleModHitChance` adds the amount to that field (`SpellAuraEffects.cpp:4930`),
`Unit::MeleeSpellMissChance` subtracts it from the attacker's miss chance and clamps it to 0..60, and
`RollMeleeOutcomeAgainst` rolls the miss first, so the miss share of the enemy's swings rises by the stated points
whatever the player's dodge or parry. A miss is sent as `VICTIMSTATE_INTACT` (`Unit.cpp:2010`). Mentor D-52 approved
design 3 of the Sun Cleric designs-3 report.

## Options

- `taken_outcome` with `one_swing`: it counts `melee_attacks_taken` by victim state, but it sets the subject aura
  with `set_aura` (G-21 point 6 forbids that for the subject), forces removal and re-application under 2000 ms (18
  steps per cycle against the 10000 step cap), holds one case only and has no pooling.
- A readback of `m_modMeleeHitChance` or of the aura amount: a data read, not the behaviour.
- A new kind module that applies the aura from real casts and counts the attackers' misses, pooled over parts.

## Decision

- New kind module `kinds/attacker_miss_share.py` (`behaviour_metric_delta`, label
  `<spell> behaviour_metric_delta attacker_miss`), with `POOLED_JUDGE`, so `parts` pools through the existing
  `add_behaviour` split. No shared file changes; the metric `melee_attacks_taken` already has its event row.
- Control arm first, no cast, the aura read absent on every attacker at each cycle end. Treatment arm: every
  `cycle_ms` a power fixture, `reset_cooldown` of `cast_spell` (a named precondition fixture, stated in the verdict)
  and a real cast at the first attacker; counting starts after `settle_ms` and an `aura` read (caster: the player)
  on every attacker, and the aura is read on every attacker at each cycle end.
- Judge: swings and misses summed per arm over every part; `Bonus((treated − control) × 100, Z_99 × sqrt(spread) ×
  100, expected, n)` and `bonus_status`, as the `taken_outcome` judge. Expected is minus the aura 54 amount from the
  DBC (+3 points for 807175).
- Unmeasured: a part missing, fewer than 100 swings in an arm, any treatment aura read 0 or control aura read 1, or
  a control share within `expected` points of the 0..60% clamp.
- `quote_spell` lets the quote come from an embedded tooltip (`@s:807175:0@` in 572752) and is refused when the
  tooltip does not embed it.

## Consequences

- False passes excluded: a readback of the hit modifier or the aura amount (none is used); a harness-set subject
  aura (no `set_aura` step); the aura on the wrong unit or lapsed while swings are counted (per-cycle reads on every
  attacker); a control contaminated by the ground (never cast in the control arm); a clamp that hides the effect.
- `bonus_status` alerts when equal arms are measured precisely (with 16000 swings per arm, an interval of about
  ±0.63 points around 0 lies under the band's floor of 1 point); equal arms are not judged only while the interval
  is wider than half the band. The design's seeded example "400 vs 400 → not judged" therefore reads alert at two
  parts of 8000 swings; the tests seed both shapes.
- Sizing (estimate until a part is measured): about 8040 swings per arm for a 5% → 8% share at a half-width of 1
  point; 8 attackers at 2000 ms give 4 swings per second, so 2 parts of 2 × 1496 s (4383 steps each).
- Residual failure probability: at most 4.7e-6 per pair for a true share p0 of 8% or less (independent review of
  the kind), within the 0.1% per pair the verification rules require (`.agents/rules/verification.md`).
- Open risk: the first part's aura reads must confirm that Sun Down's ground reaches every attacker; otherwise the
  fallback is a real cast of 807175 on each attacker, named in the verdict.
- Finished classes are untouched: Templar, Necromancer and Witch Hunter generate byte-identical output. The Sun
  Cleric class file entry belongs to the Sun Cleric author.
