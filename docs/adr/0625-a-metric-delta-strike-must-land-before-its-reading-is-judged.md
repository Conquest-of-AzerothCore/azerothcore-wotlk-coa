# 0625. A metric_delta strike must land before its reading is judged

- Status: accepted
- Date: 2026-11-13

## Context

Claim 389.0, Ghoul Mastery 503740 "Immune to movement slowing effects.": the `snare_control` entry (a striker casts
Hamstring 1715 at a Ghoul without the talent) read the Ghoul's run speed unchanged (1.14286) in final8 run 1 and
slowed (0.57143) in run 2, same scenario file and binary. The cast was accepted in both runs (cast_result 255,
TRIGGERED_FULL_MASK, identical step timings), so range, line of sight and timing are excluded. Hamstring is DmgClass 2
melee: Unit::MeleeSpellHitResult rolls miss, dodge, parry and block (Unit.cpp:3801-3900). The stored run keeps no
outcome record, so which roll is not proven. The immune entry has the same hole: its Effect[1] SCHOOL_DAMAGE carries
no snare mechanic, so the Frenzied Ghoul is not immune to the whole spell (Unit.cpp:11289-11309) and a missed strike
reads the same unchanged speed as the immunity. A cycle 9 pilot (20261113-201628) read 2 of 4 strikes landed on the
Frenzied Ghoul and 4 of 4 on the plain Ghoul.

## Options

- More strikes only: lowers the chance that none lands, never shows that one did.
- Read the snare aura on the struck creature: fits the control only; in the immune entry it is absent by design, and
  in the control an absent aura after a landed strike is the defect the entry exists to catch.
- Read the strike's own damage logs: a landed Hamstring logs its Effect[1] damage whether or not the aura is refused.

## Decision

A `metric_delta` option module `strike_landed` (`true`; the entry's `strike` must hit an owned creature) reads
`spell_log_count` of the strike spell with `caster` the striker right after the after reading, and adds a fifth named
point `verdict` (`metric_delta_options.option_verdict`, called in `compare.behaviour_metric_delta_verdict`): no log is
`unmeasured`, otherwise the verdict is unchanged. The two 503740 entries set it and strike four times, 300 ms apart
(Hamstring lasts 15000 ms, DurationIndex 8).

## Consequences

- A missed strike no longer flips the control to alert, and the immune entry is no longer ok without a strike that
  reached the Ghoul.
- No harness change: `spell_log_count` with `caster` exists. Templar has no entry with the option; Templar
  `generate --class 19` and `--stack` are byte-identical to 628582dc78.
