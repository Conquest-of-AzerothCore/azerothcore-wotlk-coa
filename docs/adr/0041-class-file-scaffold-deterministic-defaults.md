# 0041. A deterministic `scaffold` command for a class file's mandatory fields

- Status: accepted
- Date: 2026-11-09

## Context

`conformance.py generate --class N` crashes on `load_class_file`'s `ValueError` for any class without a
`classes/<name>.json`, and today only class 19 (Templar) has one. Templar's own file took ~150 hand-written
entries and days of investigation (`scale-out-mining.md`'s own count and category split). 20 more CoA classes
(12-32, minus 19) are planned, one at a time; per-class hand work for even the *mandatory* fields (`class_id`,
`name`, `race`, `level`, `weapon`, `skill_lines`, `reference_stats` — `scale-out-sweep.md` part 2's exact list)
does not scale, even though `scale-out-sweep.md` part 3 already showed every one of them is either fixed
(`class_id`, `level`) or mechanically derivable from a header, the client DBC or one measurement, with only two
choices (which race, which weapon) needing a stated, non-judgemental default rule.

## Considered options

1. Hand-write each class file as Templar's was written. Rejected: this is exactly the work the owner asked to
   collapse; the task's own framing states Templar "took days" and that per-class hand work must stop scaling
   linearly.
2. A generator that also fills coverage fields (`procs`, `triggers`, `behaviours`, `extra_spells`, the override
   lists) by inference over DBC/tooltip text. Rejected for this change: `scale-out-mining.md`'s own audit of
   Templar's 154 hand entries found only 21 (14%) derivable from DBC/tooltip text alone (categories A/B); the
   other 86% needs either server C++ reading (61%, category C) or log/judgement evidence with no data-derivable
   rule (25%, category D). Scaffolding these now would mean inventing unverified claims, which the task's own
   "never invent" rule forbids; `scale-out-sheets.md` proposes a separate, reviewed reader pipeline for that work.
3. A `scaffold` command that writes only the fields `scale-out-sweep.md` proved mandatory or mechanically
   sourced, leaving every coverage field as an explicit empty list/dict, with two stated default rules (lowest
   `playercreateinfo` race; lowest-`SkillId` `Proficiencies` row as the weapon) called out in the file's own
   README section as choices, not derivations. Chosen.

## Decision

- New module `scaffold.py` (`apps/coa-gameplay-test/conformance/`), wired as `conformance.py scaffold --class N
  --out FILE --config WORLDSERVER_CONF --mysql MYSQL`:
  - `class_title`: regex over `SharedDefines.h`'s `CLASS_* = N, // TITLE <name>` comment.
  - `class_proficiencies`: regex over `AscensionLiveBaselineData.h`'s `Proficiencies` array, scoped to the class.
  - `select_weapon_rows`: the lowest-`SkillId` row that resolves to an item subclass through
    `tooltip.weapon_skill_spells` is `weapon`; the next row with a *different* subclass, if any, is
    `alternate_weapons[0]`. A stated default, not a derivation (see the README section's Templar comparison).
  - `playercreateinfo_sql`/`item_candidate_sql`/`local_select`: the SQL text and the subprocess `mysql` client
    call, following `apps/coa-dbc/capture_sql.py`'s own pattern (`run.read_config`/`run.Connection.parse`, a
    `--defaults-extra-file` written `0o600`, never the password on the command line) rather than embedding a new
    database client dependency; not shared code with `capture_sql.py` (that function is a private closure of
    `capture()`), so this is a second, small copy of the same ~15-line pattern, not a refactor of `coa-dbc`.
  - `build_class_file`: a pure function (no DBC/DB access) assembling the class file dict from already-resolved
    inputs, fixture-tested without any DBC or database fixture.
  - `naked_scenario`/`reference_stats_from_result`: the previously-missing step that turns `profile.base_steps`
    into a runnable schema-1 scenario and a `verify_all` gameplay result back into exactly the `reference_stats`
    fields Templar's own file holds (`attack_power`, `ranged_attack_power`, `spell_power 1..6`, `stat 0..4`, one
    `skill <line>` per configured line — never `weapon_damage_min` or an aura label).
- `item_candidate_sql` adds `ItemLevel > 0` to `scale-out-sweep.md`'s stated rule (Quality 1, no stats, no
  procs, lowest `ItemLevel` then `entry`) after it matched `ItemLevel` 0 NPC-reuse weapons (`axe_1h_murloc`
  558847, `sword_2h_rayner_red` 558872) on the live `acore_world` table; still-surfacing `ItemLevel` 1
  `Monster - `/`Placeholder ` dev props (e.g. item 49340 ahead of "Worn Shortsword" 25 for class 19's chosen
  subclass) are left as a known, explained gap rather than a name-matching heuristic with no `item_template`
  column backing it (checked and ruled out: `ScriptName`, `VerifiedBuild`, `bonding`, `RequiredLevel`,
  `SellPrice`/`BuyPrice`).
- `test_scaffold.py` tests every function above except `scaffold_class` itself (the DBC+DB-querying orchestrator)
  with fixtures only: synthetic header text, plain dicts for item/race rows, and a mocked `subprocess.run` for
  `local_select` — no DBC directory or live database read in the test suite, per the task's own scope limit.
  Registered in `tools/check_source.py`'s `conformance` suite, which also gains
  `AscensionLiveBaselineData.h` as a trigger path.

## Consequences

- A future class only needs `scaffold --class N --out classes/<name>.json`, then the two-call `naked_scenario`/
  `reference_stats_from_result` measurement, to reach a `generate`-able file with value/hit/passive/melee
  coverage; `procs`/`triggers`/`behaviours`/`extra_spells`/the override lists stay empty until a later, separate
  pass fills them (by hand or by the reader pipeline `scale-out-sheets.md` proposes) — this command does not
  attempt that, by design.
- Scaffolding class 19 from data does not reproduce Templar's own hand file verbatim: the weapon/`skill_lines`
  differ (`select_weapon_rows` picks a Sword, skill 43, over Templar's hand-picked Staff, skill 136), for the
  stated reason above. `reference_stats`' own values (`attack_power`, `stat 0`..`4`, `spell_power 1`..`6`) matched
  Templar's exactly in a live measurement (stamp `20261109-140931`), since they depend only on race/class/level,
  not on the weapon choice; `generate --class 19` ran against the scaffolded file without error (298 scenarios: 221
  value, 145 passive, 33 hit, 1 melee), confirming the file is a valid `generate` input, not only a well-typed one.
- The weapon-selection rule and the `ItemLevel > 0` item rule remain stated defaults, not proven-correct choices;
  a future class whose scaffolded weapon turns out unusable (e.g. no `item_template` row survives the filter for
  any resolved subclass) raises `ScaffoldError` rather than silently picking something else, so that case is
  visible to whoever runs the next class's scaffold instead of being masked.
