# PvE balance suite

An internal reference, not a PR gate: it runs every CoA class specialization alone against the same dungeon
fights at levels 20, 40 and 60, and writes a table that flags the specs straying from their role group. It
answers "does this spec solo a dungeon encounter like its peers", never "is this build optimal" and never "does
this PR regress gameplay" — see `docs/adr/0008-pve-balance-suite.md` for why.

## Run it

```
python -B tools/verify_all.py --stages build
python -B tools/balance_suite.py run --output .agents/plans/balance-suite/reports/out/<name> \
  --jobs 4 --lanes 15
```

`run` generates one scenario per spec × level under `<output>/scenarios`, runs them through
`tools/verify_all.py --stages gameplay` into `<output>/verify` (`--jobs` worldservers, `--lanes` concurrent
cases each, in-RAM MySQL, simulated clock — see `docs/coa/verification.md`), then harvests `<output>/verify`
into `<output>/report.csv` and `<output>/report.html`. `python -B tools/balance_suite.py report --output <dir>`
re-aggregates an existing `verify` directory without rerunning anything (useful after editing the catalog's
non-gameplay fields, or to change `--threshold`).

`run.py`'s own `--stages gameplay` call bypasses `tools/balance_suite.py run`'s subprocess and goes through
`verify.sh` instead on this workstation, because verification here runs inside the `coa-verify-env` Docker image
against the in-RAM MySQL (`docs/coa/verification.md`'s fast-verify route); `tools/balance_suite.py run`'s
internal `subprocess.run` call has no such wrapper, so it only works unmodified on a host where
`tools/verify_all.py` runs directly. Generate the scenarios with `generate_scenarios` (pure Python, see the
module's `__main__`) and pass them to `verify.sh --stages gameplay --scenario <files> --gameplay-jobs N
--gameplay-lanes M --output <dir>/verify`, then call `tools/balance_suite.py report --output <dir>` to harvest.

Useful flags: `--levels 40` or `--specs 35,42` for a partial run (do this before trusting a catalog edit against
the full 210 cases); `--cap-s` and `--threshold` match the suite constants (120 s, ×/÷1.5) unless you are
deliberately retuning them.

Options kept in the suite's own defaults, not CLI flags, so a change to them is a reviewed catalog/dungeon edit:
levels (20/40/60), stages (white-hit baseline, then 1/2/3 elites and a boss), role groups (tank/healer/dps/
dps-support), white-hit swing count (20).

## Reading the table

`report.html` is one table per level, one row per spec, one column per stage (white-hit baseline, elite_1,
elite_2, elite_3, boss). Each stage cell shows the outcome and `dps`/`dtps`/`ttk`/`ttd`, highlighted when any
flag below is set; a group filter narrows the view. `report.csv` has the same rows, one per spec × level × stage,
with every harvested and computed field (`tools/balance_suite.py`'s `harvest_row`) for diffing between runs.

Per spec × level × stage, `dps`/`dtps`/`hps` (player + pets' damage/damage-taken/healing, divided by the stage's
duration) are compared against the **median of the same role group, same level, same stage** (`tank`, `healer`,
`dps`, `dps-support`; a group with under 3 valid rows gets ratios but no flags, shown as `n<3`). A cell is
flagged when its ratio to that median is outside ×/÷1.5 (`--threshold`), or:

- `flag_outcome`: the stage's outcome (win/loss/timeout/invalid) differs from the group's majority outcome.
- `pets_missing`: the spec's kit expects pets but `pets_owned_start` was 0 or its pets dealt no damage
  (`damage_done_pets == 0`) — the kit failed to field them, not "this pet spec is merely weak".
- Tank-only: `tank_clears` (won `elite_2`, `elite_3` or `boss` — tanks are not meant to solo-clear multi-mob
  stages), `tank_dies_early` (died faster than the combined dps+healer median time-to-death), `tank_dps_high`
  (matched or exceeded the dps group's median dps).
- `dps-support` rows also carry `ratio_dps_vs_dps` (support dps against the `dps` group's median, informational,
  never flagged) since support is compared against its own small group first.

An `error` row (case failed, crashed, or produced no `balance`/`balance_white` record for that stage) always
shows as `error: <message>`; the suite still writes the rest of the table (Task 8's `failed_case_becomes_error_row`).

## Extending the catalog

- **New spec**: add an entry to `apps/coa-gameplay-test/balance/catalog.json` (`class_id`, `spec_id` from
  ChrSpecs.dbc, `group`, `armor`/`primary_stat` matching `gear.json`'s keys, `talents` per level as
  `[[entry, rank], ...]`, optional `kit`). Run `python -B tools/verify_all.py --stages harness --harness
  test_balance_suite` (catalog shape) then `python -B tools/balance_suite.py run --specs <id> --output <dir>`
  before trusting it in the full run.
- **New kit** (pet summons/upkeep, defensives): a `KitRule` list (`spell`, `when`
  `always|self_aura_missing|pet_aura_missing|owned_below|health_below`, `aura`, `value`, `target`
  `self|pet|enemy`) under `opener`/`upkeep`/`defensives` — see `src/server/coa/CoAGameplayBalance.h`'s
  `NextKitRule` and the Necromancer kit in `catalog.json` for the pattern. Only the Necromancer (Animation) has
  a kit today; every other spec whose spells summon units (for example Tinker Demolition/Mechanics, Primalist
  Wildwalker, per the design's recon) runs without one, so its stages may show `pets_missing` or weak dps/dtps
  that reflects the missing kit, not the class.
- **New gear tier**: `apps/coa-gameplay-test/balance/gear.json` needs one `{item, slot}` chest piece per level ×
  `armor/primary_stat` pair, equal stat budget across armor types at that level (Task 7's
  `every_armor_stat_pair_has_gear_at_each_level` test enforces the keys, not the budget — check it by hand).

## Dungeons and substitutions

| Level | Dungeon (map) | Fight spot | Elites | Boss |
|---|---|---|---|---|
| 20 | Razorfen Kraul (47) | `(2020.0, 2010.0, 60.0)` | Bloodscalp entry 4511 ×3 (level 24) | entry 4420 (level 27) |
| 40 | Scarlet Monastery (189) | `(1688.99, 1053.48, 18.6775)` | Scarlet Soldier 4286 ×3 (level 36) | entry 3975, Herod (level 37) |
| 60 | Stratholme (329) | `(3660.0, -3560.0, 137.85)` | Crimson Guardsman 10418 ×3 (level 57) | Ramstein the Gorger 10439 (level 61) |

The design's defaults were Shadowfang Keep (33) for level 20 and Stratholme (329) + Ramstein for level 60;
Razorfen Kraul (47) replaces Shadowfang Keep because its fight spot was easier to place clear of native spawns at
the time of authoring — no further record of that decision survives beyond the catalog/dungeons data, so treat
this table as the record going forward.

Both the level 20 and level 60 fight spots were re-placed in Task 9: their original coordinates were a native
NPC's `z` copied onto a different `(x, y)` and were never checked against the server's own ground, so they sat
tens of yards off the real floor — the level 60 spot floated roughly 100 yards above its floor and the level 20
spot sat about 58 yards below its floor. A dungeon enemy spawned at a floating spot cannot path to the player and
evades within a few seconds (`anyEnemyEvading` → `StageOutcome::Invalid`); a player placed below the floor (or
whose enemy is) just never meets it, so the stage hangs until the scenario timeout instead of failing fast. Both
symptoms showed up only once the full 210-case run exercised every level, because the two-case Task 6 smoke test
and the Task 7/8 fixture catalogs happened to use levels that were fine. Check a candidate fight spot with the
gameplay harness's own `point_ground_gap` metric (an `assert` or `snapshot` step with `map`/`x`/`y`/`z`, see
`apps/coa-gameplay-test/README.md`'s placement metrics) before trusting a new one: a gap near zero is grounded; a
gap of tens of yards means the spot is off the real floor at that `z`, even when it sits 40+ yards from every
native spawn. `(3660.0, -3560.0, 137.85)` and `(2020.0, 2010.0, 60.0)` were probed this way, including small
offsets in every direction the harness actually places a spawn or lets a solo fixture drift in combat, before
being written to `dungeons.json`.

## Limits

- **Not optimal play.** Rotations are `CoARotationAssist::ChooseSpell`'s existing CoA Bots-derived priorities
  (ADR 0004), asked only while the bot is idle; the suite catches gross outliers (can't kill one elite, solos
  three without a scratch), not 10% tuning differences.
- **Rotation assistance excludes** summons, pets, taunts, shapeshifts, defensives and untargeted AoE by design
  (ADR 0004); those are the kit's job (see above), and only one spec has a kit today.
- **No movement or kiting simulation.** The solo driver (`DriveSoloActor` in `CoAGameplayTest.cpp`) keeps melee
  range or line of sight and switches targets by lowest health among engaged candidates; it does not reposition
  for mechanics, line-of-sight breaks, or kiting-dependent specs.
- **No live comparison.** There is no PTR access; a later, optional step could calibrate level 60 DPS against the
  private combat-log history (`~/Projects/coa-log-history`), out of scope here.
- **Talent builds** come from locally available external builds where the catalog's `talents` cites one;
  otherwise a deterministic tier-order spend inside the spec's tree. Neither is a claim about the "correct" build.
- **Not part of PR verification.** No balance scenario is in the default `--stages gameplay` selection; running
  the suite is always an explicit, separate command.

## Measured wall time

A full run of all 210 cases (`--jobs 4 --lanes 15`, in-RAM MySQL) on this workstation took **194.3 s** (about
3.2 minutes) of real wall time for the gameplay stage, well inside the 1-hour target, so no speed tuning (more
jobs, a shorter stage cap, fewer white-hit swings) was needed for this run. The simulated clock accelerates game
time inside each case (Task 6/9 smoke runs measured roughly 11-12 s of real time per 600 s of game time per case
at 15-lane concurrency on one server), so wall time scales with the slowest lane batch and the number of
`--jobs` servers the host's RAM and the shared `coa-test-mysql` tmpfs can support (~5.1 GB RSS and one ~772 MB
world copy per server — `docs/coa/verification.md`), not with the raw 210 × (white-hit + 4 stage caps) game-time
total.

## Talent builds are generated against the real gating data (fixed 2026-10-27)

The first full 210-case run (`.agents/plans/balance-suite/reports/out/task-9-full-2`) found 201 of 210 cases
failing an `advancement_rank` step with "The server did not apply the uploaded talent rank". Reading the
server path that handles the upload (`AscensionCompat.cpp`'s `SetTalentRank`/`ApplyKnownEntriesUpload`) against
the live `CharacterAdvancement.dbc` data showed the actual rejection cause: each CoA talent entry carries a
`TabAEInvestment`/`TabTEInvestment` tier threshold (how many points must already be spent in that same AE/TE
pool before the entry is purchasable), on top of `RequiredEntryIds`, `RequiredLevel` and the class/specialization
AE/TE budget. Task 7's "deterministic spend inside the spec tree by tier order" picked entries by raw entry-id
order, not by this tier gate, so most non-Necromancer builds tried to buy a high-tier entry before any lower-tier
points were spent and were rejected on the very upload that tried it.

`apps/coa-gameplay-test/balance/talent_gating.py` compiles the real `AscensionCoATalentData` loader against the
client DBC set (the same standalone-compile pattern as `apps/coa-tests/coa_talent_catalog.py`) and dumps every
`CoATalentEntry`'s gating fields plus the `CoATalentBudget` table as JSON — no server build or running
worldserver needed. `apps/coa-gameplay-test/balance/generate_talents.py` uses that dump to regenerate
`catalog.json`'s `talents` for every spec except the three Necromancer specs (34 Death, 35 Animation, 36 Rime,
which already cite a working external build): entries are picked tier-ascending, so the catalog's own upload
order stays valid at every incremental `advancement_rank` step, honoring `RequiredLevel`, `RequiredEntryIds`,
the tier gates and the level's AE/TE budget.

`tools/test_balance_suite.py`'s `TalentGatingTests.test_catalog_talents_satisfy_server_gating` re-dumps the
gating data and replays every spec's build at every level, one upload step at a time, through
`talent_gating.validate_build` (an independent reimplementation of the same checks, not a call into
`generate_talents.spend_build`), so a hand-edited or regressed `catalog.json` entry fails this test before it
ever reaches a live `advancement_rank` upload. It skips if no DBC set or C++ compiler is available.

### A second gating cost the first fix missed: the spec's own identity/signature entry (fixed 2026-10-27)

After the fix above, every level 20 build for 48 of the 70 specs still failed the same `advancement_rank` step
with "The server did not apply the uploaded talent rank", always at the step that reached the build's full AE
budget. Raising `Logger.coa` to INFO for one failing case showed the real server-side reason
(`AscensionCompat.cpp`'s `ApplyKnownEntriesUpload`): `"That build spends 7 class ... point(s); level 20 has 6"`
— one point more than the catalog build itself ever spends.

The extra point comes from `AscensionCoATalentState::SpecializationSwitch` (what the `specialization` step and
`CoAGameplayTest.cpp`'s `KnownEntriesWithRank` upload alongside any purchase): switching into a specialization
auto-grants that spec's identity and signature `CoATalentEntry` (`AscensionCoATalentData.cpp`'s
`CoASpecializations`), and `ApplyKnownEntriesUpload` counts their `AECost`/`TECost` against the same
class/specialization budget a purchased build spends from. Every spec's signature entry costs 1 class (AE)
point; `talent_gating.py` and `generate_talents.py` never reserved it, so a build that spent the full AE budget
on catalog entries left no room for the point the server charges automatically on top. At level 40/60 there was
enough slack in the AE budget for this to go unnoticed; at level 20 it was not.

`talent_gating.dump_gating` now also dumps `CoASpecializations` (identity/signature entry per class+spec), and
`talent_gating.mandatory_spend(gating, class_id, spec_id)` sums the AE/TE cost of those two entries. Both
`talent_gating.validate_build` and `generate_talents.spend_build` reserve this cost from the level's budget
before validating/spending on catalog entries (and treat the identity/signature entries as already known, for
the `RequiredEntryIds`/tier checks, without re-charging a build that also lists one of them explicitly — level
40/60 builds already did, since the greedy spend used to pick them up as ordinary candidates when the budget
had room). `generate_talents.spend_build` also excludes the identity/signature entries from the candidate pool
it buys from, so a regenerated catalog no longer lists them as if they were purchased choices.
`tools/test_balance_suite.py`'s existing `TalentGatingTests` test needed no change: it calls `validate_build`
directly, so it picked up the reservation automatically.

### Two level-tier plate/intellect gear entries exceeded their level (fixed 2026-10-27)

The remaining 12 failures were "Equipment change rejected: equip error 1" (`EQUIP_ERR_CANT_EQUIP_LEVEL_I`):
`gear.json`'s `plate/intellect` entry was item 22089 (Soulforge Breastplate, `RequiredLevel` 58) at level 40, and
item 28055 (Gilded Crimson Chestplate, `RequiredLevel` 60) at level 20 — both above the level of the player
trying to equip them. Vanilla WotLK plate armor pairs intellect with low levels only rarely, which is likely why
the catalog's original author reached for a raid-tier item at both levels.

Both are now item 401875 (Lightbringer's Chestplate of Divinity), a `RequiredLevel` 1, `AllowableClass -1`
scaling-stat (`ScalingStatDistribution` 332) plate chest piece — the same distribution `gear.json`'s existing
`mail/intellect` entry (item 48683) already uses, and the same pattern as the other scaling items already in
`gear.json` (`plate/strength` 48685, `mail/agility` 48677), so it fits every level the suite tests, not just the
two that were failing. Level 60's `plate/intellect` (item 25701, `RequiredLevel` 60) was left unchanged: it was
not reported broken.

`tools/test_balance_suite.py`'s `GearTests.test_gear_items_are_equippable_by_every_mapped_spec` checks every
`gear.json` item against a small table of `item_template` facts (`class`, `required_level`, `allowable_class`,
read from `acore_world.item_template` via this worktree's `verify.sh` MySQL): the item's `class` must be armor,
its `required_level` must not exceed the level bucket it is listed under, and an `allowable_class` other than
`-1` must not exclude any catalog spec mapped to that `armor/primary_stat` key. This is a static table, not a
live query, so it does not catch a future `item_template` edit to one of these specific items; it does catch a
new `gear.json` entry that forgets to add a fact row, or a `RequiredLevel`/class mismatch in the facts already
recorded.
