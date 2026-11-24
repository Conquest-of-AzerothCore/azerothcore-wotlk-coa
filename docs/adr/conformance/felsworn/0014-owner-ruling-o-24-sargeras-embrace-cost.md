# 0014. Owner ruling Felsworn O-24: Sargeras Embrace's cost

- Status: accepted (owner ruling Felsworn O-24 (2026-11-23, Felsworn ADR 0014))
- Date: 2026-11-23

## Context

Sargeras Embrace 800355 shows the cost line "30 Energy, plus 30 per sec" (lab render, from Spell.dbc PowerType 3,
ManaCost 30, ManaPerSecond 30) and channels for 5500 ms (DurationIndex 571). The stock `Aura::Update` charges 30
Energy every 1000 ms and removes the aura when the pool is below 30 (SpellAuras.cpp:771-801). From 100 Energy with the
untalented regeneration of 10 per second, the pool before the drains at 1, 2, 3 and 4 s is 80, 60, 40 and 20, so the
channel ends at 4.0 s and the end damage does not land. The cost comes from the client data under the stock engine;
no class code adds to it.

## Decision

The cost, 30 Energy plus 30 per second, is conformant as the client shows it. The channel stopping near 4.0 s from
100 Energy without the class's Energy talents is accepted. No server change.

## Consequences

- The cost line is a new ledger claim of 800355, counted on the measured drain: entry `free_3900` expects the channel
  aura on the dummy at 3900 ms and `free_4100` expects it gone at 4100 ms, from 100 Energy with no power hold. The
  bracket entries `free_3700` (present) and `free_4300` (gone) carry the same derivation without a ledger label.
- The end-damage and slow claims keep their entries, which hold Energy with `hold_power_during_wait` so the full
  channel is read.
