# 0972. A cast leech ratio can cast a real buff before the measured cast

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Witch Hunter claim 334.0 (Vampiric Tonic 802276, "allowing Physical damage dealt to heal you equal to $s1% of the
damage dealt", $s1 = 40) is judged as data only. The leech exists only while the Tonic is active, and the Tonic is a
cast of its own. `cast_leech_ratio` can set an aura through `auras`, but a `set_aura` of the claim's own spell would
make the claim's subject a fixture.

## Options

- `auras` with 802276: the Tonic is applied by a fixture, not by its cast.
- A new kind: a second judge for the same heal/damage ratio.
- An opt-in `prelude_casts` on `cast_leech_ratio`.

## Decision

`prelude_casts`: spells learned, cooldown-reset and really cast on the caster after the control cast and before the
treatment cast. It reuses the control arm of `auras` (the control cast must heal nothing) and the existing judge. The
expectation is the tooltip's plain sense from the DBC ($s1% of the damage dealt); the server code is not its source.

`dummy_distance` (the same optional field other kinds carry, through `dummy_placement`) places the dummy for a
cast spell with a minimum range: Heartseeking Bolt 807284 fails with SPELL_FAILED_TOO_CLOSE (result 128) at the
kind's default placement. Absent by default.

## Consequences

- Absent by default: Templar and Necromancer entries regenerate unchanged; the Witch Hunter Dusk Blade entry too.
- Seeded tests: the distance places the dummy and an out-of-limit one is refused; the buff is cast once, between the two strikes and with no `set_aura`; no control arm or buff cast
  without the option; a heal during the control alerts; 40% of the treatment damage is ok and half of it alerts; the
  option with `damage_also_spell` is refused.
- The band stays the kind's (delta judged on the healing scale).
