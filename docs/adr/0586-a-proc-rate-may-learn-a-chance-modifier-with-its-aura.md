# 0586. A proc rate may learn a chance modifier with its aura

- Status: accepted
- Date: 2026-11-13
- Builds on: ADR 0346

## Context

Necromancer claim 83.0, Frigid Winds 504357 "Increases the chance to trigger Refreshing Chill by $s1%", is a flat
`SPELLMOD_CHANCE_OF_SUCCESS` modifier (Effect[0] aura 107, MiscValue 18, BasePoints 4 + 1 = 5) on Refreshing Chill
300940, whose roll is `Chance(player, 300940)`: ProcChance 20 plus the caster's modifier
(`AscensionNecromancer.cpp:225-232`). A `proc_rate` entry reads its expected chance only from its aura's tooltip
(`$h` = 20) and learns no second spell; `proc_rate_delta` (`baseline_co_learn`) proves a positive difference only.

## Options

1. A `proc_rate_delta` with a stated difference (a new rule for the delta judge).
2. A `chance_modifiers` field on `proc_rate` entries: learn the modifier with the aura and add its stated points.

## Decision

Option 2. `procs.chance_modifiers(entry)` reads `[spell, token]` pairs; `aura_steps` learns each spell after the aura;
`proc_chance` adds each token's percent value from the modifier's tooltip after checking that the token's effect is a
flat chance-of-success modifier in the server DBC set. The expectation model carries `chance_modifiers`, and
`compare.stated_chance` adds the modifier tokens it reads from the tooltips again. `same_roll` (same aura, same
modifiers) replaces the plain aura match in `shares_aura` and `shares_proc_spell`, and `entry_proc_label` and the
scenario keys append ` with <spell>`, so an entry without modifiers keeps its label and scenarios
(`generate --class 19`, `--stack` and the 300940 and 92122 scenarios are byte-identical).

## Consequences

- 83.0 is judged at 25% with `band: true`: 12443 trials, 18665 attempts, 77 parts (the 2.0 sizing).
- A modifier with another shape (a percent modifier, a script amount) is refused; it needs its own decision.
