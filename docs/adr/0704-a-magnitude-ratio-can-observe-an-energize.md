# 0704. A magnitude ratio can observe an energize

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-15

## Context

Resilient to Darkness 681092 (Witch Hunter) heals and restores mana equal to 3% of the direct magic damage taken
(AscensionWitchHunterEvents.cpp:366-371). The magnitude ratio observed damage and heals only, so the mana half had no
label. Mentor decision D-158 (design D-10).

## Decision

`MAGNITUDE_OBSERVE_METRICS` takes `spell_energize_total`, counted by `spell_energize_count`. The total is the logged
nominal gain before the resource cap (harness README), so a full pool does not shorten it.

## Consequences

- Templar 19 and Necromancer 23 regenerate byte-identical (no entry observes an energize).
- Witch Hunter: `681092 trigger_magnitude_ratio mana`.
