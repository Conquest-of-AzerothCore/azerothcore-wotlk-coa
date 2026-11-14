# 0490. A power read promises every class resource

- Status: accepted
- Date: 2026-11-13

## Context

Freeze Dry 704680: "Your Glacial Impact now generates $/10;804111s1 Runic Power." The gain is added directly by
the native power-gain rules, not logged as an energize event, so the entry reads the caster's Runic Power after a
real Glacial Impact cast, with and without the learned talent (0 and 200). `STATE_PROMISES['power']` named only
"mana", "energy", "rage", "focus" and "cost", so the coverage tool counted this learned state contrast as data
although the clause promises exactly that state. The maximum-power promise already used the class power names
(`POWER_NAMES`, which include "runic power").

## Decision

- `STATE_PROMISES['power']` uses the same class power names (`POWER_WORDS`) plus "cost": a learned contrast of a
  power read proves a clause that names the resource or a cost.
- No metric changes class: `power` stays a STATE read, and a read-back metric stays data.

## Consequences

- The Freeze Dry entry counts as behaviour; clauses that name Spell Power or another non-resource word stay data.
- Tests: `RunicPowerPromiseTest` (test_coverage.py): the Runic Power clause is behaviour, a damage proxy clause is
  data, and the mana, Energy and Runic Power cost clauses stay behaviour.
