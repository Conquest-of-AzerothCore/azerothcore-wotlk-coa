# 0022. Spirit speed lasts while Spirits are held

- Status: accepted
- Date: 2026-11-21

## Context

With Spirit Walk known, `SyncSpirits` adds Spirit speed 561071 with one stack per Spirit. 561071 has DurationIndex 0
and is not passive, so `Aura::CalcMaxDuration` gives 0 and the aura added by `AddAura` expires on the next update:
572383 and 707504 `spirit_speed` read a run speed of 1.0 against the tooltip's 1.04 (triage rows 12-13). No player can
learn 707335 on this realm (M-52), so the path is dormant; the fix keeps it correct for when it is reachable.

## Decision

- The aura is made permanent (`SetMaxDuration(-1)`, `SetDuration(-1)`) when added; `SyncSpirits` already removes it
  when no Spirit is held.

## Consequences

- Regression: the class entries `572383 spirit_speed` and `707504 spirit_speed`.
- Fix note: cycle 10 triage.md FIX-T2.
