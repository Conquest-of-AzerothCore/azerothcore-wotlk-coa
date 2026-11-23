# 1006. The harness can read an owned summon's remaining lifetime

- Status: draft
- Date: 2026-11-17
- Builds on: ADR 0120

## Context

Dead and Gone 705524 (Witch Hunter) states "Your Pavise now lasts 2 additional sec". Pavise 520865 summons creature
50519 and applies no aura, so the only read was `owned_creature_count`. `TempSummon::Update` unsummons the creature on
the map update after its timer runs out, 93 to 543 ms after the nominal end in the recorded runs, so a presence bracket
of the 2000 ms increase is (1391, 2609) ms and cannot exclude 10% off it (mentor D-382). Mentor D-467 (owner delegation
O-35) approved one read-only harness metric; D-472 kept a presence arm beside it.

## Decision

- `owned_creature_remaining_ms` (`entry`) returns `TempSummon::GetTimer()` of the one living timed-despawn summon of
  that entry selected as `owned_creature_count` selects it, -1 without one; it fails on more than one such creature or
  another despawn type. `GetTimer` returns the member `m_timer` and changes no state (`TemporarySummon.h:68`); the
  metric only lists creatures and reads it (`CoAGameplayTest.cpp`, beside `owned_creature_count`).
- Registration: `run.py` metric list and the `entry` requirement, `coverage.METRIC_EVIDENCE` class STATE and
  `STATE_PROMISES` `lasts?|duration`, a README line. No judge changes.
- The 705524 entry `pavise_remaining` uses the existing `metric_delta` `expected_gain` 2000 with `tolerance` 100: the
  timer is read 500 ms after each Pavise cast, before and after 705524 is learned. Both reads sit at the same step after
  their casts and the timer counts down on the summon's own updates, so the removal lag does not enter the reading.
- Presence arms `pavise_base_gone` and `pavise_ext_margin` read the creature gone without 705524 and held with it at the
  same moment, 10975 ms after the cast, and gone with it at 12975 ms; the 975 ms margin (reads 975 ms past the nominal ends) holds the removal lag.

Number assigned at integration; status draft until merged.

## Consequences

- Seeded tests: `test_runner.py` (player and entry required), `test_coverage.py` (STATE row and promise),
  `test_behaviours.py` `PaviseRemainingLifetimeTests` (read placement, the gain judge, a mutant without the extension and
  readings 200 ms off that alert, the presence moments).
- Existing scenarios of every class regenerate byte-identical; the metric is used only by entries that name it.
- A summon that dies or is dismissed early leaves no timer: the read returns -1 and the gain alerts.
