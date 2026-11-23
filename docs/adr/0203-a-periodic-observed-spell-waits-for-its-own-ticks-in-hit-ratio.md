# 0203. A periodic observed spell waits for its own ticks in hit_ratio

- Status: accepted
- Date: 2026-11-12
- Extends: ADR 0125 (hit ratio), ADR 0183 (a cast spell read through another spell's hits)

## Context

Focused 300524, claim 31: "Increases the damage of Blade of Faith and Righteous Tempest by $s1%." Its Effect[1] is a
SPELLMOD_DOT modifier on Blade of Faith, whose level 60 rank 803880 deals its damage only as periodic ticks (aura 3,
every 3000 ms). A `hit_ratio` trial reads its hits right after the cast, so a periodic spell read itself saw no tick.
`cast_wait_ms`, the wait after each cast, was accepted only with a `cast_spell` other than the observed spell.

## Considered options

1. Read the ticks through a no-effect `cast_spell` with a wait. It would cast an unrelated spell in every trial.
2. Accept `cast_wait_ms` when the observed spell is cast itself, not beside swings. Chosen: the trial steps already
   cast `cast_spell or observe_spell` and wait `cast_wait_ms` after it.

## Decision

`hit_ratio` accepts `cast_wait_ms` without a `cast_spell`; it stays refused beside swings. The contract states the
wait. Entries without that combination regenerate byte-identical (1692 of 1692, one new scenario).

## Consequences

- Focused's Blade of Faith arm: 30 casts of 803880 per arm, 3500 ms each, reading 191 against 239 per tick (+25.13%).
- Tests: `test_behaviours.SelfObservedPeriodicHitRatioTests`.
