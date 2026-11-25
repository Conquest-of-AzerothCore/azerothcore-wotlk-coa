# 1297. Last-application expiry feed can stop on a target aura

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-25
- Rulings: Cultist orchestrator D-39, D-43; G-39 harness note approved

## Context

Cultist Mind Rot `300300` (row 42 claim 1, `"for $560943d"`, `10000 ms`) procs debuff `560943` on the target dummy at a
25% raw `Chance()` roll (`AscensionCultistEvents.cpp:82,165`) on periodic or channeled damage, with no caster-side
companion aura.

`last_application_expiry` `feed` (`kinds/last_application_expiry.py`) previously stopped `cast_until_aura` only on
`player->HasAura(aura)` (`CoAGameplayTest.cpp:7590`), requiring either `caster: true` or a separate caster-side
`stop_aura`. Without a caster-side aura, a target-only rolled debuff could not use `feed`.

## Decision

1. **Opt-in `stop_target` on harness `cast_until_aura`** (`CoAGameplayTest.cpp`, `run.py`, `README.md`):
   - `CastUntilAura` accepts an optional `stop_target` scenario unit id (default `actor`, preserving existing
     `player->HasAura(aura)` behavior when omitted) and checks `GetUnit(stop_target)->HasAura(aura)`.
   - `run.py` validates optional `stop_target` against `actor_ids`.
2. **Opt-in `feed.stop_target` on `last_application_expiry`** (`kinds/last_application_expiry.py`):
   - Accepts optional `"stop_target": "dummy" | "caster"` inside `feed`.
   - When omitted, emits no `stop_target` field in `cast_until_aura`, reads stop `aura` on `caster`, cancels on `caster`,
     and writes the exact prior contract text (byte-identical for all existing entries).
   - When set to `"dummy"`, emits `"stop_target": "dummy"` on `cast_until_aura`, reads the stop `aura` on `"dummy"`,
     clears `stop_aura` on `"dummy"` via `set_aura` before the treatment arm, and allows `stop_aura` to default to
     `aura` when `caster: false` (while still refusing a mismatch without `stop_aura` when `caster: true`).

## Consequences

- Strictly opt-in: finished classes regenerate byte-identical.
- Closes Cultist Mind Rot `300300` row 42 claim 1 (`560943` duration `10000 ms` on the dummy).
- Does not by itself close Teachings of Mythrax `561035` row 196: `561035` (`ProcChance = 100`) modifies the duration
  of rolled Presence procs (`803035`/`803037`, `ProcChance = 20`) from base to `+25%` rather than gating aura
  application (`0` vs `1`), so `last_application_expiry` still refuses `gate_spell = 561035` (`ProcChance` not in
  `(0, 100)`) and its control arm alerts if the base-duration Presence applies without `561035`.
