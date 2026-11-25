# Incoming critical block rate and doubled amount (`kind: "critical_block_rate"`, ADR 1310)

ADR 1310 has a provisional number and is renumbered at merge (guide 14.4).

Proves both an incoming melee critical-block probability (`Unit::isBlockCritical`) and that every critical block
blocks strictly twice the normal shield block value (`2 * B` against `B`).

## Harness primitives

- Read `melee_blocks_taken_count` (`actor`, optional `block_kind` in `all`, `normal`, `critical`, `other`, `full`;
  default `all`): counts incoming `SMSG_ATTACKERSTATEUPDATE` hits carrying `HITINFO_BLOCK`, classified against the
  player's `GetShieldBlockValue()` `B`: `normal` (`blockedAmount == B`, partial block), `critical`
  (`blockedAmount == 2 * B`, partial block), `other` (partial block with any other amount), `full`
  (`victimState == VICTIMSTATE_BLOCKS`).
- Read `melee_blocks_taken_total` (`actor`, optional `block_kind` in `all`, `normal`, `critical`, `other`; default
  `all`): sums `blockedAmount` over the matching incoming block events.
- Both metrics are registered as `event` evidence inside `kinds/critical_block_rate.py`'s `METRIC_EVIDENCE` dict
  (no edit to `coverage.py`).

## Scenario and arms

- Equips the spell's shield weapon set (`armed_for`), learns `Block 107`, engages `strikers` stationary melee
  creatures (with haste and AP fixtures so every incoming hit exceeds `2 * B` and never full-blocks), and pauses
  them with Stun `56` during setup and reads.
- `control` (before `gate_spell` is learned) and `treatment` (after a real learn) each verify `shield_item` in slot
  `16`, `after_setup_stacks`, and constant `block_value` `B > 0`, then collect incoming blocks across windows with
  `dodge = 0, parry = 0, block = 100`.
- Control requires `>= min_ctrl` pooled blocks and `0` critical blocks (any critical block alerts).
- Treatment pools across `parts`, requires `>= min_treat` blocks (exact binomial sample size for G-20 `±2 pt` band
  with pair false-fail and false-pass `<= residual`, default `0.1%`), requires `full == 0` (else `unmeasured`),
  requires `other == 0` and exact `normal_total == B * normal`, `critical_total == 2 * B * critical` (exact `2.0x`
  ratio; any deviation alerts), and judges `critical / all` with its 99% Wilson interval inside the G-20 band.

## Refusals

Refuses unknown fields, `expected_pct` outside `(0, 100)`, `strikers` outside `1..10`, non-offhand `shield_slot`,
`gate_spell` in `learn`, `residual` outside `(0, 1)`, negative `setup_wait_ms`, and non-caster `phase_auras` or
`after_setup_stacks`.
