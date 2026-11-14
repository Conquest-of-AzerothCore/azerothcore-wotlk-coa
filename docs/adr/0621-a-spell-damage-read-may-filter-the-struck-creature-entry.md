# 0621. A spell damage read may filter the struck creature entry

- Status: accepted
- Date: 2026-11-13
- Builds on: ADR 0361, ADR 0606

## Context

Spellbound Champion 807811 "deflects spells cast on you, redirecting them to itself" (claim 358.2, "redirecting them
to itself"). The immunity entry shows the spell no longer lands on the caster; the Champion's health loss (ADR 0606
pilot) shows an amount whose mitigation is not derived from the tooltip. The claim states where the hit goes, an
event. `spell_damage_count` filters the struck unit by a scenario `target` only, and the Champion is a summon, not a
scenario unit.

## Options

1. Resolve a live owned creature as the target (fails in a phase without the creature).
2. Filter the recorded damage events by the entry of their target guid (`target_entry`), a pure read of events the
   harness already records (G-39).

## Decision

Option 2. `spell_damage_count` / `spell_damage_total` take `target_entry` in place of `target`: an event counts when its
target guid is a creature of that entry. It reads 0 when no such creature was struck, so the control phase without the
Champion is observable. `run.py` validates the field (spell damage metrics only, a positive entry, not with `target`).

## Consequences

- 807811 `redirect` (the striker's Light of the Naaru on a Champion 500483: 0 without, 1 with) and `redirect_control`
  (the same strikes on the caster: 1, then 1, no new hit) on claim 358.2.
- No scenario sets the field before this ADR, so every existing scenario reads the same.
