# 1265. Charge recharge timeout and fall-speed packet reads

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

## Consequences

Recharge windows past 90 s can run. The fall-speed read proves the order sent to the client, not the client's fall.
