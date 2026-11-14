# 0043. Graveyard leaves one corpse per raised Undead

- Status: accepted
- Date: 2026-11-13

## Context

Claim 356.1 "and creating a corpse" (Graveyard 805197, Tombstones casting 500365 every 3 s, Risen Ghoul 542065 killed
500 ms after its summon) (shared ADR 0595).

## Decision

- Entry `805197 corpse_per_raise`, kind `corpse_per_raise`, 100 ms polls over 9000 ms, `death_ms` 1000; control: the
  cast before 805197 is learned. Expected one corpse per raise (the tooltip states a corpse per raised Undead).
