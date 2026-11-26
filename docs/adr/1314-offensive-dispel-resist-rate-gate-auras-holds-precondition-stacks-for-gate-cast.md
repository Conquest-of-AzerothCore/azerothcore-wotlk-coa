# 1314. Offensive dispel resist rate `gate_auras` holds backing precondition stacks for `gate_cast`

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-25
- Rulings: Cultist class-end diagnosis D1 (`300287` Forbidden Resilience)

## Context

In Cultist (class 25), Forbidden Resilience `300287` (`kind: "offensive_dispel_resist_rate"`, ADR 1294) casts
`gate_cast: 520326` (Herald of the Depths) before the `control` and `treatment` arms. `520326` requires
`CasterAuraSpell = 680604` (the `>= 80` Insanity marker aura). `arm_steps` emits `required_aura_steps(520326)`
(`set_aura 680604 1`) immediately before `cast 520326`, without setting the backing Insanity counter `500706`.

Under load (4 concurrent simulated servers in the Cultist class-end pair), `AscensionCultist.cpp:270-273` (`Refresh()`)
occasionally runs between `set_aura 680604 1` and `cast 520326`; seeing `500706 == 0 < 80`, it strips `680604`, causing
`cast 520326` to fail with `SPELL_FAILED_CASTER_AURASTATE (22)` and voiding the arm as `unmeasured`
(`control gate aura 520326 read 0 (before), expected present`).

`OffensiveDispelResistSpec` had no field to hold a backing resource aura before `gate_cast`, and the class-level
`cast_auras` list only sets 1 stack (insufficient for stack-counted resources like `500706` at 95 stacks) and is not
read by `offensive_dispel_resist_rate`.

## Options

- Read `cast_auras` in `offensive_dispel_resist_rate`: rejected because `cast_auras` only supports 1 stack per aura and
  cannot set a backing resource stack count with margin above the threshold.
- Emit `gate_auras` only in `control` and `treatment`: rejected because removing `gate_cast` before `gate_off` can drain
  the backing resource (for Cultist, removing Herald `520326` executes `Resource(player, Insanity, -100, true)` at
  `AscensionCultistAuras.cpp:181-182`), which would leave `treatment` and `gate_off` differing by both `gate_cast` and
  the backing resource/markers (`500706`, `680601`–`680604`, `573315`) and confound the gate proof.
- Add an optional `gate_auras: [[spell, stacks], ...]` field to `OffensiveDispelResistSpec` that emits `set_aura` on
  `caster` symmetrically across all arms: immediately before `required_aura_steps` in `control` and `treatment`, and
  immediately after removing `gate_cast` (`stacks: 0`, before `gate_settle_ms`) in `gate_off`. Chosen.

## Decision

Extend `kinds/offensive_dispel_resist_rate.py` ([doc](../../apps/coa-gameplay-test/conformance/docs/kinds/offensive_dispel_resist_rate.md)):

- Add optional `gate_auras: tuple[tuple[int, int], ...] = ()` to `OffensiveDispelResistSpec`, parsed from a list of
  `[positive_spell_id, non_negative_stacks]` integer pairs (rejecting booleans, wrong arity, non-positive spell ids,
  negative stacks, or specifying `gate_auras` without `gate_cast`).
- In `arm_steps`, emit `{'action': 'set_aura', 'actor': CASTER, 'spell': aura, 'stacks': stacks}` for each pair in
  `spec.gate_auras` immediately before `required_aura_steps(facts_of(records, spec.gate_cast))` in `control` and
  `treatment`, and immediately after `{'action': 'set_aura', 'actor': CASTER, 'spell': spec.gate_cast, 'stacks': 0}`
  (before `gate_settle_ms`) in `gate_off`, so every arm carries the same backing stacks and `treatment` vs `gate_off`
  differs strictly by `gate_cast`.
- When `gate_auras` is omitted, generated scenarios and contracts are byte-identical to ADR 1294.

## Consequences

- Opt-in extension to `offensive_dispel_resist_rate`; zero C++ changes and zero diff on any existing class or entry
  that omits `gate_auras`.
- Cultist `300287` `dispel_resist` sets `"gate_auras": [[500706, 95]]` (`+15` stacks above the `80` Insanity threshold,
  staying below 100 and well above 80 across out-of-combat `-2 / 10 s` Sanity `500727` ticks in
  `AscensionCultistAuras.cpp:214-215`), eliminating the `Refresh()` race in `control`/`treatment` and restoring
  `500706 = 95` after Herald removal in `gate_off` so `treatment` and `gate_off` differ strictly by Herald `520326`.
- Unit tests in `kinds/test_offensive_dispel_resist_rate.py` verify symmetric step placement in all three arms,
  byte-identical default output, and input validation refusals.
