# 1265. Charge recharge timeout, fall-speed packet reads and more area fixtures

- Status: proposed
- Date: 2026-11-23
- Related: [ADR 0495](0495-damage-shield-packets-are-recorded-and-read-as-events.md) (recorded server packets).
- Decided by: controller go of 2026-11-23 (mentor: no objection).

## Context

Felsworn Fury of the Illidari 561216 ("2 Charges, 1.5 min recharge") timed out: its `charge_recharge` scenario waits
99500 ms and carried no `timeout_ms`, so the run's 90000 ms default applied. Reckoning 802058 ("your falling speed is
slowed") gets SPELL_AURA_FEATHER_FALL from the class contract; for a client-controlled player `Unit::SetFeatherFall`
only sends SMSG_MOVE_FEATHER_FALL to the client, and no metric read it.

## Options

- Always give `charge_recharge` a timeout: it would move the digests of finished classes.
- A timeout only when the scenario's own waits reach the run default.
- A new feather-fall state metric: the server sets no movement flag for a player until the client acknowledges.
- Record SMSG_MOVE_FEATHER_FALL and SMSG_MOVE_NORMAL_FALL like the other recorded opcodes and read them with
  `server_packets`.

## Decision

`charge_recharge` adds `timeout_ms` (waits + 60000 ms) only when its waits reach 90000 ms; shorter scenarios keep no
key, so every passing scenario regenerates byte-identical. The harness records the two fall opcodes (recording only,
no gameplay effect); a `metric_delta` entry reads them with `server_packets` and its existing `event` row.

The `metric_delta` fixture option `area_dummies` follows the same rule (controller go of 2026-11-23): it admits 11
distances instead of 9 (the dummy and 11 fill the 12 creatures `run.py` admits), for a cap of 10 additional targets
that needs an eleventh candidate (Hellfire Carver 707444). It is opt-in; no existing scenario changes and no evidence
row is added. A `friendly_creatures` option for "all allies" beyond a party cap was dropped before merge: its only
target, Infernal Whipcrack 805243 under Taskmaster's Army 800220, carries SPELL_ATTR3_ONLY_ON_PLAYER and refuses
creatures, so it had no user and no positive read in game (review fw-rl2 I-5). The cross-class guard
`test_cross_class_guard_the_sun_cleric_lockout_read_without_its_evidence_row_is_found` now expects Felsworn beside
Sun Cleric among the users of `school_prohibited` (Felbreak 800203 lockout reads; controller go, guard logic unchanged).

The packet read alone is not behaviour (mentor D-77, 2026-11-24: the slower descent is rendered by the client). The
claim is read instead through the server's own consequence of the aura: `Player::HandleFall` skips fall damage for a
player with a feather-fall aura (Player.cpp:15129-15131). The harness `fall` action (ADR 0237) feeds that handler a
landing, but refused a feather-falling player: the refusal kept a landing that cannot hurt from passing as a
reduction. It is lifted for feather fall only (hover, flight and physical immunity stay refused), because the
`fall_damage` judge already requires the control arm's loss above 0 on the same fall, which proves the handler ran,
and the treatment's aura read proves the aura was present. No passing scenario landed under feather fall, so none
changes. Reckoning 802058 reads 0 under the aura (controller go of 2026-11-24, G-39).

## Consequences

Recharge windows past 90 s can run; a cap of up to 10 extra targets can be read. The
fall-speed packet read proves the order sent to the client only; the landing read proves the server's fall-damage
exemption.
