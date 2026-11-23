# 1049. A fixture creature can carry a melee hit bonus

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21
- Builds on: ADR 0053 of round 10 (`set_combat_avoidance` for melee vehicles)

## Context

A striker's `spell_hit_bonus` sets `m_modSpellHitChance`, which only `MagicSpellHitResult` reads. A melee vehicle
(DmgClass 2, Hamstring 1715) goes through `MeleeSpellHitResult`, whose miss chance (`MeleeSpellMissChance`) starts
near 5% against a player and subtracts only the attacker's `m_modMeleeHitChance`. The `duration_ratio_expiry` arm has
one act per arm by design (ADR 0126), so a melee vehicle fails that scenario about 1 run in 10 (cycle 10 author F,
tool note T-c10-F1). The kind page said `spell_hit_bonus` "only removes the miss roll", which is false. Witch Doctor
803700 moved to the always-hit magic vehicle Icy Clutch 50436; Templar Courage 707754 and 712466 still use Hamstring
(another class's file, reported, not edited).

## Options

1. Refuse a melee or ranged vehicle without `SPELL_ATTR3_ALWAYS_HIT` or `SPELL_ATTR7_NO_ATTACK_MISS` (option (a)).
2. A creature fixture field that sets `m_modMeleeHitChance` (option (b)).

## Decision

Option 2. The creature fixture accepts `melee_hit_bonus` (0..100) next to `spell_hit_bonus`
(`CoAGameplayTest.cpp` `CreateTargets`, `run.py` creature schema). A `duration_ratio` entry may set
`striker_melee_hit_bonus: true`; then the striker of both its readback (`mechanic_duration_scenario`) and its expiry
pair (`expiry.duration_ratio_expiry`) carries `melee_hit_bonus` 100. The kind page states which roll each bonus
reaches.

## Consequences

- The field and the entry option are opt-in: no striker changes without them, so generated scenarios of classes 13,
  19 (with and without `--stack`) and 23 are byte-identical. The Templar owner can set the option on the Hamstring
  entries.
- Catalog scenario `witch-doctor-harness-striker-melee-hit-bonus.json`: 60 triggered Hamstrings of a striker with the
  bonus all land on a caster with dodge and parry at 0 (about 5% without the bonus).
