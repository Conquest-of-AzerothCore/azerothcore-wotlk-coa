# 0263. Threat-tick arms start from a real cast

- Status: accepted
- Date: 2026-11-12
- Extends: the `threat_tick_ratio` behaviour kind and its tick-count arms

## Context

The rule 4 amendment of 2026-11-12, point 2b, counts a unit-property read as behaviour only when the change comes from
a real application in the run. The three Righteous Custodian 572808 threat-tick arms (0, 1 and 3 ticks, claims 139
and 140) started from a harness `set_aura` of 572808, so the audit demoted both claims to data
(`lean/rule4-amendment-audit.md`, "2b for 139/140"). 572808 is an instant, costless raid-target blessing that the
caster can cast on itself (the `cast_applies_aura` entry already does).

## Decision

A `threat_tick_ratio` entry may set `cast_target` (only `"caster"`, since the dummy's threat is read against the
caster; `aura_stacks` must stay 1). The scenario then learns `aura_spell`, builds threat by melee as before, reads
`aura_duration_ms` of `aura_spell` on the target, casts it, reads it again, and only then reads the threat baseline:
Spell::HandleThreatSpells forwards a positive cast's SpellLevel threat to the dummy, so a baseline read before the
cast would mix that threat into the ratio. The verdict is `ok` only when the ratio is within tolerance and the aura
reads 0 before the cast and above 0 after it; a missing aura read leaves it unjudged. The three 572808 arms set
`cast_target: "caster"`. Entries without `cast_target` regenerate byte-identical.

## Consequences

- The three 572808 arms are rerun as one counted pair on one build; claims 139 and 140 return to behaviour only if
  that pair passes.
- The tick windows are timed from the cast instead of the `set_aura`; the reads between them take no game time on
  the simulated clock.
