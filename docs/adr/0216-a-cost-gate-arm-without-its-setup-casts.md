# 0216. A cost-gate arm without its setup casts

- Status: accepted
- Date: 2026-11-12

## Context

Transcending Strikes 804897, claim 371: "Your Divine Force will now trigger a $/1000;804918s1 sec reduced cooldown when
used on enemies affected by Blade of Faith." The cost gate's arms contrast the talent (without, with, beyond), and its
`setup_casts` (Blade of Faith at the dummy) run in every arm. Nothing showed that the reduction needs the target's Blade
of Faith; the stored `target_gate` reading is a remaining-cooldown readback.

## Decision

`unset_arm: true` adds an arm `unset` after `with`: the talent known, the cooldown reset and the gated spell primed as
in `with`, but the `setup_casts` skipped, and the attempt at the reduced wait refused. It needs `setup_casts`. Entries
without it regenerate byte-identical.

## Consequences

- Transcending Strikes on build 861e0e1e6bee: Divine Force 806153 primed at a dummy carrying Blade of Faith 803880 and
  attempted 90500 ms later: refused without the talent (67), through with it (0), refused at 89500 ms (67), and refused
  at 90500 ms with the talent but no Blade of Faith on the dummy (67).
- Seeded tests: the unset arm casts no setup spell and expects a refusal; an unset arm without setup casts is refused.
