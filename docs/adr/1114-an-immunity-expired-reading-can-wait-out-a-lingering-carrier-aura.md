# 1114. An immunity expired reading can wait out a lingering carrier aura

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21
- Builds on: ADR 0134 (immunity post-expiry control), ADR 0864 (immunity variant)

## Context

Big Bad Voodoo 802719 "you are immune to all harmful spells and effects" (clause 470, tool note T-c9-B16-9, proposal
1046): the immunity is the field 802718 that the spirit casts every second with a 2200 ms aura duration
(AscensionWitchDoctorSummons.cpp:378-383). The immunity kind reads the carrier aura gone at the spell's duration plus
500 ms after the cast, which can fall inside the field's last refresh.

## Decision

- `immunity` entry field `expired_extra_ms` (default 0): the expired reading (and the control casts after it) waits
  that many more milliseconds. It needs a carrier `aura` other than the spell and a duration-ended immunity (no
  `remove_control`). The scenario contract names the extra wait.
- Witch Doctor entry `802719 immunity field` (1714, 35317, 47021, `aura` 802718, `expired_extra_ms` 2500).

## Consequences

- Absent, the scenario is unchanged: classes 19 (with and without `--stack`) and 23 generate byte-identical.
- Seeded test in `test_landed_rate_and_ally_strikes.py`.
