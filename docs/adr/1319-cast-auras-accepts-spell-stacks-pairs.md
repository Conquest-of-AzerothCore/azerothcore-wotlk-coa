# 1319. `cast_auras` accepts `[spell, stacks]` pairs for stack-counted cast preconditions

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-25
- Rulings: Cultist class-end pair 2 diagnosis (`572846` Entropic Slam and `806830` Hammer of Twilight `hit_mean`)

## Context

In Cultist (class 25), `572846` (*Entropic Slam*) and `806830` (*Hammer of Twilight*) both require a stack-counted
backing resource (`500706` *Insanity* `>= 60` / `>= 40`) in `AscensionCultistAbilities.cpp:82-84` AND a derived
threshold marker aura in `Spell.dbc` `CasterAuraSpell` (`680603` / `680602`), which `AscensionCultist.cpp:270-273`
(`Refresh()`) strips whenever `Count(Insanity)` is below the threshold.

Setting `803061` (*Total Madness*) via plain 1-stack `cast_auras` bypasses the `OnSpellCheckCast` Insanity check,
but applying `803061` triggers `Refresh()` with `Insanity == 0`, stripping `680603` / `680602` that
`required_aura_steps` had just applied and failing every cast with `SPELL_FAILED_CASTER_AURASTATE (22)`.

`values.cast_aura_steps` previously accepted only plain spell IDs and hardcoded `stacks: 1`, so `cultist.json`
could not supply `[500706, 70]` / `[500706, 50]` before each cast.

## Options

- Reorder `required_aura_steps` after `cast_aura_steps` in `hits.py`: rejected, because it would change every
  existing class's hit scenarios with `cast_auras` and still leaves `Refresh()` able to strip `680603`/`680602` on
  its 500 ms timer while `Insanity == 0`.
- Extend `values.cast_aura_steps` to accept `[spell, stacks]` pairs alongside plain positive integer spell IDs
  (opt-in by syntax, mirroring `gate_auras` in ADR 1314). Chosen.

## Decision

Extend `values.cast_aura_steps` ([doc](../../apps/coa-gameplay-test/conformance/docs/value-scenarios.md)):

- Add `cast_aura_entry(aura)` accepting either a positive `int` (returns `(aura, 1)`) or a 2-element `list`
  `[positive_int_spell, positive_int_stacks]` (rejecting booleans, non-positive values, or wrong arity).
- Emit `{'action': 'set_aura', 'actor': CASTER, 'spell': spell, 'stacks': stacks}` in `cast_aura_steps`.
- Plain integer entries emit the exact same steps as before; no generated scenario of any existing class changes.

## Consequences

- Opt-in by `[spell, stacks]` syntax; zero C++ changes and zero diff on finished classes 13, 14, 15, 19, 23, and 27.
- Cultist `cast_auras` supplies `[[500706, 70], 680603]` for `572846` and `[[500706, 50], 680602]` for `806830`
  (neither `500706`, `680602`, `680603`, nor `573315` has any `EffectSpellClassMask` overlap with `572846` or
  `806830`), keeping both the Insanity backing stacks and threshold marker aura valid before every cast.
- Unit tests in `test_values.py` verify plain int compatibility, `[spell, stacks]` step emission, and input
  validation refusals.
