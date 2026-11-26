# 1248. A listed foreign periodic total is judged per tick

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-23
- Decided by: mentor ruling D-23 (Felsworn conformance)
- Builds on: ADR 0676; supersedes its clause "a `mixed` foreign token keeps its `effect_value` read"

## Context

Malice of Gul'dan 800214 and Fel Apprentice 92088 expand Felstrike 802678 with `@s:802678:0@`, whose text holds
`${($d*1000/$T1)*($m1+0+$SP*.05)}`: 6 ticks x (9 + 0.05 SP), 54 at SP 0. The generated labels
`800214 effect_value 802678e0 #1` and `92088 effect_value 802678e0 #0` compared that total with one
`spell_effect_value` read of Felstrike effect 0, a single tick (34 at level 60): one tick against the total.

`periodic_reason` (ADR 0676) classes a foreign token by its own spell, but `period_reading` re-read the token text
alone in the rank's context. Outside its expansion, `$d`, `$T1` and `$m1` named 800214, the scaled reads failed
(`is unreadable with a scaled duration or period`), and the foreign path ignored any reason that was not a total, so
the read stayed. The ADR 0676 route for a foreign total, a periodic-total hit scenario, is `unmodelled` for these
ranks (800214 is a passive, as Feast of Talons 500056 is), so it would drop the check.

## Options

1. Route the two labels to `periodic_totals` like Witch Hunter's 500056 and 680238: the labels become `unmodelled`.
2. Judge every foreign total per tick: moves the two Witch Hunter labels of a finished class.
3. Opt-in per class file: a listed foreign total keeps its `effect_value` read and is judged against the token
   divided by its tick count.

## Decision

- `period_reading` takes an optional `ordinal`: the foreign path re-reads the rank's whole tooltip with the scaled
  duration or period and takes the value at the token's ordinal, so an `@s:` token keeps its expansion's context.
- On a foreign token, a probe reason that is not a total (a `mixed` reading, an unreadable scaled read) makes the
  label `unmeasurable` instead of keeping a read.
- Option 3: a class file's `per_tick_foreign_totals` (`{spell, effect, reason}`) lists the foreign effects whose
  total is judged per tick. The expectation keeps its label, its `spell_effect_value` step and its rule `read <kind>
  per tick: ...`; the model adds `ticks`, duration over amplitude of the listed spell, as the hit scenarios divide a
  total (`periodic_tick_readout`). `compare.judge_token` expects the token divided by `ticks` and skips the roll,
  base-roll and aura-227 branches; the per-level check divides the tooltip's per-level part by the same count.
  The flat band is the total's band divided by `ticks` (`max(1, 0.5 %)` of the total, over `ticks`), so one
  point off per tick, six off the application, alerts as it would against the total.
  Generation stops when a listed effect rolls or its token is not a total over its ticks.
- Felsworn lists Felstrike 802678 effect 0.

## Consequences

- The two Felsworn labels compare 9 per tick (SP 0, band 8.83 to 9.17) with the read; the read of 34 still alerts,
  the server value being the owner question of D-23. No label of any class disappears or becomes unmeasurable or unmodelled.
- Templar (both generations), Necromancer, Witch Hunter and Sun Cleric generate byte-identical output; Felsworn
  changes only the two expectations and its embedded class file in the manifest.
- Witch Hunter 500056 and 680238 stay `unmodelled` periodic totals; listing their effects would judge them per
  tick, a change to a finished class left to its owner.
