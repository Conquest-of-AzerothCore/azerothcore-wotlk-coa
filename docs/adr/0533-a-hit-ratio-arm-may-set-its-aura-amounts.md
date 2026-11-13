# 0533. A hit_ratio arm may set its aura amounts

- Status: accepted
- Date: 2026-11-13
- Split before publication (mentor ruling 2, 2026-11-13): this ADR keeps the tool rule; the Glacial Impact fix it was
  written for is [Necromancer ADR
  0026](conformance/necromancer/0026-glacial-impact-damage-grows-with-the-caster-frost-spell-crit-chance.md).

## Context

A damage factor that follows a character-sheet value (Glacial Impact's Frost spell crit factor, Necromancer ADR 0026)
needs arms that hold that sheet value exactly. A fixture aura applied at its DBC amount gives one value only; the
harness `set_aura` step already sets an aura effect's amount.

## Decision

- Conformance tools: a `hit_ratio` arm may set `aura_amounts` ([spell, effect, amount] of one of its own auras),
  applied with the harness `set_aura` amount before every trial, so a fixture aura holds an exact sheet value.

## Consequences

- A fixture aura can stand for an exact sheet value; the Glacial Impact regression holds 984954 Effect[1] at +2 and
  +22 (Necromancer ADR 0026).
<!-- Draft note: the original ADR 0533 states no tool-only consequence (no Templar byte-identity line); add one only if
     measured. -->

