# 1163. A random pick is read per trial for each picked aura's effect

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21
- Builds on: ADR 0052 (`cooldown_pick_share`), ADR 0616 (`CONTRAST_PROOF`), ADR 0707 (`promise_of`)

## Context

Loa's Blessing 705848: a Loa's Brew heal applies one of four blessings at random (`urand(0, 3)`,
AscensionWitchDoctorAbilities.cpp:210-213), each with its own tooltip and value: 3% haste (802207), 3% healing
received (802208), 3% critical strike chance (802215), 3% less physical damage taken (802216). `carried_aura_count`
proves that one of the four is applied, not which, and setting one by `set_aura` would set the claim's subject. The
four ledger rows waited on "a share or pick kind that reads which blessing each real cast applied and the matching
stat".

## Decision

New kind `pick_effect`: each trial clears the pick auras, reads the judged states, makes a real cast, then reads which
pick auras the cast left and the states again. Control trials run before the passive is learned. One verdict per pick:
the trials that left it show each of its reads' stated change (a ratio or a gain within a tolerance), every other
trial no change; a control trial with a pick, or a trial with other than one pick, alerts; a pick never seen is
unmeasured. The verdict metric `pick_effect` is a readback gated by `CONTRAST_PROOF` (learned contrast) and promised
by the word "empower", so a ledger row that names the empowerment through `promise_of` counts an ok verdict as
behaviour.

## Consequences

New module only; classes 19 (with and without `--stack`) and 23 generate byte-identical scenarios. Class 13 gains
705848 `pick_haste`, `pick_healing`, `pick_crit` and `pick_physical` (one scenario, 48 trials). The uniform share of
the pick is not judged (the tooltip says "random", not "equal").
