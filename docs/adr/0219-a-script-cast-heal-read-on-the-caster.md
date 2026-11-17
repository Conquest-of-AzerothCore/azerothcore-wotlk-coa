# 0219. A script-cast heal read on the caster

- Status: accepted
- Date: 2026-11-12
- Extends: ADR 0160 (script-cast hits), ADR 0206 (control casts)

## Context

Libram of Grace 801463, claim 324: "causing your damaging abilities to restore ${$804150m1+$AP*.1+$SP*.15} health to
you and nearby allies". Its script casts Grace 804150 on the Templar (AscensionTemplarEvents.cpp:200-201). A
`script_hit` read its hit on the dummy or the striker only.

## Decision

`receiver: "caster"` reads the script-cast spell's heals on the caster (`spell_heal_total` and `spell_heal_count` with
target the caster). It is refused for a damage hit. Other receivers regenerate byte-identical.

## Consequences

- Libram of Grace on build 861e0e1e6bee: Grace heals the Templar (held at 50%) after each Argent Blade with the Libram
  cast, and never without it (control); the mean lies in the engine model (ADR 0147 per-level truncation) with the
  Libram's own +20% healing received (ADR 0220).
- Seeded tests: the heal reads target the caster; a damage hit on the caster is refused.
