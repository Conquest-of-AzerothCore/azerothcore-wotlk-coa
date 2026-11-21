# 0622. A copied disease is read against a fresh cast after a spell power raise

- Status: accepted
- Date: 2026-11-13
- Builds on: ADR 0581

## Context

Virulency 801938 "Reinvigorate your diseases, refreshing all diseases on the target enemy and copying them, preserving
their power and duration" (claim 226.0). The refresh entry reads a readback on the source; the Infest entries show
that a copy lands, not what it carries. A copy made at the caster's current spell power would read like a kept one,
so "power preserved" needs a contrast: the spell power must change between the copy and the Infest.

## Options

1. `metric_delta` with a second target: its reads take one metric per phase and one dummy.
2. A kind module `disease_copy` on three dummies (source, copy, control), with the spell power raised by an aura
   amount fixture between the copy and the Infest, and the reads stamped in game time.

## Decision

Option 2 (`kinds/disease_copy.py`, no C++). The copy must keep the source's amount from before the raise while a
fresh cast after it carries more (the control, unmeasured otherwise), and its duration must equal the copied
duration (`duration_ms`, the refreshed full duration) less the time since the Infest. The copy is taken at the
Virulency, after the refresh, so "preserving their duration" is read as the duration at the copy; the source's own
remaining time (about 4700 ms less) is read beside it and must be separable inside the G-19 band.

## Consequences

- Flesh to Worms 500338 (18000 ms) with QA Test +100 SP 10062 effect 0 at 1000.
- If the mentor reads "preserving their duration" as the source's remaining time at the Infest, the same reads
  judge it by changing the expectation, not the scenario.
- Templar scenarios are unchanged (no Templar entry uses the kind).
