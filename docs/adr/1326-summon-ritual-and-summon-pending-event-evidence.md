# 1326. `summon_ritual` kind and `summon_pending` event evidence prove multi-ally summoning rituals

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-26
- Rulings: Bloodmage (class 20) Bucket 2 tool plan (`1200012` Blood Covenant `row#553`)

## Context

Bloodmage's `1200012` (*Blood Covenant*) carves a blood rune via a multi-stage summoning ritual: casting `1200012`
creates gameobject `194111` (`GAMEOBJECT_TYPE_SUMMONING_RITUAL`), two grouped party members click it to trigger
`1200014` (*Blood Covenant Completion*) creating `194114` (*Blood Covenant Rune*, `GAMEOBJECT_TYPE_MEETINGSTONE`), a
party member selects a distant party member and clicks `194114` to open `179944` (*Meeting Stone Summoning Portal*),
and another party member clicks `179944` to leave the distant ally with `summon_pending == 1`.

The hand-written regression `apps/coa-gameplay-test/scenarios/bloodmage-blood-covenant-summons-party-11165.json` already
exercises every required harness primitive (`group`, `teleport`, `use_nearby_gameobject`, `select`,
`owned_gameobject_count`, `summon_pending`) with zero C++ changes. Conformance tooling lacked both a reusable kind for
this multi-ally gameobject chain and a `coverage.METRIC_EVIDENCE` classification for `'summon_pending'`.

## Options

- Classify `'summon_pending'` as `STATE` with a `STATE_PROMISES` regex: rejected, because `summon_pending` directly
  observes the outcome of the delivered summon spell (`Ritual of Summoning Effect 7720` calling
  `Player::SetSummonPoint`) in a multi-step ritual with pre-ritual, post-stone, and post-portal `0` controls, matching
  event-class outcomes such as `water_walk` and `aura`.
- Register `'summon_pending': EVENT` in `coverage.METRIC_EVIDENCE` and add reusable `kinds/summon_ritual.py`
  (`ORDER = 64`) modeling the four-player ritual chain with chronological milestone alerts and intermediate controls.
  Chosen.

## Decision

Extend `apps/coa-gameplay-test/conformance/coverage.py` and add
`apps/coa-gameplay-test/conformance/kinds/summon_ritual.py` (`ORDER = 64`,
[doc](../../apps/coa-gameplay-test/conformance/docs/kinds/summon_ritual.md)):

- Register `'summon_pending'` under `EVENT` in `coverage.METRIC_EVIDENCE` so `summon_ritual` verdicts count as
  `behaviour` evidence.
- Implement `summon_ritual` with four grouped same-class players (`caster`, `first`, `second`, `faraway`), teleporting
  `faraway` at least `50 yd` away on the same map, checking clean `0` baselines before casting `spell`, then stepping
  through `ritual_entry` creation (`cast_failure == 0`, count `1`), two-ally click to carve `stone_entry` (count `1`,
  control `summon_pending == 0`), ally `select` + stone click to open `portal_entry` (count `1`, control
  `summon_pending == 0`), and second-ally portal click leaving `faraway` with `summon_pending == 1`.
- Judge milestones chronologically so an early ritual break that causes a later `use_nearby_gameobject` step to abort
  reports `alert` on the broken stage rather than `unmeasured`.

## Consequences

- Pure Python change; zero C++ harness edits and zero diff on finished-class snapshots (`templar (19)` and
  `necromancer (23)`).
- Reusable for Warlock *Ritual of Summoning* and similar multi-player summoning stone rituals.
- Unit tests in `kinds/test_summon_ritual.py` and `test_coverage.py` verify scenario validation, `EVENT` evidence
  classification, full-chain pass, per-stage mutants (including truncated runs), baseline `unmeasured` guards, and
  input validation refusals.
