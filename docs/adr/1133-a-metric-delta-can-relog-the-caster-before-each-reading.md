# 1133. A metric-delta can relog the caster before each reading

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21
- Builds on: ADR 0582

## Context

Brew Stew 807056 "Brewed items disappear if logged out for more than 15 minutes." Black Lotus Bisque 339008 is a
conjured item (item_template Flags bit 0x2), removed at login when the stored logout time is more than 15 minutes old
(PlayerStorage.cpp:6176, game time, PlayerStorage.cpp:5482-5487). The harness `relog` already moves the stored logout
time back by `offline_seconds`; no option used it (tool note T-c9-B16-13).

## Decision

The option `relog_before_read` (`before_offline_s` below and `after_offline_s` above 900 s) snapshots the judged read,
relogs the caster with the phase's offline time and reads again as a share of the snapshot (`ratio_to`). Game time is
stamped around each relog; the verdict is unmeasured when the stated time plus the relog's own game time no longer
straddles 900 s.

## Consequences

Opt-in only; generated scenarios of classes 19 (with and without `--stack`) and 23 are byte-identical. Class 13 gains
807056 `logout_expiry`.
