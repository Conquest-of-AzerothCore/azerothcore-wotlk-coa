# 1121. An aura window treatment can be a cast state, judged in the band of the stated change

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21
- Builds on: ADR 0551 (`aura_window`)

## Context

Graven Effigy 506635 lengthens crowd control on enemies in its field by 25% (504767, aura 232 on mechanics 7, 11 and
2). The effect exists only while a summoned effigy stands, so the treatment is a real cast, not a learned talent, and
`aura_window` only learns the entry's spell between its phases (tool note T-b13-7). Its judge also bands each stamped
duration by 5% of itself: for a 12500 ms snare that is 625 ms, about 6 points of the stated +25%, wider than the G-19
band of the stated value (2 points, 200 ms of the 10000 ms base).

## Decision

`aura_window` takes optional `setup_casts` (`{spell, target, wait_ms}`), made for real at the start of the treatment
phase before its global cooldown wait and the trigger (base mana and a cooldown reset first; the spells are learned at
the start), and an optional `treatment_band_ms` that replaces the treatment band and must be narrower than 5% of the
treatment duration.

## Consequences

- Opt-in: without the fields the steps, the contract and the model are unchanged; classes 19 (with and without
  `--stack`) and 23 generate byte-identical scenarios.
- Witch Doctor 506635 `graven_cc`: Lethargy Jinx 802065 lasts 10000 ms without an effigy and 12500 +- 200 ms on a
  dummy in a real Graven Effigy's field.
