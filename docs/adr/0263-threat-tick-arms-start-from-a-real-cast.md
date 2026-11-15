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

## Options

- Self-cast only: the caster casts 572808 on itself. A real application, but the aura holder is also the blessing's
  caster, so a tick that scaled the caster's threat instead of the holder's would pass (review I1).
- Self-cast plus an ally arm: the caster also casts 572808 on a grouped ally that has built threat, the ally's threat
  is judged, and the caster's threat over the same tick is the control. Chosen, as the audit suggested.

## Decision

A `threat_tick_ratio` entry may set `cast_target` (`"caster"` or `"ally"`; `aura_stacks` must stay 1) and
`threat_unit` (whose threat toward the dummy is read: the caster or the cast target, by default the cast target). The
scenario then learns `aura_spell`, builds threat by melee as before (with `"ally"`, the ally is grouped and attacks
too), reads `aura_duration_ms` of `aura_spell` on the target, casts it, reads it again, and only then reads the threat
baseline: Spell::HandleThreatSpells forwards a positive cast's SpellLevel threat to the dummy, and ScaleThreat
multiplies the total threat, so a baseline read after the cast keeps the ratio unbiased. The verdict is `ok` only when
the ratio is within tolerance and the aura reads 0 before the cast and not 0 after it (-1 being a permanent aura); a
missing aura read leaves it unjudged. The three 572808 tick-count arms set `cast_target: "caster"`; two new arms cast
on the ally: `ally` (the ally's threat, 0.98 after one tick) and `ally_caster_control` (the caster's threat, 1).
Entries without `cast_target` regenerate byte-identical.

## Consequences

- The five 572808 arms run as one counted pair on one build; claim 139 needs the ally arm and its control, claim 140
  the tick-count arms.
- The tick windows are timed from the cast; the reads between the cast and the wait took 0 ms of game time on the
  simulated clock (result.json step `elapsed_ms`).
- The baseline after the cast cannot see a tick at application. 572808 has no SPELL_ATTR5_START_PERIODIC_AT_APPLY
  (AttributesEx5 32), and every observed baseline is an integer, so no such tick is expected; the design does not show
  it.
- The phase-free period bound from the 600, 1200 and 3200 ms arms, with the first tick anywhere in (600, 1200] ms, is
  about (667, 1300) ms; (800, 1067] ms holds only if the first tick lands one period after the cast.
