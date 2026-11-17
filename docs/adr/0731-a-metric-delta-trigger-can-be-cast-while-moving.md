# 0731. A metric delta trigger can be cast while moving

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Witch Hunter claim 0.0 ("You may now cast Darkslayer while moving.", Boltslinger 92091) and 44.0 ("Usable while
moving.", Sixfold Shot) state that a cast is accepted while the caster moves. `Spell::prepare` refuses a player cast
with a cast time and the movement interrupt flag while the caster moves (`SPELL_FAILED_MOVING`), unless an aura 313
selects the spell (`Unit::CanCastSpellWhileMoving`). No conformance kind or option moved the caster, so the c12-bolt
author stopped on 0.0. Gap design A1 (c13 gap designs), mentor ruling D-201.

## Options

- A `metric_delta` option that sets the harness movement flag before each trigger cast and clears it after the judged
  reading; the existing `cast_failure` read and the gate contrast judge it.
- A new kind: it would repeat the phases and the contrast of `metric_delta`.
- `phase_auras` with a movement aura: no aura sets the client movement flag that `Unit::isMoving` reads.

## Decision

The option. It adds steps only; the plain `metric_delta` verdict is unchanged. The flag is held until the reading after
the cast, so a reading later than the cast time also tells that the cast was not interrupted (40).

## Consequences

- Absent by default: Templar 19 and Necromancer 23 regenerate byte-identical (`snapshots.py check`).
- Seeded tests: the movement starts right before each trigger cast and stops right after the reading; an uncast
  phase does not move; no movement without the option; a flag outside the four directions is refused. It adds no
  check, so there is no mutant.
- Witch Hunter: `92091 behaviour_metric_delta moving_cast` (51 without Boltslinger, 0 with it, 3000 ms after the
  2500 ms Darkslayer cast).
- 44.0 has no movement refusal to contrast: Sixfold Shot 807364 carries InterruptFlags 0, so a moving cast is
  accepted with or without 500567. Its use needs another control arm (not built).
