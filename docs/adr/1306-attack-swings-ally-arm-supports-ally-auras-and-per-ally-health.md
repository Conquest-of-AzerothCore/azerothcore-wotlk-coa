# 1306. Attack swings with ally_arm support ally_auras and per-ally ally_health

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-25
- Builds on: ADR 1186 (`ally_arm`), ADR 1244 (`ally_power`), ADR 1281 (raid `ally_arm`)

## Context

Cultist Shadow Pennant (706926 rank 1 50%, 525307 rank 2 100%) states "You now heal the lowest health ally affected by
Black Blood for $s1% of your auto attack damage." (`AscensionCultistEvents.cpp:109-110,266-276`,
`AscensionCultist.cpp:238-255`). The existing `auto_heal` entries prove the 50%/100% auto-attack scaling on the caster
holding Black Blood (`804153`), while claim `[1]` ("heal the lowest health ally affected by Black Blood") remained a
tool gap on rows 166 and 327 for three reasons:
1. `ally_arm.ally_health` accepted only one uniform `[value, maximum]` pair for every ally, so two Black Blood allies
   and a lower-health non-Black-Blood ally could not be given distinct health percentages.
2. `metric_delta` `phase_auras` refuses ally unit ids (`test_behaviours.py` tests that refusal), so Black Blood
   `804153` could not be placed on specific allies with `caster` as aura caster.
3. The `elif spec.attack_swings:` branch of `behaviours.metric_delta_scenario` never emitted `ally_arm` phase steps, so
   per-ally health and ally auras could not run ahead of melee auto-attack swings.

## Options

- Widen `behaviours.PHASE_AURA_UNITS` to include allies and call `option_phase_steps` for every option in
  `attack_swings`. Refused: breaks existing refusal test `test_phase_aura_refuses_an_unknown_unit` and would alter
  existing `attack_swings` entries that carry unrelated options such as `phase_aura_amounts` (Cultist `92131`).
- Add opt-in per-ally `ally_health` dict form and `ally_auras` inside `ally_arm`, and emit only those opt-in
  `ally_arm.attack_phase_steps` ahead of `attack_swings` phases (plus in normal `ally_arm.phase_steps`). Chosen.

## Decision

- `ally_arm.ally_health` accepts either the existing `[value, maximum]` list (applied to every ally, unchanged) or a
  non-empty object mapping ally ids in `ally.ally_ids` to `[value, maximum]` (`1 <= value <= maximum`, integers,
  `allies > 0`).
- `ally_arm.ally_auras` is an optional non-empty list of `[spell, stacks, on, by]` (`allies > 0`, `spell > 0`,
  `stacks >= 0`, `on` and `by` in the scenario's units, and at least one of `on` or `by` in `ally.ally_ids`). Emits
  harness `set_aura` steps with `target=on` (when `on != 'caster'`) and `caster=by` (when `by != on`).
- `ally_arm.attack_phase_steps` returns the per-ally `ally_health` and `ally_auras` steps only;
  `behaviours.metric_delta_scenario` prepends them before `attack_swings` in both phases (followed by `spec.wait_ms`
  settle) only when non-empty. Every existing `attack_swings` entry without those keys generates byte-identical steps
  and contract.
- `ally_arm.phase_steps` emits per-ally `ally_health` and `ally_auras` in cast-triggered `metric_delta` phases as well.

## Consequences

- Closes Cultist Shadow Pennant 525307 row 166[1] and 706926 row 327[1] with forward (`ally` 30% vs `ally2` 70%) and
  reverse (`ally` 70% vs `ally2` 30%) arms alongside a 10% non-Black-Blood `ally3` and full-health caster (all 0 heals),
  verifying `804153` precondition auras and unlearned before-phase controls.
- Finished classes and all existing `attack_swings` / `ally_arm` entries regenerate byte-identical.
