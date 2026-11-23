# 1152. A last-application expiry can poll before its cast

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21
- Builds on: ADR 0593, ADR 0716 and ADR 1132 (last_application_expiry)

## Context

The True Spirit 802268 `true_lasts` times The True God 681233, which the Serpent Ward 500960 summon casts inside the
instant ward cast. The first poll after the cast already counted the application, so no rise was seen and both
final08 runs were unmeasured ("no application is seen after the cast"), while the aura held about 9950 ms from that
poll. Only `no_refresh` read a poll before the first cast.

## Decision

`poll_before_cast: true` reads one poll (time, application count, presence) right before the cast in each arm, so an
application at the cast is the rise from that read and the bracket starts at the cast. The contract says so. A
non-boolean value is refused.

## Consequences

Absent, nothing changes: generated scenarios of classes 19 (with and without `--stack`) and 23 are byte-identical.
Class 13: 802268 `true_lasts` sets it. Seeded tests in `kinds/test_last_application_expiry.py`.
