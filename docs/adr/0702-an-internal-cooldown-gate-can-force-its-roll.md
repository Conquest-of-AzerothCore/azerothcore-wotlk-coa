# 0702. An internal cooldown gate can force its roll

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-15

## Context

Expert Killer 804404 (Witch Hunter): "Can only occur once every 5 sec." on an 8% proc. The internal cooldown gate
casts three times and needs the first cast to fire; an 8% roll fires it rarely. Mentor decision D-158 (design D-7).

## Options

- An optional `forced_roll` (talent id) reusing the SPELLMOD_CHANCE_OF_SUCCESS +1000% mutant fixture of the
  `metric_delta` option `forced_roll` (ADR 0588).
- Size trials until a first fire is likely: a coin flip, not a test.

## Decision

The first option. The fixture is added after the settle and removed at the end, read as `spell_mod_mutants`. With
the roll forced, the judge also requires the first cast to fire exactly once and the mutant to read released;
otherwise `alert`. An optional `dummy_distance` places the dummy for a ranged trigger (the first pair at the melee
default read SPELL_FAILED_TOO_CLOSE).

## Consequences

- Templar 19 and Necromancer 23 regenerate byte-identical.
- Seeded mutants: a missed first fire and a kept mutant alert.
- Witch Hunter: `804404 behaviour_internal_cooldown_gate` (Tormentor 800162 as the trigger, dummy at 17.5 yd): pair
  20261115-203840 / -203917 ok (0 between the first two casts, +1 after the reopen).
