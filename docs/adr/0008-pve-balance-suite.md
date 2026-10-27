# 0008. PvE balance suite: real spawns, rotation assist plus kits, outside PR verification

- Status: accepted
- Date: 2026-10-27

## Context

Players report that creatures feel too weak in dungeons, with a Necromancer soloing Scarlet Monastery around
level 36 with five ghouls and Fetid Ward as the motivating example. `origin/main` showed no recent regression in
creature damage; the working hypotheses are unvalidated dungeon tuning (health ×2.5, damage ×1.5) and player-side
power, notably pet classes. There is no PTR access, so the owner wants an internal reference instead: run every
CoA specialization alone against the same dungeon encounters at levels 20, 40 and 60, and see at a glance which
specs stray too far from the other specs of the same role (`.agents/plans/balance-suite/design.md`).

## Considered options

1. Spawn real (non-summon) dungeon creatures inside each case's own instance, drive the player with a
   tank-less "fight whatever is engaged" solo driver, and layer pet/defensive kits on top of the existing
   `.rotation` selection (`CoARotationAssist::ChooseSpell`, ADR 0004).
2. Keep using `SummonCreature` fixtures as the rest of the gameplay harness does. Rejected: `CoACreatureScaling::
   IsEligible` excludes summons, so a summoned elite gets no CoA dungeon health/damage scaling — exactly the
   tuning this suite exists to measure.
3. Hand-write per-spec rotation lists in the catalog instead of reusing `ChooseSpell`. Rejected: 70 specs' worth
   of hand-picked spell lists would drift from the CoA Bots priorities players actually experience and double
   the catalog's maintenance surface; `ChooseSpell` already covers every CoA class and specialization (ADR 0004).
4. Make the suite a `tools/verify_all.py` gameplay stage, so every PR run measures balance. Rejected: it is not a
   pass/fail regression test (no "correct" DPS to assert against) and a 210-case run does not fit inside PR
   verification's time budget; it stays a separate, explicit command.

## Decision

Option 1:

- `src/server/coa/CoAGameplayBalance.h` holds the pure decisions (stage outcome, solo target selection, kit rule
  pick, swing tallying) as a header-only namespace, tested by the standalone `apps/coa-tests/balance_policy`
  harness — the same split ADR 0002/0004 established for raid bot logic.
- `CoAGameplayTest.cpp` spawns real dungeon creatures (`Creature::Create` + `AddToMap`, not `SummonCreature`) at
  the configured level so `OnCreatureSelectLevel` scales them exactly as a native spawn would, drives `solo`
  actors with no tank gate (`DriveSoloActor`), and adds two measurement actions: `balance_white` (a passive
  white-hit baseline, both directions, isolating creature damage tuning and armor from rotation quality) and
  `balance_stage` (a timed fight recording outcome/TTK/TTD/damage/healing via a per-actor `UnitScript` tally).
- Pet and minion specs get an explicit `kit` (opener/upkeep/defensive `KitRule`s) layered on top of
  `rotation_assist`, because `ChooseSpell` excludes summons, pets, taunts, shapeshifts, defensives and untargeted
  AoE by design (ADR 0004) — exactly the suspected problem area.
- `tools/balance_suite.py` generates one scenario per spec × level from a committed catalog
  (`apps/coa-gameplay-test/balance/{catalog,dungeons,gear}.json`), runs them through the existing
  `tools/verify_all.py --stages gameplay` machinery (no second runner), and aggregates `result.json` records into
  `report.csv`/`report.html`, medians and flags computed per role group (tank/healer/dps/dps-support) at each
  level × stage.
- The suite is not part of PR verification and no balance scenario joins the default gameplay selection; it is
  always run as an explicit, separate command (`docs/coa/balance-suite.md`).

## Consequences

- A kit is data the owner must author and review per pet-capable spec; only the Necromancer (Animation) has one
  as of this suite's first full run, so other pet specs run without pet upkeep or defensives and may show
  `pets_missing` or weak numbers that reflect the missing kit rather than the class (tracked in
  `docs/coa/balance-suite.md`'s Limits).
- Real spawns at a fixed, authored `(x, y, z)` fight spot depend on that spot actually sitting on the dungeon's
  walkable floor; an unverified spot can float tens of yards off the ground (an enemy that can never path to the
  player evades immediately; a player placed under the floor just never meets its enemy) and the failure mode is
  a scenario timeout, not an informative error. The fight spots are now checked with `point_ground_gap` before
  being committed; a future dungeon or fight-spot change must be checked the same way.
- The suite measures rotation-assist-plus-kit play, not optimal play, and not live (PTR) numbers; a flagged spec
  is a signal to investigate, not a verdict on its tuning.
- Because cases run concurrently (several worldservers, several lanes each) on one shared process per server,
  any new harness state the suite adds must be scoped per case/actor rather than kept as a single process-wide
  value — two balance-suite review passes (Task 4's `BalanceAccounting`, Task 9's `BalanceWhiteGuard`) found and
  fixed exactly this cross-lane sharing bug.
- The catalog's talent builds are only verified by construction for specs an external build covers; the
  deterministic tier-order fallback does not check each talent entry's own prerequisites
  (`AscensionCoATalentState`'s `RequiredEntryIds`/`TECost`/`AECost`), and the suite's first full run found that
  it produces a build the server rejects past the first entry for 67 of 70 specs (`docs/coa/balance-suite.md`'s
  "Known defect"). The report is only informative for a spec whose build the server actually accepted.
