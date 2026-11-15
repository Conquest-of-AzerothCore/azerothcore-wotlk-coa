# 0041. March of the Dead's slow is timed from the last explosion

- Status: accepted
- Date: 2026-11-13

## Context

Claim 206.1 "for $707010d" (707010 DurationIndex 27 = 3000 ms); six walkers apply it at unknown times (shared ADR 0593).

## Decision

- Entry `707007 slow_expiry`, kind `last_application_expiry`, 25 ms polls over 5000 ms; control: the cast before
  707007 is learned. Expected 3000 ms, G-19 band 2850 to 3150 ms.
