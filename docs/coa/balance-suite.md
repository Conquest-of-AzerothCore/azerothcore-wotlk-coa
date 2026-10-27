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
  `NextKitRule` and the Necromancer/Felsworn kits in `catalog.json` for the pattern. Only Necromancer
  (Animation) and Felsworn (Infernal) have a kit today. Source evidence (a dedicated `Ascension<Class>Summons.cpp`,
  a tamed-beast path, or a pet-system file) confirms Cultist, Tinker, Venomancer, Witch Hunter and Knight of
  Xoroth each have a scripted summon/pet path, Primalist has one via `AscensionPrimalistSpiritBeast.cpp`, and
  Stormbringer via `AscensionStormbringerPet.cpp`'s air elemental; `CoARotationAssist.cpp`'s `HasManualEffect`
  already excludes `SPELL_EFFECT_SUMMON`/`SPELL_EFFECT_SUMMON_PET` from the auto-rotation for every class,
  confirming the design's "summons are the kit's job, not the rotation's" rule is universal, not
  Necromancer-specific.

  **Felsworn Infernal, fixed**: an earlier session's guess, "Summon Infernal" (DBC id 637278), was falsified by
  the harness (`pets_owned_start` stayed 0; `637278` is referenced nowhere in `src/server/coa/`). The real path:
  `AscensionFelswornSummons.cpp`'s `Summon()` calls `Map::SummonCreature(..., 572163)` directly in C++ — `572163`
  ("Fel Doom") and `572183` ("Infernal", the extended Inner-Demon form) are only the tracking/script-hook spell
  ids attached to that summon (`AscensionFelswornAbilities.cpp:446` hooks `SPELL_EFFECT_SUMMON` on them), never
  themselves cast by a player. The actual player-castable signature spell is **560284** ("Infernal", DBC:
  `Effect[2]` = `SPELL_EFFECT_TRIGGER_SPELL`, description references `$572163d`), granted by talent entry 31295
  (`class_id` 14, `spec_id` 7, `tab_te_investment` 8) — which the catalog's Infernal build never selected. Added
  `[31295, 1]` to the level 40/60 talent builds (swapped out `[30302, 1]` to stay within the TE budget; entry
  31295 needs 8 TE invested below its tier, unreachable within the level-20 budget of 5, so Infernal's pet kit
  is structurally level-40+ only, not a bug) and set `kit: {opener: [560284], upkeep: [{spell: 560284,
  when: owned_below, value: 1, target: self}]}`. `SummonProperties.dbc` row 61 (`Category` 1 ALLY, `Type` 2
  GUARDIAN) makes `Map::SummonCreature` build a `Guardian` (a `Minion` subclass), so the Infernal is added to
  the player's `m_Controlled` like any other counted pet. Verified at level 40 (`balance-7-40`, all four
  stages): `pets_owned_start` 1, `damage_done_pets` > 0 throughout.

  **Witch Hunter Houndmaster, not fixed — still open**: "Houndmaster's Whistle" (801343) is a genuine
  `SPELL_EFFECT_SUMMON_PET` spell (`EffectMiscValue` 50124, description "Summons a permanent Shadowhound
  companion"), not a recall-only ability as an earlier session suspected — `Spell::EffectSummonPet`'s native
  engine path (`SpellEffects.cpp`) creates a brand-new `Pet` from any creature entry when the caster has none,
  with no class/PetStable prerequisite. The spell is gated by talent entry 17414 (`class_id` 15, `spec_id` 11,
  cost 0, no tier threshold), also missing from the catalog's Houndmaster build; adding it and a
  `kit: {opener: [801343], upkeep: ...}` still left `pets_owned_start` 0 at every stage's start, with
  `damage_done_pets` > 0 appearing only later in the fight (the `CanBotCast`-gated upkeep rule's retry
  eventually lands a cast; the opener's first unconditional `SubmitBotCast`, even duplicated to two casts, does
  not). This looks like a timing/ordering issue in `AdvanceBalanceStage`'s opener-completion check
  (`CoAGameplayTest.cpp`) rather than a wrong spell id, but that was not proven this session, so the Houndmaster
  `kit`/talent addition was reverted rather than committed as an unverified entry. A future session should
  instrument or single-step the opener phase for this spec specifically, not retry a different spell id.

  Cultist, Tinker, Venomancer, Knight of Xoroth, Primalist and Stormbringer still have no kit attempt recorded:
  finding their player-castable, opener-reliable summon spell needs the same per-class
  `Ascension<Class>Abilities.cpp`/`Ascension<Class>Summons.cpp` trace used for Felsworn above, each followed by
  the same harness-proven check; their stages may show `pets_missing` or weak dps/dtps that reflects the
  missing kit, not the class.

  The Necromancer ghoul population was previously capped at 1 (`upkeep`'s `owned_below` value), tighter than
  the server's own `AscensionNecromancer.cpp` `Capacity()` (base 2 minion-capacity points, `Raise: Ghoul`
  costs 1), so a real player's base 2 ghouls never matched the suite's 1, and the single ghoul only got
  resummoned after a full wipe. The opener now casts `Raise: Ghoul` twice and `upkeep`'s `owned_below` is 2,
  matching `Capacity()`'s base value (no capacity-boosting talent is in the catalog's Animation build, so 2 is
  the correct ceiling here, not a guess at "several"). A level 40 elite_1 rerun after the fix moved from
  `pets_owned_start` 1 (previously reported dead by the end) to `pets_owned_start` 2, `pets_alive_end` 2, stage
  outcome `win`.

  **Animation Life Force talents added.** `AscensionNecromancer.cpp`'s `Capacity()` is `2 +
  player->ApplySpellMod(805011, SPELLMOD_MAX_AURA_STACKS, capacity)`. Two spec talents feed that spell mod:
  Summoning Adept (spell 92123, CharacterAdvancement entry 4036, `RequiredLevel` 10 — also spec 35's identity
  entry) and Summoning Expert (spell 807494, entry 4237, `RequiredLevel` 30), each `Effect[last]` =
  `SPELL_EFFECT_APPLY_AURA`/`SPELL_AURA_ADD_FLAT_MODIFIER` with `EffectMiscValue` 31
  (`SPELLMOD_MAX_AURA_STACKS`) and `EffectBasePoints`+`EffectDieSides` = +1 (read directly from `Spell.dbc` via
  `coa-dbc-viewer`, matching `necromancer-audit-3678-summoning-expert.json`'s own contract for 807494). Both
  entries cost 0 AE/TE and have no `RequiredEntryIds`/tab-investment gate (`talent_gating.py`'s gating dump),
  so `talent_gating.validate_build` accepts them at any level that meets `RequiredLevel`; entry 4237 is
  unaffordable (level-gated, not budget-gated) at level 20 and was left out of that build. Added `[4036, 1]` at
  levels 20/40/60 and `[4237, 1]` at levels 40/60, raising ordinary capacity to 3 at level 20 and 4 at level
  40/60. The kit (single opener/upkeep list, not per-level) now casts `Raise: Ghoul` four times and
  `upkeep.owned_below` is 4 — the real `Capacity()` call still caps actual summons at the live value, so a
  level-20 character harmlessly fails its fourth `Raise: Ghoul` attempt instead of over-filling. Verified with
  `balance-35-20/40/60`, `elite_1` (`--gameplay-jobs 1`): `pets_owned_start` 3/4/4 matching the derived capacity
  at each level, `pets_alive_end` equal to `pets_owned_start`, `damage_done_pets` > 0 (2576/4628/10270) and
  every `specialization`/`advancement_rank` step `completed` with no talent-upload refusal in the worldserver
  log.
- **New gear tier**: `apps/coa-gameplay-test/balance/gear.json` is generated, not edited by hand — see
  "Full-kit gear generator" below. A new `armor/primary_stat` or `class_id/group/primary_stat` combination
  needs no new gear entry: re-run `generate_gear.py` and it is covered from `item_pool.json`.

## Dungeons and substitutions

| Level | Dungeon (map) | Fight spot | Elites | Boss |
|---|---|---|---|---|
| 20 | Razorfen Kraul (47) | `(2020.0, 2010.0, 60.0)` | Bloodscalp entry 4511 ×3 (level 24) | entry 4420 (level 27) |
| 40 | Scarlet Monastery (189) | `(1688.99, 1053.48, 18.6775)` | Scarlet Soldier 4286 ×3 (level 36) | entry 3975, Herod (level 37) |
| 60 | Stratholme (329) | `(3660.0, -3560.0, 137.85)` | Crimson Guardsman 10418 ×3 (level 57) | Maleki the Pallid 10438 (level 61) |

The design's defaults were Shadowfang Keep (33) for level 20 and Stratholme (329) + Ramstein for level 60;
Razorfen Kraul (47) replaces Shadowfang Keep because its fight spot was easier to place clear of native spawns at
the time of authoring — no further record of that decision survives beyond the catalog/dungeons data, so treat
this table as the record going forward.

Ramstein the Gorger (10439) was replaced by Maleki the Pallid (10438) after a full run recorded `invalid` for
every level 60 boss case. Ramstein's own smart_scripts On Reset action always runs a timed actionlist
(entryorguid 1043900) built for his scripted entrance in the real Baron Rivendare gauntlet: it sets
`UNIT_FLAG_IMMUNE_TO_PC` on him immediately and only removes it some seconds later. Spawned directly by
`balance_stage` instead of through that gauntlet, he carries the immunity from the first tick, so the fighter's
threat reference against him is never "online" (`ThreatReference::FlagsAllowFighting`), `Unit::SelectVictim`
finds no acceptable target and he evades on the very next update — duration_s 0.017, zero damage either side,
matching the recorded `invalid` outcome exactly. Maleki is a standalone Stratholme SmartAI caster of the same
level (61) with no On Reset script and no unit-flag toggling, so the existing fight spot needed no change. See
`apps/coa-gameplay-test/scenarios/balance-level-60-boss-stage-not-invalid.json` for the regression that pins
both halves of this down (Ramstein still evades; Maleki does not).

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

### Full-kit gear generator (fixed 2026-10-27)

`final-run-1` (`.agents/plans/balance-suite/reports/out/final-run-1/report.csv`) fitted fixtures with a single
chest item (`gear.json`'s only slot) and nothing else: at level 60 the median elite kill took ~14 s and a white
hit received cost a median 15.7% of max HP, both far outside what a geared player takes, and the level 60 boss
stage was `invalid` for all 70 specs. `gear.json` now fills every armor slot an armor type uses (head, neck,
shoulders, back, chest, wrist, hands, waist, legs, feet, two rings, two trinkets) plus a weapon kit, instead of
one chest piece.

**Source data.** `apps/coa-gameplay-test/balance/item_pool.json` is a snapshot of `item_template` rows with
`class IN (2, 4)` (weapon/armor), `ScalingStatDistribution != 0`, `Quality IN (4, 6, 7)` and `AllowableClass = -1`,
each tagged with the primary stat(s) its `ScalingStatDistribution` id carries (`ScalingStatDistribution.dbc`'s
`StatMod`, matched against `ITEM_MOD_STRENGTH`/`AGILITY`/`INTELLECT`). `ScalingStatDistribution` items scale
their stats from the player's level and the item's quality at equip/update time, the same mechanic item 401875
already relied on, so two kits built from the same quality tier at the same level carry the same stat budget by
construction — no stat math has to be replicated here. Refresh the snapshot by re-running the same query this
worktree's `verify.sh`/`run.py` database settings already expose (`apps/coa-gameplay-test/run.py`'s
`Connection`/`read_config`, the pattern `apps/coa-dbc/capture_sql.py` uses for spell/quest data) against
`item_template`, joined with a direct `ScalingStatDistribution.dbc` read; it needs the coa-verify-env image for
a MySQL client, not a running worldserver.

**Generator.** `apps/coa-gameplay-test/balance/generate_gear.py` is a pure function of `item_pool.json` and
`catalog.json` — no database or DBC directory at generation time — and writes `gear.json` with two sections:
`armor` (keyed `armor_type/primary_stat`, the 9 combinations the catalog uses; shared across every class with
that combination, since the slots don't depend on weapon proficiency) and `weapons` (keyed
`class_id/group/primary_stat`, 54 combinations, since weapon proficiency is per class and a class can appear in
more than one role or stat). Per slot it picks the lowest-entry Quality-7 item tagged with the kit's primary
stat, falling back to Quality 6, then 4, then to an untagged item of the same quality, then (for the one slot
with no scaling candidate at all below level 45 — see below) the closest-item-level plain item; every
`armor/stat` combination at a given level and slot still ends up on the same quality tier (the budget-equality
tolerance `GearTests.test_armor_kits_share_the_same_quality_tier_per_slot_per_level` checks), and every
`ScalingStatDistribution` candidate is additionally filtered to one whose `MaxLevel` covers the level bucket
(`CanEquipItem` rejects it above that otherwise — see below).

**Weapon mapping is this generator's call, from evidence**: `generate_gear.py` parses
`src/server/coa/AscensionLiveBaselineData.h`'s `AscensionLiveBaseline::Proficiencies` table directly (regex over
the header, no build step) to get each CoA class's actual weapon/armor skills, since that is the table
`AscensionCompat.cpp`'s `AscensionCompatHandler::SynchronizeProficiencies` enforces on every login/spec sync —
it both grants any proficiency a player is missing and `removeSpell`s one a player holds that it does not list,
so it overrides whatever `AscensionCustomClassData.h`'s `ClassProficiencies` (or `playercreateinfo_spell_custom`)
granted at character creation. `TalentProficiencies` (also in `AscensionCustomClassData.h`) adds a few more
proficiencies, but only while a specific talent is held, and `gear.json` is shared across every spec of a class,
so those talent-gated entries are not used: only a proficiency every spec of a class keeps unconditionally is
safe to equip. Several classes catalogued as a given armor/stat combination do not share the same weapon
proficiency (for example `leather/agility/tank` covers both Felsworn, which has no Shield proficiency, and a
sibling that does), which is why weapons are keyed by class, not by `armor/primary_stat`. The rule, uniform
across all 54 combinations: an `intellect` spec gets a one-hand weapon tagged `intellect` (dagger/mace/sword/axe/
fist, in that preference order) plus an off-hand holdable item, or a two-hand staff if the class has no one-hand
type at all; a `tank` spec gets a one-hand weapon plus a shield if the class has Shield proficiency, an off-hand
holdable otherwise, or a two-hand weapon if the class has no one-hand type; every other (non-tank, non-intellect)
spec gets a two-hand weapon (polearm/sword/axe/mace/staff) matching its proficiency, falling back to one-hand
plus holdable if it has no two-hand type. `playerbots_coa_rotations.sql` tags every one of the twelve tank specs
"Position: close", including the one `intellect` tank (Starcaller/Moon Guard), which is why tanks are not split
into a separate caster-tank branch: all twelve use the melee weapon branch. `tools/test_balance_suite.py`'s
`GearTests.test_weapon_items_match_class_proficiency` and
`GearTests.test_class_proficiencies_match_live_baseline_header` check every generated weapon item's subclass
against the class's actual live-baseline proficiency (the latter re-parses the header independently of
`generate_gear.py`), so a wrong mapping or a regression back to the creation-time table fails the harness stage,
not only a human reading the table.

`apps/coa-gameplay-test/balance/item_facts.json` is the subset of `item_pool.json` that `gear.json` actually
references (`required_level`, `max_level`, `class`, `subclass`, `inventory_type`, `quality`); `GearTests` reads
it instead of a hand-maintained table so a regenerated `gear.json` cannot drift from the facts it is checked
against.

**Two equip-time defects found while building the full kit** (both reproduced with a minimal two-item
scenario before being fixed, not guessed from the error code alone):

- **Vanity-collection gating.** A chunk of the `Quality 7` scaling pool (the `1339xxx`-range entries, e.g.
  "Pendant of the Sorcerer") also appears in `VanityCollection.dbc`. `AscensionCompat.cpp`'s
  `OnPlayerCanEquipItem` → `RefuseWithoutVanityRealmLevel` requires the *account*, not the character, to have
  reached level 60 or prestiged on this realm before equipping one — a fresh level 20/40 fixture account never
  has that, so equip failed with `EQUIP_ERR_CANT_DO_RIGHT_NOW` (39) on every item in that set; a level 60
  character passed only because reaching level 60 *is* the unlock. `refresh_item_pool.py` excludes every
  `VanityCollection.dbc` item id from `item_pool.json`.
- **`ScalingStatDistribution.MaxLevel` cap.** `Player::CanEquipItem` (`Player.cpp`) returns
  `EQUIP_ERR_ITEM_CANT_BE_EQUIPPED` (20) when an item's distribution `MaxLevel` is below the player's level.
  The one non-vanity scaling necklace in this item_template (`Necklace of the Sunken Empire`, Epic,
  `MaxLevel 55`) passed at 20/40 but failed at 60. `item_pool.json` records `max_level` per item and
  `generate_gear.py`'s `eligible()` filters out any candidate whose `max_level` is below the level bucket.

That necklace gap also showed that **no account-unrestricted scaling necklace exists below `RequiredLevel
45`**: `refresh_item_pool.py` additionally queries plain (non-scaling), `RequiredLevel`-eligible necklaces and
`generate_gear.py` falls back to the one closest to the level bucket's own item level for 20 and 40 — the
deterministic, closest-item-level fallback the design calls for when no scaling item exists for a slot. Every
`armor/stat` combination still gets the *same* necklace at a given level, so the fallback does not break
equal-budget parity across kits.

A smoke run comparing generated scenarios against `final-run-1` is recorded in
`.agents/plans/balance-suite/reports/gear-fix-1.md`.

### Weapon proficiency derived from the wrong table (fixed 2026-10-27)

`final-run-2` had 9 "Equipment change rejected: equip error 8" (`EQUIP_ERR_NO_REQUIRED_PROFICIENCY`) failures:
Guardian dps/dps-support (`18/dps/strength`, `18/dps-support/strength`) and Primalist tank (`31/tank/strength`)
at all three levels. `generate_gear.py`'s weapon mapping used `AscensionCustomClassData.h`'s
`ClassProficiencies`, which only reflects what a character is granted at creation. `AscensionCompat.cpp`'s
`AscensionCompatHandler::SynchronizeProficiencies`, which runs on every login/spec sync, strips any
proficiency spell not present in `AscensionLiveBaselineData.h`'s `AscensionLiveBaseline::Proficiencies` for the
player's class — Guardian's creation grant included Sword2H (spell 202), which the live baseline never lists
for class 18, and Primalist's creation grant included Shield (spell 9116), which the live baseline never lists
for class 31 — so both were removed from the live character before the fixture ever equipped the item the
generator picked for it. Full root-cause trace: `.agents/plans/balance-suite/reports/equip-error-8.md`.

`generate_gear.py` now derives `CLASS_PROFICIENCY_SPELLS` by parsing `AscensionLiveBaselineData.h`'s
`Proficiencies` array directly instead of hard-coding a copy of `ClassProficiencies`, so it cannot drift from
the table the server actually enforces again. The live baseline grants several classes more weapon types than
the old creation-time table did (for example class 12's Axe/Sword/Mace/Dagger, present in the live baseline but
absent from `ClassProficiencies`), so most classes' weapon kits changed, not only Guardian and Primalist's.
`TalentProficiencies` is still excluded, as before, since it is conditional on holding a specific talent and
`gear.json` is shared across every spec of a class. `apps/coa-gameplay-test/balance/item_facts.json` was
regenerated from `item_pool.json` for the resulting set of items `gear.json` references: item 44092 (Sword2H)
no longer appears (replaced by item 42945, a one-hand Sword, for `18/dps/strength` and
`18/dps-support/strength`), item 400063 (Shield) no longer appears for `31/tank/strength` (replaced by holdable
item 1540350), and the wider live-baseline proficiencies elsewhere (for example class 26's `tank/intellect`
gaining Shield) brought in further new items such as 401883.

`tools/test_balance_suite.py`'s `GearTests.test_class_proficiencies_match_live_baseline_header` independently
re-parses `AscensionLiveBaselineData.h` (not through `generate_gear.py`) and asserts it matches
`generate_gear.class_proficiencies()`, and explicitly that spell 202 is absent for class 18 and spell 9116 is
absent for class 31 in the live baseline — a regression back to the creation-time table fails this test even if
`generate_gear.py`'s own derivation were also reverted.
`GearTests.test_weapon_kits_never_use_a_proficiency_absent_from_the_live_baseline_for_any_class` checks every
weapon/shield item in `gear.json`, for every class/group/stat and level, against that same independently-parsed
set, and specifically that item 44092 (Sword2H) is never selected for `18/dps/strength` or
`18/dps-support/strength` and that `31/tank/strength` never carries a shield or item 400063.
