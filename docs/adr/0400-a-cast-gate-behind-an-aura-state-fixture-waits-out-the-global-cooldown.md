# 0400. A cast gate behind an aura state fixture waits out the global cooldown

- Status: accepted
- Date: 2026-11-13

## Context

`cast_gate_scenario` attempts the gated spell three times: blocked, after the bypass spell, and through the target
state fixture. A health fixture (`AURA_STATE_HEALTHLESS_35_PERCENT`, `AURA_STATE_HEALTHLESS_20_PERCENT`) waits 1000 ms
before the last attempt, so the gated spell's 1500 ms global cooldown from the bypassed attempt has run out. The frozen
fixture (`AURA_STATE_FROZEN`, a `set_aura` of Frost Nova 122, ADR 0303) has no wait. Glacial Impact 707402's allowed
attempt read `SPELL_FAILED_NOT_READY` (67) in both runs of pair 20261113-010419 (build 17ff0cc7e580): the global
cooldown of the bypassed cast, not the frozen gate.

## Considered options

1. Wait in `required_target_health_steps` after the Frost Nova fixture. Rejected: the value and hit scenarios that use
   the fixture cast once and would change for no reason.
2. Wait the global cooldown before the allowed attempt when the gated spell's state comes from an aura fixture. Chosen.

## Decision

- Before the allowed attempt, `cast_gate_scenario` waits `GCD_WAIT_MS` (1600 ms) when the gated spell's
  `TargetAuraState` is one of `TARGET_STATE_AURAS`.

## Consequences

- Health-fixture gates (Templar Titanstrike 806521) are unchanged: `generate --class 19` and `--stack` are
  byte-identical.
- Necromancer Glacial Impact 707402's "Requires Frozen Target" reads its allowed attempt after the cooldown.
