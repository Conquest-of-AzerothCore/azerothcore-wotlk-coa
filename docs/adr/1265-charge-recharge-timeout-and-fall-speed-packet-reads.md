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

Two `metric_delta` fixture options follow the same rule (controller go of 2026-11-23): `area_dummies` admits 11
distances instead of 9 (the dummy and 11 fill the 12 creatures `run.py` admits), for a cap of 10 additional targets
that needs an eleventh candidate (Hellfire Carver 707444); and a new option `friendly_creatures` adds friendly
creatures outside the party (faction 35, entry 631) and sums the judged `aura` reading over them, for "all allies"
beyond a spell's party cap. Its first target, Infernal Whipcrack 805243 under Taskmaster's Army 800220, carries
SPELL_ATTR3_ONLY_ON_PLAYER and refused the creatures, so no entry uses the option yet. Both are opt-in; no existing
scenario changes and no evidence row is added.

## Consequences

Recharge windows past 90 s can run; a cap of up to 10 extra targets and an all-allies claim can be read. The
fall-speed read proves the order sent to the client, not the client's fall.
