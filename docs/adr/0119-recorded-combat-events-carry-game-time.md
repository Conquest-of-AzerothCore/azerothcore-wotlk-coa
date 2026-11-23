# 0119. Recorded combat events carry game time

- Status: accepted
- Date: 2026-11-11

## Context

The clause-spec prototype's bounded timestamp trial (X2, commit 69ba008884, carried over by ADR 0116) needed times
on the events the gameplay harness records from the packets a player actor receives: `SpellCastEvent`, `SpellDamageEvent`, `SpellHealEvent`,
`SpellEnergizeEvent` and `MeleeHitEvent` (`src/server/coa/CoAGameplayTest.cpp`). They carried no time, so a
period ("every 3 sec."), a first tick or an internal cooldown seen on damage could only be read as a definition
readback (`aura_amplitude_ms`) or through the encounter timeline. The timeline records casts, auras, deaths and
encounter states, not damage, heal or energize logs; it needs `encounter_start` (one per scenario, which makes the
case exclusive) and reads relative to the boss's engagement.

## Considered options

1. Add damage, heal and energize events to the encounter timeline. Rejected: it keeps the `encounter_start`
   prerequisite and the exclusive case, and it needs new hooks beside the packet observer that already parses those
   logs.
2. Stamp the recorded events with game time when the packet observer stores them, and read first and interval
   metrics over them, referenced to the latest received cast of a named spell.

## Decision

Option 2. Each of the five structs gains `atMs`, set from `GameNowMs()` in the observer that stores the event; no
hook is added. `CoAGameplay::TimesFrom` (in `CoAGameplayTimeline`) keeps the stamps at or after an optional reference
and returns the first one's offset and the consecutive gaps. The metrics `event_first_ms`, `event_interval_min_ms`,
`event_interval_max_ms` and `event_interval_median_ms` take `stream` (`spell_damage`, `spell_heal`,
`spell_energize`, `melee_hit`) and `since_spell` (required for `event_first_ms`), with the existing `caster`,
`target`, `critical` and `hand` filters; `run.py` validates them, and the evidence table of the two proof statuses
(ADR 0120) classes them as event evidence.

## Consequences

- Periodic ticks, first ticks and per-event gaps are readable in any scenario, without an encounter and without an
  exclusive case. A stamp has the resolution of the world update that sent its packet (on the simulated clock up to
  25 ms in a `wait`, 3 ms in other steps).
- The X2 trial run (Condemn 567539, `EffectAmplitude[0]` 3000, duration 21000) read the first tick 3003 ms after the
  cast and every interval at 3000 ms, with and without an encounter, and the timeline placed the aura application in
  the cast's world tick; `scenarios/event-times-periodic-damage.json` keeps that as a regression.
- No conformance kind reads the metrics yet: an `every $t` clause stays a readback of `aura_amplitude_ms`, and an
  internal cooldown below the gap resolution stays a bespoke check, until a kind judges a period or a gap from them.
  Only the `spell_damage` stream has been exercised in game.
