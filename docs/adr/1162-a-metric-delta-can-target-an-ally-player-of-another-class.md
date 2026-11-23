# 1162. A metric delta can target an ally player of another class

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21
- Builds on: ADR 0582, ADR 1030 (`ratio_to_metric`)

## Context

Rage Brew 503750 throws a brew at an ally, "regenerating 50% of their maximum Rage, Energy, and Focus" (three
ENERGIZE_PCT effects). The Witch Doctor owns none of the three, and an energize on a unit whose maximum of that power
is 0 does nothing (Spell::EffectEnergizePct), so no read on the caster shows it. `metric_delta` places the caster,
the dummy and an enemy player of a stated class; the harness already creates players of any class (`class` of a
player fixture). The claim kept a no-behaviour-route ruling waiting on tool note T-ally2 since cycle 8.

## Decision

The option `ally_player` (`{"class", "power"}`) adds a grouped ally player of that class with regeneration off, and
sets its power of that index to 0 at the start of each phase. The entry casts its trigger at `ally` and reads `ally`.

## Consequences

Opt-in only; classes 19 (with and without `--stack`) and 23 generate byte-identical scenarios. Class 13 gains 503750
`brew_rage` (Warrior), `brew_energy` (Rogue) and `brew_focus` (Ranger, class 21, whose power type is Focus), each
read as the share of the ally's maximum (`ratio_to_metric` on `max_power`): 0 before the cast, 0.5 after.
