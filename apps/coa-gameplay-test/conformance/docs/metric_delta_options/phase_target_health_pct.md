# Phase target health (`metric_delta` `phase_target_health_pct`, ADR 0717)

`phase_target_health_pct` is `[before pct, after pct]`, each 1-100, the after one lower, on an entry whose target is
the dummy and that sets no `target_health_pct`. At the start of each phase, before its setup casts, the dummy's health
is set to that percent (`set_health_pct`). `target_health_pct` sets it right before every trigger cast instead, after
the setup casts: a health-gated setup cast is then refused, and a second fixture after a hit would raise health, which
the harness refuses ("set_health_pct cannot raise health"). The after percent is lower because the before phase's
hits already took the dummy below the first one. It adds no check. Absent, the scenario is unchanged.

Witch Hunter: Stake 681350 `flames_extension_present` and `flames_extension_absent` (setup Stake and trigger Stake,
both gated at 35% health; claim 180.1).
