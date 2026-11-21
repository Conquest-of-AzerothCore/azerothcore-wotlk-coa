# 0717. A metric delta can set the dummy's health once per phase

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-15

## Context

Stake 681350 (Witch Hunter) "increases the duration by 3 sec" of Flames of Sin. The extension needs a setup Stake and
a trigger Stake, and Stake is only usable at or below 35% health. `target_health_pct` sets the dummy's health right
before the trigger cast, after the setup casts, so the setup Stake is refused; a fixture before each cast would raise
health after the first hit, which `set_health_pct` refuses (c11-inq stop on claim 180.1). Mentor decision D-160 (c12
tool batch item 7).

## Options

- A `metric_delta` option module that sets the dummy's health once at the start of each phase, before its setup
  casts, lower in the after phase.
- A caster aura with SPELL_AURA_ABILITY_IGNORE_AURASTATE on the Stake mask: none was identified in the DBC.

## Decision

`metric_delta_options/phase_target_health_pct.py`: `[before pct, after pct]`, the after one lower, a `phase_steps`
hook (`set_health_pct` on the dummy), refused with `target_health_pct` or a target other than the dummy.

## Consequences

- Templar 19 and Necromancer 23 regenerate byte-identical (no entry states the option).
- Witch Hunter: `681350 behaviour_metric_delta flames_extension_present` / `flames_extension_absent`.
