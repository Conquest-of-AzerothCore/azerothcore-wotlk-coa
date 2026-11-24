# 1247. Object scale is a state read, judged with an ended read

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-23
- Decided by: mentor ruling D-19 point 1 (Felsworn conformance)

## Context

Fel Monstrosity 500067 says "and size by $s2%." Its Effect[1] (aura 23, SPELL_AURA_PERIODIC_TRIGGER_SPELL, amplitude
9999 ms) triggers 500076, whose Effect[1] is aura 61 SPELL_AURA_MOD_SCALE with BasePoints 9 (+1 = 10, the tooltip's
`$s2`); 500076 has DurationIndex 38, 11000 ms in SpellDuration.dbc. The harness metric `object_scale` reads
`Object::GetObjectScale()`, which returns the `OBJECT_FIELD_SCALE_X` update field. Coverage had no evidence class
for `object_scale`, so `conformance.py prove` stopped with an `EvidenceError`.

Options:

1. Read the size from the `SMSG_UPDATE_OBJECT` packet (`server_packet_float` with an opcode and offset spec).
2. Read `object_scale` as a state, judged as a ratio against the tooltip percentage.

`OBJECT_FIELD_SCALE_X` is the field the server replicates to the client in its update packets, so the getter
returns the value the client receives; option 1 reads the same number through a packet parser and adds a spec to
maintain.

## Decision

Option 2.

- `coverage.METRIC_EVIDENCE` classes `object_scale` as `STATE`, and `STATE_PROMISES` gives it `\bsize\b|\bscale\b`:
  a passing `object_scale` read proves a clause that names size or scale.
- A `metric_delta` option `ended_read` (`{unlearn, wait_ms, duration_ms}`) adds a third reading after the after
  reading: it unlearns the listed spells, waits `wait_ms` (longer than the stated `duration_ms` of the triggered
  aura), reads the metric again and alerts unless the reading equals the before reading of the same scenario within
  the entry's tolerance. The baseline is always that before reading, never an assumed 1.0. The engine adds scale
  points (`Unit::RecalculateObjectScale` adds the native scale and a percent of 1.0), so the ratio equals the tooltip
  only at a baseline of 1.0, which this fixture reads; another scale aura on the fixture would give a ratio below
  1.10 and alert.
- The 500067 entry judges `expected_ratio` 1.10 within 0.001 (float32 rounding of 1.1 is about 2e-8; +9% and +11% are
  0.01 away), with the ended reading 12000 ms after the unlearn, past the 11000 ms of 500076.

## Consequences

- No finished class file uses `object_scale` or `ended_read`, so their generated scenarios and digests do not move;
  the coverage audits of the Templar, Necromancer, Witch Hunter and Sun Cleric ledgers on fixed verdict sets are
  byte-identical before and after the row.
- A clause naming size or scale can now be proven by an `object_scale` state read; any other clause keeps its class
  of evidence.
- `ended_read` requires the default gate timing and refuses an `expiry_wait_ms`, attack swings or
  `setup_only_after`.
