# CoA class tooltip conformance

Python 3.11+ standard library only. Tools that check, per class, that spells behave as their client tooltip says.
Expected values come from the effective client DBC set (`/srv/coa/server-data/dbc`), never from server code.

## Modules

- `mitigation.py`: expected armor and partial-resist mitigation of a target.
- `classes.py`: `class_spells(dbc_dir, class_id, progression_header, level=60)` lists a CoA class's spells as
  `ClassSpell(spell_id, name, ranks, max_rank, required_level, passive)`; `class_skill_lines(dbc_dir, spells,
  weapon_subclass)` lists the `SkillLineAbility` lines of their ranks and of the weapon's skill spell.
- `tooltip.py`: `read_tooltip(dbc, spell_id, caster)` evaluates a spell's `Description[enUS]` with the caster's
  measured `CasterStats` and returns `Readout(values, unreadable)`.
- `profile.py`: the reference character of a class file and `base_steps(class_file)`, the steps every scenario starts
  with. Its name shadows the standard library `profile`: run the package from its own directory.
- `values.py`: `value_scenario(class_file, spell, rank_id)` returns the no-combat scenario of one rank and its
  `Expectation` list.
- `passives.py`: `passive_effects(class_file, spell)` classifies each effect of a passive into a family, its expected
  token, its metric plans and, for a spell modifier, its targets (see [Passive effects](#passive-effects));
  `passive_scenario(class_file, spell)` returns its with/without scenario, or `None` when no effect is measured, and
  its `Expectation` list (see [Passive scenario](#passive-scenario)).
- `hits.py`: `hit_parts(class_file, spell, casts)` returns the parts of the hit scenario of a spell's highest rank
  (`hit_scenario` the only part of a hit that fits one scenario) and `melee_scenario(class_file, swings)` the
  auto-attack scenario, with their `Expectation` lists; `expected_hit` and `casts_needed` give the expected mean, its
  sigma and the number of casts. When the highest rank targets a friendly unit (`values.targets_ally`), the scenario
  adds an `ally` player and casts at `target: 'ally'`, measuring the heal total/count without a `target` filter, so
  both the ally's and the caster's own heal land in the same metric. If the rank's own effects also close the
  distance to its target (`values.closes_distance`, a charge/leap effect such as Temple Guardian's), the scenario
  additionally relocates the caster `values.CHARGE_OFFSET_YD` yd before every cast (keeping it inside the spell's
  range of the stationary ally after the previous cast closed the distance, as `procs.py`'s own ally casts already
  do); a stationary ally heal with no such effect leaves the caster in place instead, since nothing would ever
  close a relocate's drift back.
- `procs.py`: `proc_scenario(class_file, entry, part)` returns one part of the proc-rate scenario of a `procs` entry
  and its `Expectation`; `proc_plan` sizes the parts, `trials_needed(p)` gives the trials a chance `p` needs and
  `wilson_interval(procs, trials)` the 99% Wilson interval of a rate.
- `triggers.py`: `trigger_scenario(class_file, entry, part)` returns one part of the scenario of a `triggers` entry and
  its `Expectation`; `trigger_plan` sizes the parts and `trigger_entries(class_file, auras)` selects the entries (see
  [Trigger entries](#trigger-entries)).
- `compare.py`: `compare(manifest, results_dir)` judges a run against the manifest and returns `Verdict(label, status,
  measured, expected, low, high, explanation)`; `write_outputs` writes `alerts.tsv`, `report.md`, `verdicts.json` and
  `questions.md`.
- `questions.py`: `questions(verdicts, tooltips)` turns the verdicts that carry a question into one `Question(tooltip,
  spells, kind, question, readings, measured, labels, conditions, observations)` per tooltip and kind, and
  `write_questions(items, out_dir)`
  writes `questions.md` (see [Open conformance checks](#open-conformance-checks)).
- `diff.py`: `diff(before, after, intended)` returns the `Change` of every verdict that moved between two compare
  outputs, and `write_impact` writes `impact.md` (see [Impact report](#impact-report)).
- `stack.py`: `stack_scenarios(class_file, passes=5)` returns the passes of every cumulative talent configuration of
  the class file with their `Expectation` lists; `levers(verdicts)` turns the stack verdicts into one `Lever(config,
  dps_mean, dps_low, dps_high, delta_pct, sources, tooltip_delta_pct)` per configuration; `mean_interval`,
  `ratio_interval` and `student_t_quantile` give the 99% intervals of the passes.
- `coverage.py`: `coverage(header, verdicts)` counts the verdicts per status and the class spells, passives and actives
  that a compare output judges (`Coverage`), and `write_coverage` writes `coverage.md` for two outputs (see
  [Coverage comparison](#coverage-comparison)).
- `observations.py`: `player_observations(class_file)` reads and validates a class file's `player_observations`
  array (see [Player observations](#player-observations)) and `observations_by_spell` groups them by spell id.
- `conformance.py`: the command line, `generate`, `compare`, `diff` and `coverage`.
- `classes/<name>.json`: one class file per class (`classes/templar.json`).

## Spell set of a class

- `CharacterAdvancementClassTypes.dbc` maps a class to its ClassType rows (`ClassID` matches and `CustomClass` is 1).
  ClassType is not ClassID: Templar is ClassID 19 and ClassType 21. Non-custom types, such as the shared ClassType 12,
  are never read for a CoA class.
- Every non-zero `RankSpell[0..4]` of the `CharacterAdvancement.dbc` rows of those types is one spell id (Templar: 172).
- `ranks` is the spell id followed by the spells that `src/server/coa/AscensionSpellProgressionData.h` chains to it
  (`{ClassId, FirstSpellId, SpellId, RequiredLevel}`); `max_rank` is the last rank whose required level is at most
  `level`. `required_level` is the `CharacterAdvancement` required level of the entry that holds the spell.
- `passive` is attribute bit 0x40 of the `Spell.dbc` record.
- `class_spells(..., extra_spells=())` adds base spells that `CharacterAdvancement` lacks (ADR 0016), with ranks
  from the same header and `required_level` the `Spell.dbc` `BaseLevel` of the base spell. A listed spell already in
  the set, listed twice or missing from `Spell.dbc` is an error. `generate` passes the class file's `extra_spells`;
  passive reference spells keep the `CharacterAdvancement` set.

### Extra class spells

A class file's `extra_spells` entry is `{"spell", "name", "citation"}`: the base spell id, its name and the citation of
one Ascension combat log event of the owner's private Ascension combat log archive where a player casts a rank of it
or holds its aura ([ADR 0016](../../../docs/adr/0016-conformance-class-spells-beyond-character-advancement.md) D2).
The citation is `<date> <time>, spell <logged id> <name>, Ascension combat log, private archive`, without character
names or raw lines, because the archive is private; the full lines stay in the gitignored
`.agents/plans/class-conformance-2/templar/extra-spells-evidence.md`. The log does not store a class, so the event
must come from a player who also casts a `CharacterAdvancement` active of the class in those logs.
`test_classes.py` checks the citation form, that the logged spell has the entry's name and is a rank of its chain
(Temple Guardian excepted, below), and that no spell is listed twice.

The candidates are the 34 Templar entries of `AscensionCompatData::ClassSpells`
(`src/server/coa/AscensionCustomClassData.h`, ClassId 19), none of them in `CharacterAdvancement`. Searched on
2026-11-06 by spell id, every rank of the progression header, and by name. 22 are confirmed and listed in
`classes/templar.json`: Righteous Lunge, Chastise, Gift of Zeal, Benediction, Libram of Consecration, Condemn,
Tranquil Circle, Harmonic Disposition, Testament of Faith, Holy Cleave, Beckon, Rebuke, Light's Hope, Spiritual
Ascension (a resurrection by its rank 500758), Tithe, Temple Guardian, Testament of Resolve, Libram of Grace,
Titanstrike, Crusader's Presence, Righteous Custodian and Shoot (a ranged hit; it needs a ranged weapon, so its hit
is `unmodelled`). Temple Guardian is logged at Rank 6 803796 (`Spell.dbc` `Rank[enUS]`, level 60), while the header
chains 801165 to Rank 2 803792 only, so the run judges Rank 2.

Righteous Tempest 805410 (`AscensionTemplarAbilities.cpp`'s `RighteousTempest()`, ranks 805410/570200-570205) is a
23rd `extra_spells` entry, logged at Rank 7 570205 (level 60); it is not one of the 34 `ClassSpells` candidates above
(round 3, 2026-11-08), so ADR 0016's citation mechanism applies to it independently of that candidate list.

Not confirmed, left out: Dodge 81, Block 107, Dual Wield 674, Auto Attack 6603, Resilient Constitution 552011,
Divine Stand 807729, Detect Evil 562226, Gift of Fervor 572629, Shackle The Unrepentant 560963, Greater Gift of Fervor
572630 and Greater Gift of Zeal 680306 (no log line), and Throw 2764 (cast only by players who cast no Templar
active).

## Tooltip reading

The rules follow the stock 3.3.5a client parser (wowdecomp `WoW/Source/Ui/QuestTextParser.cpp` and `MathState.cpp`,
evidence rather than authority). Each value is `Displayed(text, value, effect_index, kind, spell_id)`: `text` is the
token as written in the DBC, `value` the number before any player modifier.

| Token | Value | Kind |
|---|---|---|
| `$sN`, `$<id>sN`, `$SN` | `EffectBasePoints + 1`, unsigned, only if `EffectDieSides` is 1 | `percent` before `%`, or `flat` |
| `$mN`, `$MN` (with `<id>`) | `EffectBasePoints + 1`, `EffectBasePoints + EffectDieSides`, unsigned | as `$sN` |
| `$/N;` then `$sN`/`$SN`/`$mN`/`$MN` | divided by N; `$/1000;` followed by `sec` stays in ms | `duration_ms` or as `$sN` |
| `$d`, `$<id>d` | `SpellDuration` `Duration`, capped by `MaxDuration` | `duration_ms` |
| `$tN`, `$TN`, `$<id>tN` | the period of effect N (below), in ms; the client shows seconds | `amplitude_ms` |
| `$h`, `$<id>h` | `ProcChance` | `chance_pct` |
| `$u`, `$i` (with `<id>`) | `StackAmount`, `MaxAffectedTargets` | `count` |
| `$aN` (with `<id>`) | `SpellRadius` radius of effect N | `radius_yards` |
| `${...}` | `+ - * /`, parentheses and the variables below | as `$sN` |
| `$<name>` | a `SpellDescriptionVariables` formula of the spell it is scoped to (below) | as `$sN` |
| `$pplN`, `$<id>pplN` (inside `${...}` only) | `EffectRealPointsPerLevel[N-1] × max(0, caster level − BaseLevel)` | as `$mN` |

Inside `${...}`: `$mN`/`$MN` (signed), `$h $u $i`, `$d` in seconds, `$aN`, `$tN`/`$TN` the period in ms, each with
an optional spell id; `$pplN`/`$<id>pplN` (below); `$AP`, `$RAP`, `$PL`; `$SP` is the lowest spell power of schools
1 to 6, `$sph $spfi $spn $spfr $sps $spa` one school each; `$STR $AGI $STA $INT $SPI` the effective stats 0 to 4;
`$<name>` a variable defined earlier.
`$<name>` resolves against the `SpellDescriptionVariables` formula of the spell most recently named by a `$mN`/
`$MN`/`$sN`/`$SN`/`$aN`/`$tN`/`$TN`/`$<id>...` token earlier in the *same* `${...}` expression, or the described
spell when the expression has not named one yet (`Tooltip.variable`'s `context_spell_id`, cached per spell id in
`Tooltip.variable_cache` so a formula is compiled once even when several tokens reference it). Argent Blade/
Scourgebane 807268's `${$801832m1*$<scalingbp>+$sph*0.25+$AP*0.25}` names 801832 first, so `$<scalingbp>` resolves
801832's own `$scalingbp=${...}` formula (`SpellDescriptionVariableID` 182 on 801832, 0 on every Argent Blade rank
itself) instead of being unreadable for lack of a variable on the described rank.
`effect_index` is the effect of the first `$sN`/`$mN`/`$MN`/`$tN`/`$TN`/`$aN` of the spell itself in the token (for
`$<name>`, in its formula), otherwise `None`. `spell_id` is the spell of the first `$sN`/`$mN`/`$MN`/`$tN`/`$TN`/`$aN`
of the token, the described spell or another one, and `None` for a token without one (`$h`, `$d`, `$u`, `$i`). The
client reads `$D $H $U $I $AN $SN` as their lowercase forms (`$S` as `$s`: `QuestTextParser.cpp:829-834`), and so does
the reader.
The period of effect N is `EffectAmplitude[N-1]`, or 5000 ms when `ProcFlags & 1` (`QuestTextParser.cpp:977-1001`
for the text, `MathState.cpp:594-615` for expressions; the field is `m_effectAuraPeriod`, `SpellRec.h:78`). It is
unreadable in the text form when `AttributesEx5 & 0x2000` and not `AttributesEx3 & 0x20000000`: the client hastes
that shown period by the player's cast speed, which no metric reads; the expression form is never hasted
(`MathState.cpp`). A period of 0 is unreadable (`EffectAmplitude[N] 0 of spell S`). The client also applies the
player's period modifiers (`Spell_C_ModifySpellValue(..., 19)`); the reader gives the value before them. The
standalone `$tN`/`$TN` text form keeps its own effect's `effect_index`/`spell_id` (the periodic-total detection
below only applies to `EFFECT_KINDS` tokens, never to the period token itself); inside an expression it still
resolves through `math_variable` with both `None`, exactly like `$aN` there. Righteous Tempest 807274 reads `$t1` as
1000 ms, measured after a cast against the live `aura_amplitude_ms`; inside Blade of Faith 803880's
`${($d*1000/$T1)*(...)}`, `$T1` is 3000 and carries no `effect_index`/`spell_id`.
A standalone `$aN`/`$<id>aN` radius token keeps its own effect's `effect_index`/`spell_id` the same way, read
no-combat against `spell_effect_radius` (`SpellEffectInfo::CalcRadius`, no cast needed, unlike the period token).
A class file's `disabled_foreign_effects` list (`[{"spell": <id>, "effect": <n>, "reason": "..."}]`) names a
foreign effect that a class script zeroes at `SpellInfo` load time (`info->Effects[N].Effect = 0`), so raw DBC
alone cannot tell it apart from a live one; `foreign_radius` treats a listed pair as
`unmeasurable: effect <n> of spell <id> is disabled by a server correction` instead of generating a step that
would fail against the live server. Templar: Testament of Hope 1397742's `$704409a1` names effect 0 of 704409,
which `AscensionTemplarContracts.cpp:211` disables (effect 1, the one still applying the aura, carries the
identical `EffectRadiusIndex`).
Color codes `|c........` and `|r` are removed, in either case.

`@s:<id>:<flags>@` with `flags` 0 or more expands to the tooltip of spell `<id>`, read by a nested reader of that spell
([ADR 0013](../../../docs/adr/0013-conformance-expands-spell-markup.md)). The header line the client draws before it
(icon and spell name) holds no number. The expanded tokens join `values` at the markup's place, with their own
`text`, `effect_index` `None` and `spell_id` the spell they read: the referenced spell for its own tokens and for
`$d $h $u $i $aN` without an id, the named spell otherwise. Zealotry 92108 thus shows `$s2` 80 of 801450. Their
unreadable parts join `unreadable`. A markup stays unreadable, with its reason, when its flags are negative (the
shift-reveal and partial renderings), when the spell is missing from the DBC set, when it closes a cycle, and when
the nesting is deeper than `MAX_EXPANSION_DEPTH` (3) expansions. A referenced tooltip without a token adds nothing:
Sacred Oath 712346 is then a tooltip without value.

Everything else goes to `unreadable` verbatim and is never guessed: `$?` conditionals, other `@...@` markup, other `|`
escapes, other tokens (`$o`, `$x`, `$l`, `$g`...), expression functions and variables such as `$BH` or lowercase
`$ap`, durations that scale with level (`DurationPerLevel` not zero), points that scale with level when the skill
rank cannot be read (see below), spread values (`EffectDieSides` not 1 for `$sN`), missing records, non-positive
durations, a `$<name>` whose spell (the one it is scoped to, above) has no `SpellDescriptionVariables` formula of
that name, and a stat or school missing from `CasterStats`.

### Level-scaled points

Points with a non-zero `EffectRealPointsPerLevel` read `EffectBasePoints + 1 + EffectRealPointsPerLevel ×
max(0, level − BaseLevel)` (`BaseLevel` subtracted only when positive), as the CoA client binaries compute them
([ADR 0014](../../../docs/adr/0014-level-scaled-tooltip-values-use-the-skill-rank.md), superseding ruling R6 of
ADR 0011). The level is not the character level. `client_spell_level(records, spell_id, caster)` is the skill rank
divided by 5 (integer), and the rank is computed as follows:

- `rank_spell`: a spell with `EquippedItemClass` 2 takes its rank from the weapon-skill spell of the equipped
  weapon (`CasterStats.weapon_subclass`), when the subclass is in its mask and `Targets & 0x10`,
  `AttributesEx2 & 0x8000000` and `Effect[0]` 25 do not exclude it. `weapon_skill_spells(records)` is the client's
  subclass → spell table (Staves: 10 → 227).
- `ability_line`: the `SkillLineAbility` line of that spell for the character's `race` and `class_id`. A row
  counts when `CharBaseInfo` holds the pair, a `SkillRaceClassInfo` row of its line allows it, and the row's
  `RaceMask`/`ClassMask` (inverted by `ExcludeRace`/`ExcludeClass`) allow it. Without a row the rank is 0. Staves
  227 allows only classes 10, 25, 26 and 29, so a Templar's staff spells (Reckoning) read rank 0.
- the rank is `CasterStats.skills[line]`, capped at 5 × `MaxLevel` of the spell it comes from.

Each point is read at the level of the spell it belongs to: the CoA `Extensions.dll` sets the described spell's
level to 0. Staffguard 705295 thus shows `$706583m1` at the rank of 706583, which has no ability row: 125. The
exception is a `$<id>sN` text token whose spell has `AttributesEx2 & 0x1000000`: it uses the character level,
capped at a positive `MaxLevel`.

The entry stays unreadable and names its field and the cause in three cases: the skill line is not measured
(`${$m3+0+$SP*1+$AP*.55} [EffectRealPointsPerLevel[2] of spell 807805: skill 72 is not measured]`), the race or
class is unknown, or several ability lines match. The client adds a temporary skill bonus to the rank;
`skill_value` reads the pure value, and no metric reads that bonus.

### Per-level points (`$pplN`)

`$pplN`/`$<id>pplN` is only ever found inside a `${...}` expression (never as a standalone text token) and reads
`Tooltip.per_level_points`: `EffectRealPointsPerLevel[N-1] × max(0, caster.level − BaseLevel)`, `0` when
`EffectRealPointsPerLevel` is `0`. Unlike `$mN`/`$sN` above, the level it scales by is the **caster's actual
level** (`CasterStats.level`), not `client_spell_level`'s skill-rank-derived level
([ADR 0031](../../../docs/adr/0031-ppl-tokens-scale-by-actual-level-not-skill-rank.md), which does not reopen
[ADR 0014](../../../docs/adr/0014-level-scaled-tooltip-values-use-the-skill-rank.md): `$mN`/`$sN` keep reading the
skill rank). This followed from evidence, not from the token's name alone: none of the custom Templar spells that
carry a `ppl` token have a `SkillLineAbility` row, so `client_spell_level` always resolves to 0 for them and the
skill-rank reading would make every `$pplN` term 0 regardless of `EffectRealPointsPerLevel`. Two of the
2026-11-07 player tooltip readings (Libram of Consecration 801441/803890-803893 and Eternal Blessing 705300) carry
no `$AP`/`$sph` term, so their reported number is a direct check of `$pplN` alone at AP/SP-independent faces;
Libram's reported 188 matches `EffectRealPointsPerLevel × (60 − BaseLevel)` exactly (`4.0 × (60 − 18) = 168`, `+20
= 188`) and would not match a skill-rank reading (which gives 0). `player_tooltip_readings` (below) carries this
citation.

### `$<name>` resolved against the spell it names

`$<name>` used to resolve only against the *described* spell's own `SpellDescriptionVariables` formula, so
Argent Blade/Scourgebane's `${$801832m1*$<scalingbp>+$sph*0.25+$AP*0.25}` stayed unreadable: `scalingbp` is
defined on 801832 (`SpellDescriptionVariableID` 182), not on the described rank (0 on every Argent Blade rank).
The formula text itself already names 801832 first (`$801832m1`), so `ExpressionParser` now tracks the most
recently named spell within the expression and resolves `$<name>` against *that* spell's formulas instead,
falling back to the described spell when none has been named yet (see the token table above).

Known divergence: the reader reads the client DBC, which is what players' tooltips show unless the client is
patched. The server can override a description: `rev_20261029_240_templar_untainted_tooltip.sql` gives Untainted
705298 `${-$705299m1+$STA*0.1}` through `coa_client_spell_description`, while the client DBC reads
`${$705299m1+$STA*0.1}`; the comparison follows the client DBC
([ADR 0014](../../../docs/adr/0014-level-scaled-tooltip-values-use-the-skill-rank.md)). A class script can
similarly correct a live `SpellInfo` effect without changing `Spell.dbc` at all: Upheave! 520442 effect 0 is
`EffectMiscValue[0]` 7 in the client DBC, but `AscensionTemplarContracts.cpp:130` rewrites it to 15 at load time;
the class file's `effect_overrides` entry (see "Effect overrides" below) makes the reader classify the effective
op instead of the raw DBC one.

## Reference character

`classes/<name>.json` holds `class_id`, `name`, `race`, `level`, `weapon` (`item`, equipment `slot`, 15 is the main
hand, `subclass` from `Item.dbc`: 10, a staff, for the Walking Stick), `skill_lines` (`class_skill_lines` of the class
spells and the weapon: Templar 70, 71, 72 and 136), `ratings` (fixture hit and expertise ratings, so that an aura or hit
is never lost to a miss; they do not change a tooltip value), `reference_stats`, `known_auras`, `probe_auras`, `procs`
(see [Proc rates](#proc-rates)) and `talent_modifiers`, `rotation`, `stack`
(see [Talent stack](#talent-stack-lever-map)), `alternate_weapons` and `extra_spells`
(see [Extra class spells](#extra-class-spells)). The Templar reference is a human with the
Walking Stick (item 2495).

`weapon` also freezes the `item_template` row of the weapon: `min_damage` (`dmg_min1`), `max_damage` (`dmg_max1`),
`speed_ms` (`delay`), `inventory_type` and `normalized_speed`, the speed `Unit::GetAPMultiplier` uses for normalized
weapon damage (3.3 for a two-handed weapon, inventory type 17). Walking Stick, read on 2026-11-05 from `acore_world`
in the in-RAM test database with `SELECT dmg_min1, dmg_max1, delay, InventoryType FROM item_template WHERE entry =
2495`: 6.5625, 10.9375, 2500, 17. With 313 attack power, 6.5625 + 313 / 14 x 2.5 = 62.455 is the measured
`weapon_damage_min`. `reference_stats` holds the `base_steps` values measured on the naked reference character (Templar:
2026-11-05, `.cache/verify-all/20261105-181206`; the skills on 2026-11-06, `.cache/verify-all/20261106-122106` and
`20261106-122142`: `skill_value` 300 on lines 70, 71, 72 and 136 after `set_skill` 300/300); they size the scenarios,
and the comparison uses the values measured in the run.

`alternate_weapons` lists other reference weapons with the same fields plus `skill_line`, the `SkillLineAbility` line of
the weapon-skill spell of their subclass (owner answer Q9: a second, one-handed reference weapon). A rank whose
`EquippedItemClass` is 2 and whose `EquippedItemSubClassMask` or `EquippedItemInventoryTypeMask` excludes `weapon`
(`unfit_reason`, the checks of `Item::IsFitToSpellRequirements`) takes the first alternate weapon that fits:
`armed(class_file, requirement)` returns the class file with that weapon, its skill line added to `skill_lines` and
`skill <line>` added to `reference_stats` at 5 × level. The value scenario, its generated tokens, the hit scenario and
the comparison of that rank use it; the hit rule names it (`reference weapon 2259 (EquippedItemSubClassMask 41105
excludes the reference weapon subclass 10)`). Without a fitting weapon the hit is `unmodelled` with that reason. The
Templar one-hand weapon is the Frostmane Club (item 2259), a white one-handed mace of item level 6 and required level 3
like the Walking Stick, without stats or spells, read on 2026-11-06 from `acore_world` in the in-RAM test database with
`SELECT class, subclass, Quality, dmg_min1, dmg_max1, delay, InventoryType, RequiredLevel, ItemLevel FROM item_template
WHERE entry = 2259`: 2, 4, 1, 3.45, 5.75, 2000, 21, 3, 6; `Item.dbc` gives subclass 4, inside the mask 41105 of
Vindication 573324 and Righteous Upheaval 501562, its normalized speed is 2.4 (`Unit::GetAPMultiplier`, a one-hand
weapon that is not a dagger), and the Maces skill spell 198 is on line 54. One-Handed Maces (skill 54, spell 198) is a
Templar proficiency in `AscensionLiveBaselineData.h` (`Proficiencies`) and `AscensionCustomClassData.h`
(`ClassProficiencies`).

`base_steps` waits 5 s, adds and equips the weapon, sets each line of `skill_lines` to 5 × level with `set_skill`
(value and maximum: 300 at level 60, owner answer Q4) and measures it back with `skill_value` (label `skill
<line>`), then measures with the extreme bounds of an exploratory measurement (the judgement is made by the
comparison, never by the scenario): `attack_power`,
`ranged_attack_power`, `spell_power 1`..`6`, `stat 0`..`4`, `weapon_damage_min`, and one `aura` per entry of
`known_auras` (label `known_aura <id>`) and of `probe_auras` (label `probe_aura <id>`). `caster_stats_from(measured,
class_file)` rebuilds the `CasterStats` that `read_tooltip` needs from those labelled values, the class file's level,
race, class and weapon subclass, and the measured skills.

A naked level-60 Templar knows no class spell and carries one class aura: measured on 2026-11-05 on the worldserver of
the worktree, `knows_spell` is 0 for all 221 spell ids of the class and `aura` is 1 only for the class tuning aura
887007 (887043/887044/887045, the spec auras, and the passive Scourgebane 92111 read 0). `known_auras` therefore lists
887007 only; Scourgebane is in `probe_auras`, which is measured and reported but never explains a deviation.

## No-combat scenario of a rank

`value_scenario` returns a schema 1 scenario of one rank and its `Expectation(label, check, spell_id, rank_id,
effect_index, displayed, rule)` list. `label` is also the label of the measurement step, and is unique in the scenario.
`displayed` is the token as written in the DBC: the comparison reads the tooltip again with the measured caster
stats, since the value depends on them. The scenario learns the rank, then measures (assertions with extreme bounds):

| `check` | Measurement | Expected from |
|---|---|---|
| `effect_value` | `spell_effect_value` of the token's effect | the tooltip token (`rule` `read <kind>`) |
| `effect_value` of another spell | `spell_effect_value` of the effect of the token's first `$<id>sN`/`$<id>mN`, `model` `{'effect_spell': id, 'effect': n}` | the tooltip token, label `<rank> effect_value <id>e<n> #<ordinal>` |
| `max_stacks` | `spell_max_stacks` of spell `<id>` of a `$<id>u` token, `model` `{'effect_spell': id}` | `StackAmount` of that spell, compared exactly |
| `spell_duration` | `spell_duration_ms` of spell `<id>` of a `$<id>d` token, `model` `{'effect_spell': id}`, label `<rank> spell_duration <id> #<ordinal>` | the token: `Duration` of that spell, capped by `MaxDuration` |
| `power_cost` | `spell_power_cost` before any cast | `ManaCost` divided by the client display divisor of the power type (1, 10 rage and runic power, 1000 happiness) |
| `cooldown_ms` | `cooldown_ms` right after the cast | `max(RecoveryTime, CategoryRecoveryTime)`, as the client tooltip |
| `aura_amount` | `aura_amount` of the effect after the cast | the same tooltip token as `effect_value`, for an effect that applies an aura |
| `aura_duration_ms` | `aura_duration_ms` after the cast | the `$d` token of the rank, for an instant spell that applies an aura |
| `known_aura` | `aura` before any learn | the class file; the aura's own tooltip gives its modifier |

A rolled effect (`EffectDieSides` neither 0 nor 1) of an own or foreign `effect_value` is read k times: the step
`<label>` and its copies `<label> sample <n>` for n = 1 .. k - 1, each one `CalcValue` roll. k is the hit-mean count
`ceil((Z x sigma / (1% x |mean|))^2)`, Z 2.576, with the mean and the population sigma of the token read once per
roll (`ForcedPoints`) at the structure stats, and is kept as `model['samples']`. The copies must fit in what the
other steps leave of the harness's 10000-step limit (`MAX_SCENARIO_STEPS`, `run.py` `validate`) and in 1800 reads
(`READ_BUDGET_MS` 45 s, half the 90 s default `timeout_ms`, at `READ_STEP_MS` 25 ms, the largest step of the
simulated clock; the harness runs one step per world update); otherwise the effect is read once and its verdict is
`measured`. Templar: 51 rolled tokens, 2 to 1716 reads (Vindication 501589 102, Reckoning 572741 366).

A token without an id names the spell whose tooltip holds it: for a token of an expanded `@s:` tooltip that is the
referenced spell, so its `$sN`, `$u` and `$d` are checked as tokens of another spell (Zealotry 92108 `$s2` is
`effect_value` of 801450 effect 1; Glory 801481 checks its own `$d` as `aura_duration_ms` and the `$d` of Downfall
801482 and Redemption 801483 as `spell_duration`). The sign of an unsigned expanded token comes from the referenced
spell's points.

The cast, when a cooldown or an aura is measured, targets the fixture creature `dummy` (entry 36) when an active
effect has an enemy target (implicit targets 2, 6, 15, 16, 24) and the caster otherwise; an aura whose target is the
caster is read on the caster. A cost in a power other than mana is set to its cost before the cast. A rank whose
record names a `CasterAuraSpell` gets that aura as a one-stack fixture (`set_aura`) right before the cast: without it
the server refuses the cast with `SPELL_FAILED_CASTER_AURASTATE` (22, `Spell.cpp:5930`). Templar: Oath Chain 704576
for Righteous Upheaval, Blade of Faith, Righteous Tempest and Reckoning; Recently Parried or Dodged 681170, a dummy
aura, for Sacred Swing. Two diagnostic measurements ride along without an `Expectation`: `<rank> cast_failure` and
`<rank> aura_present`.
The remaining aura duration is read in the cast step's own tick: measured 12 to 15 ms below the record on instants.
`cooldown_ms` is the remaining cooldown, measured 6 ms below the record right after the cast.
A rank whose record names a `TargetAuraState` gets a health fixture on its hostile target before the cast
(`required_target_health_steps`, `values.py`): `AURA_STATE_HEALTHLESS_35_PERCENT` (13) sets the target to 30% of its
max health, strictly below the 35% gate and above any lower-threshold check that might also apply, then waits 1000
ms for `Unit::Update` to recompute the derived aura state flag. Without the wait the cast can still see the stale
flag and fail `SPELL_FAILED_TARGET_AURASTATE` (111). An unmapped `TargetAuraState` is `unmodelled: target aura state
<n> has no scenario fixture`, never silently skipped. Templar: Titanstrike 806521/806834/806835.

A value that cannot be compared is never dropped; its `rule` starts with a stable prefix:
`unreadable: <entry>` for a part the reader could not evaluate (the scenario measures the spell's first active effect
beside it, which is not the token's own effect), `unreadable: tooltip without value` for an empty readout,
`unreadable: ManaCostPercentage ...` or `unreadable: ManaCostPerlevel ...` for a cost the DBC alone does not give, and
`unmeasurable: <reason>` for a readable token with no no-combat metric (a periodic total or `mixed` token left to
the hit scenario, a chance token, an aura of a passive or cast-time spell, a foreign amplitude or an amplitude of a
passive effect, another spell's effect or radius that `Spell.dbc` does not define or that `disabled_foreign_effects`
names, which `spell_effect_value`/`spell_effect_radius` refuse). Only `unmeasurable` expectations may lack a
measurement step. The rank's own radius (`$aN`), own period (`$tN`/`$TN` after an instant cast) and own stack count
(`$u`) are measured, through `spell_effect_radius`, `aura_amplitude_ms` and `spell_max_stacks`; `$i`
(`MaxAffectedTargets`) still has no no-combat metric.
`$<id>h` stays `unmeasurable: chance_pct token ...`: `spell_proc_chance` needs a `spell_proc` row of that spell, so
no step reads it. A `$/1000;sN sec` token (own or of another spell) is an `effect_value` in ms: Liberty 705266
`$/1000;s1` expects −30000. A `$<id>d` token of another spell is a `spell_duration`, read without a cast: Keeping
the Oath 92109 `$803237d` expects 8000. The reader leaves a token of a spell missing from the DBC set unreadable,
so a step names only spells of that set; a spell the server's store lacks still fails its scenario (`Unknown
spell in metric`). `spell_duration_ms` is the base duration after the player's spell modifiers, before script
hooks: every `spell_duration` verdict carries that limit in `detail['scope']`.
Known limit: a duration that a `ScriptMgr::OnCalcMaxDuration` script changes (`Aura::CalcMaxDuration`,
`SpellAuras.cpp:815`) is not covered, so such a spell needs a cast-based `aura_duration_ms` check instead.
`spell_effect_value` is `SpellEffectInfo::CalcValue`, before aura scripts: every `effect_value` verdict carries
`detail['scope']` "CalcValue before aura scripts (CalcAmount hooks not covered)". Known limit: an amount that an
AuraScript `CalcAmount` hook sets is not covered, so a passing value can still differ from the applied aura, and a
failing one can be an artifact of the metric. An `aura_amount` check on a present aura is the remedy. Staffguard
706583: `AscensionTemplarAuras.cpp:60-63` sets the applied amount to 125 + 0.3 × Stamina + 0.25 × (dodge + parry
rating), the 125 base the client shows, while CalcValue gives 305.

## Passive effects

`passive_effects(class_file, spell)` classifies every effect of a passive's rank at the class level as
`PassiveEffect(spell_id, effect, aura, misc, misc_b, family, token, plans, targets, reason, points)`. It measures
nothing:
the scenarios and the judging build on it. `reason` starts with `unmodelled: ` for an unmodelled effect, which then
has no `plans`; it names the distinguishing marker below for an effect modelled through `aliased_token`, and is
empty for every other modelled effect.

Family by `(Effect, EffectApplyAuraName)` (`FAMILIES`, `family_of`): effect 3 (dummy) is `P6` whatever its aura;
otherwise the aura decides, and an aura absent from the table is `unknown` (`unmodelled: aura <n> has no passive
measurement`, or `unmodelled: effect <n> applies no aura` for aura 0).

| Family | Auras | Templar effects |
|---|---|---|
| `P1` spell modifier | 107, 108 | 71 |
| `P2` stat sheet | 29, 31, 47, 49, 132, 133, 137, 138, 142, 166, 167, 174, 220, 237, 240, 290, 327, 333 | 51 |
| `P3` done / received | 59, 79, 118, 122, 136, 163, 286, 303 | 9 |
| `P4` taken | 87, 229, 283 | 4 |
| `P5` proc / trigger | 23, 42, 231, 354 | 76 |
| `P6` scripted / crowd control | 4, 112, 178, 232, effect 3 | 21 |
| `P7` power | 72, 110 | 2 |

The expected value is the effect's own token (the first token of the passive's own tooltip whose `effect_index` is
the effect). An effect without one takes a sibling effect's plain `$sN` (or `$/N;sN`) token when both effects have the
same displayed points (`|EffectBasePoints + 1|`, single-valued): Sturdy 681009 effect 1 (Energy) shares `$s1` of
effect 0 (health), and Paladin Training 520009 effect 1 (cost, −20) shares `$s1` (+20) of effect 0, since the tooltip
says "Increases the damage and reduces the Energy cost ... by $s1%". `token.effect_index` then names the sibling.
A token's `value` is unsigned; `points` is the effect's own signed `EffectBasePoints + 1` (`None` when its points
scale with level), so the expected value is `token.value` with the sign of `points` (520009 effect 1: −20).
Otherwise: `unmodelled: no own token and no sibling token with equal points` (Graceful Fighter 705303 effect 2 has 0
points beside 20 and 20). On Templar, 18 effects share a token; 16 of them are modelled (Courage's two aura 31
effects stay unmodelled).

An effect whose points disagree with every sibling's own token can still be modelled when the tooltip's own
authoring reuses a sibling's literal `$sN` token verbatim for this effect's clause, rather than giving this effect
its own number at all (`aliased_token`): the sibling's token text must recur in a second sentence of the tooltip
(`SENTENCE_BREAK`-split), not merely a second time anywhere in the text, so a token legitimately repeated twice
within its owning effect's own clause is never mistaken for a second effect's clause. The expected value is then
that sibling's own signed points, not this effect's own (never displayed) raw `EffectBasePoints`: Fortified Body
300515 effect 1 (max health, raw points 10%) reuses effect 0's `$s1` (6%) for its own "increases your maximum
health by $s1%" sentence, so the expected value is 6%, matching both the client's rendered tooltip and CoA's own
`AscensionTemplarContracts.cpp` load-time patch of effect 1's `BasePoints` down to effect 0's value. `reason` then
reads `token <text> reused from effect <sibling>; expected value follows effect <sibling>, not own points`, so a
reviewer can tell this path apart from a directly-owned or evenly-shared token without reading the source.

Each `MetricPlan(metric, fields, relation, source, judged)` names a harness metric, its fields (the scenario adds
`spell` where the metric needs one), the relation of the delta to the token, for `share` the base-step label of the
source (`stat <n>` or `attack_power`), and whether the delta is judged (`judged` false: reported as `measured`):

| Aura | Plans | Relation |
|---|---|---|
| 107 / 108 | `spell_modifier {op, base: 1000}` per target; consumer of the op: 14 `spell_power_cost`, 10 `spell_cast_time_ms`, 5 `spell_max_range`, 31 `spell_max_stacks`, 3/12/23 `spell_effect_value {effect: 0/1/2}`, 7 `spell_done_crit_chance {target: dummy}`, 15 `spell_critical_damage {target: dummy}` | `spell_mod_flat` / `spell_mod_pct`; consumer `add` / `scale`, op 15 `crit_damage` |
| 29 / 137 | `stat {stat}`, all five for misc −1 | `add` / `scale` |
| 133, 132, 166, 167 | `max_health`, `max_power {power}`, `attack_power`, `ranged_attack_power` | `scale` |
| 240, 47, 49 | `expertise`, `parry_chance`, `dodge_chance` | `add` |
| 290 | `spell_crit_chance {school}` when the tooltip says "<School> critical strike chance"; else `melee_crit_chance_refreshed` plus `spell_crit_chance {school}` for schools 1 to 6 with `judged` false (D6) | `add` |
| 333 | `melee_hit_chance` and `spell_hit_chance` | `add` |
| 138 | `attack_time_ms {hand: 0}` | `haste` |
| 220 | `combat_rating {rating}`, one per bit of the misc mask | `share` |
| 174 / 237 | `spell_power {school}`, one per magic school of the misc mask | `share` |
| 327 | `stat {stat}` | `share` |
| 79 | `spell_damage_done {target: dummy}` (magic schools in the mask); physical: `weapon_damage_min {hand: 0}` | `composition`; physical `ratio` |
| 136 | `spell_healing_done {target: caster}` | `composition` |
| 118 | `spell_healing_taken {target: caster}` | `ratio` |
| 163 | `spell_critical_damage {target: dummy}` | `crit_damage` |
| 303 | `spell_damage_done {target: dummy}` | `ratio` |
| 229 | `aoe_damage_taken {school}`, one per school of the mask | `ratio` |
| 72 | `spell_power_cost` | `scale` |

The physical part of aura 79 enters the weapon damage (`Unit::UpdateDamagePctDoneMods`, `TOTAL_PCT` of the hand's
damage modifier), and `Unit::MeleeDamageBonusDone` skips aura 79 for a physical school mask (`Unit.cpp:11419`):
`melee_damage_done` stayed 800 → 800 with Serendipity 300929 learned, so the physical part is measured on
`weapon_damage_min` (`UNIT_FIELD_MINDAMAGE`, the character sheet's minimum damage).

A `composition` or `crit_damage` relation can read as more than one quantity (the bonus "multiplies" or "adds" to
known modifiers; a critical-hit percent applies to the "whole" hit or only to the "bonus" above the fixed base),
but only one of those readings is ever physically possible for a given effect's own mechanism, so `delta_readings`
gates each alternate on `model['aura']` instead of always offering it: a `composition` known modifier only offers
"adds" when its own `aura` (carried on every `known_modifiers` row) equals the effect's own `aura` — a known
modifier of a different aura can never enter the same `Unit::GetTotalAuraMultiplier` call as the effect under
test, so it cannot compose additively with it (Serendipity 300929's aura-79 effect against the Ascension tuning
aura's 341, `Unit::GetAscensionNormalTuningDamageMultiplier` and `Unit::SpellDamageBonusDone`,
`Unit.cpp:9284-9296, 9914-9930`). A `crit_damage` effect offers "whole" only for a direct aura 163 application
(`Unit::SpellCriticalDamageBonus`, `Unit.cpp:10527-10561`: aura 163's own percent scales the pre-subtraction value);
every other `crit_damage` plan — the spell-modifier op 15 consumer below — offers "bonus" only, since
`ApplySpellMod(..., SPELLMOD_CRIT_DAMAGE_BONUS, crit_bonus)` runs only on the bonus-above-base portion.

### Effect overrides

A class file's `effect_overrides` list (`[{"spell": <id>, "effect": <n>, "misc_value": <n>, "citation": "..."}]`)
substitutes a live-corrected `EffectMiscValue` for the raw client DBC value before `classify` builds any plan, the
same `{spell_id or rank_id, effect}` lookup as `passive_targets` (point 3 above). A class script can rewrite a
spell's effective `SpellInfo` at load time without changing `Spell.dbc`, so the raw DBC op the reader would
otherwise classify by was never the one actually registered. Templar: Upheave! 520442 effect 0 carries
`EffectMiscValue[0]` 7 (`SPELLMOD_CRITICAL_CHANCE`) in the client DBC, but `AscensionTemplarContracts.cpp:130`
rewrites it to 15 (`SPELLMOD_CRIT_DAMAGE_BONUS`) at load time to match its own "critical damage" tooltip wording;
the `effect_overrides` entry makes the reader classify it as op 15 (`spell_critical_damage`/`crit_damage`, the
"bonus" reading above), the op the live server actually installs.

Unmodelled by rule: `P5` (`proc or trigger effect without a trigger entry`), `P6` (`scripted or crowd-control
effect`), 142 (`mail armor is out of scope`, owner ruling), 59 (`damage versus a creature type is level-scaled`),
122 (`no off-hand weapon damage metric`), 110 (`no energy regeneration metric`), a spell modifier op of 32 or more
(`SpellModOp <op> is not below MAX_SPELLMOD 32`: `spell_modifier` requires `op < MAX_SPELLMOD`), and the auras of the
table without a plan (31, 87, 283, 286: `aura <n> has no passive measurement`).

### Targets of a spell modifier

1. Named: every `Spell.dbc` record of the passive's `SpellFamilyName` whose `SpellName[enUS]` appears in the tooltip
   (color codes removed, whole words, longest names first, overlapping matches skipped: "Oath: Condemn" before
   "Condemn"). A match followed by a space and a capitalised word is part of a longer proper noun and does not
   count: the spell "Oath" is not named by "Oath Breakers" (Blessed Strikes 704180, Chakra of Light 803159). A name
   inside a counter clause ("per trigger of", "per stack of", "per charge of", "for each time you triggered") is
   blanked out before matching and never counts as named: Holy Upheaval 572547's "Increases the effectiveness
   Righteous Upheaval gains per trigger of Zealotry by `$s1`%" grammatically raises Righteous Upheaval's own value,
   with Zealotry only the counted trigger, so Zealotry is not a target at all, named or otherwise
   (`without_counted_names`). Names are read in the sentence that holds the effect's token when the token sits in
   one sentence that names a spell, else in the whole tooltip (ADR 0017 D3: Legacy of the Silver Hand's `$s2`
   sentence names Scourgebane only). A named spell whose records meet this effect's mask has those records as
   targets, resolved to the ranks the class level reaches, records outside a chain all kept (ADR 0017 D1: Pure
   Focus 705253 on Scourgebane 520007, not
   92111, 801832, 801861 or 804916; Argent Knight 300512 on Righteous Tempest 570200 to 570205 and 805410, not the
   aura 807274). A named spell with no record in this mask but one in a sibling spell-modifier effect's mask is that
   effect's target only (D2: Grace of Aman'thul's effect 1 takes Sacred Swing, not Righteous Lunge). Otherwise a
   named spell resolves to its rank at the class level through the chains of `AscensionSpellProgressionData.h`
   (Righteous Lunge → 570233, Argent Blade → 807268), else to every record of that name, outside the mask.
   `named_targets(records, family_name, text, level, in_mask, sibling_mask)` returns them. A named spell neither
   in this mask nor in a `P1` sibling's gets a `passive_targets` entry instead (Pious Sweep 520034 effect 1 names
   Chastise, whose own flags never meet the mask; the mask's real target is Tranquil Circle 801205, each a
   separate half of the tooltip sentence. Templar's Might 705291 effect 0 names its four boosted abilities, but
   the mask belongs to Condemn 567539, the stacking debuff that gates the boost).
2. Category: when nothing is named and the first capitalised word (four letters or more) of every name the class
   mask matches is in the tooltip ("Libram spells": Libram of Tenacity, Libram of Zeal, ...), the mask's spells are
   the targets.
3. Class file `passive_targets` overrides both: `{"spell", "effect", "targets": [ids], "tooltip_words": "..."}`
   (`spell` is the passive's spell id or its rank at the class level); the quoted words must be in the tooltip,
   else `ValueError`.
4. Otherwise `unmodelled: the tooltip names none of the spells the class mask affects (<names>)`. Templar: Deep
   Secrets 705263, Mark of Aggramar 804928 and Chakra of Light 803159/803844 say "Testaments" while their masks
   also match Ascetic and Mortal Abdication; Blessed Strikes 704180 says "Oath Breakers" while its mask matches
   Benediction, Blade of Faith, ... (no name starts with "Oath"). These have a `passive_targets` entry
   (`classes/templar.json`): Blessed Strikes' own `Description[enUS]` of each of the 10 mask-matched spells
   carries "Oath"/"Oaths", the in-fiction label `category_holds` cannot see because it only checks a candidate's
   `SpellName`.

`PassiveTarget(spell_id, name, named, in_mask)`: `in_mask` is whether the record's `SpellFamilyFlags` meet the
effect's `EffectSpellClassMask`. Mask spells whose name is not matched are listed too (`named` false, one rank per
name, selected by id), so a disagreement stays visible: Patience 712678 names Interdict 560116 (outside the mask)
while its mask matches only Sacred Restraint 102208.

### Phrase check

Every plan outside `P1` has a quantity, and the tooltip must contain one of its `PHRASES` (case-insensitive):
"parry rating", "Holy critical strike chance", "chance to hit", "maximum health", "Energy", "melee haste",
"expertise", "attack power", "spell power", "Holy spell damage", "damage taken from area of effect", "cost", ...
Missing: `unmodelled: the tooltip does not name <quantity>` (Call of the Monastery 560550 effect 1 is ranged attack
power, its tooltip says "attack power"). For `share`, `stat_after_token(text, token)` reads the stat or "attack
power" written after `<token>% of (your)`; the source comes from the tooltip, not from `EffectMiscValueB`, so a
mismatch shows as an alert when judged. No such words: `unmodelled: the tooltip names no stat or attack power after
<token>% of`.

### Passive scenario

ADR 0012 records the method. `passive_scenario(class_file, spell)` measures every plan of every modelled effect of
the passive's rank at the class level (`spell.max_rank`) twice in one no-combat scenario:

1. `base_steps(class_file)` (fixtures, stats, known and probe auras);
2. each measurement labelled `<passive> e<n> <metric> <target> before`;
3. `learn` the passive, then `aura` of the passive labelled `<passive> aura_present` (diagnostic);
4. the same measurements labelled `<passive> e<n> <metric> <target> after`.

`<target>` is the spell the metric is asked about, else the values of the plan's fields other than `target`
(`706431 e0 stat 0 before`, `705303 e0 combat_rating 3 after`, `561346 e1 expertise before`). A spell modifier and
its consumer metric (`spell_power_cost`, `spell_effect_value`, `spell_done_crit_chance`, ...) are measured on every
target of the effect, named or mask-only. A spell-bound metric without targets (`spell_damage_done`,
`spell_critical_damage`, `spell_healing_done`, `spell_healing_taken`, `spell_power_cost` of aura 72) is measured on a
reference spell: the first active class spell, at its rank for the class level, whose `SchoolMask` meets the effect's
mask (`EffectMiscValue`; its magic part for aura 79; every school for aura 303, whose misc value is an aura state)
and that has a school damage effect (2) for damage, a heal effect (10) for healing, or a plain cost (`ManaCost` above
0, no per-level or percentage cost) for the cost. Templar: Reckoning 572741 for Serendipity 300929 and Chivalric
705272, Crusader's Brand 300513 for the cost of Serendipity. The scenario adds the dummy creature when a measurement
targets it.

Expectations, one per measured pair: label `<passive> e<n> <metric> <target>`, check `passive_delta`, `displayed` the
token text, `rule` the plan's relation, and `model` with `family`, `effect`, `metric`, `fields` (the step's fields,
`spell` included), `relation`, `source_label` (the base-step label of a `share` source), `before_label`,
`after_label`, `target` (the spell measured, else `None`), `named` and `in_mask` (spell modifier targets, else
`None`), `points` (the effect's own signed points), `judged` and `aura_label`. Not measured, check `unmodelled`:

- an effect without plans: one expectation labelled `<passive> e<n>` with the effect's reason (Condemnation 704175
  effect 1, op 40: no step is generated);
- a target without the effect a `spell_effect_value` consumer reads: `unmodelled: target <id> has no effect <n>`
  (the harness would stop the scenario);
- a target of a `spell_power_cost` consumer with no plain cost (`ManaCost`, `ManaCostPerlevel` and
  `ManaCostPercentage` all 0): `unmodelled: target <id> has no power cost to modify` (`CalcPowerCost` clamps a
  negative cost to 0, so a flat reduction on a 0-cost target would measure a false 0 → 0 instead of its real
  token; Blessed Strikes 704180's Divine Fury 501567, Reckoning 572741 and Chakram 704573 have no plain cost);
- a reference spell missing: `unmodelled: no active class spell with a heal effect in school mask <mask>` (Templar
  has no heal spell: Sacred Style 705278 and Fortified Body 300515 are unmodelled).

On Templar the 145 passives give 66 scenarios and 79 entries without one; 355 `passive_delta` and 145 `unmodelled`
expectations.

Probe of 2026-11-06 (`--passive` 706431 705266 520009 705303 561346 572555, simulated clock, every scenario
passed): `aura_present` was 1 in the step right after `learn` for all six, and the stats had moved by the next step.
Before → after: Pious 706431 stats 81/132/79/32/50 → 85/138/82/33/52; Liberty 705266 `spell_modifier` op 11 on the
five Librams 1000 → −29000; Paladin Training 520009 op 0 1000 → 1200, op 14 1000 → 800, `spell_power_cost` 40 → 32
(Righteous Lunge 570233) and 50 → 40 (Argent Blade 807268), 0 → 0 for Holy Master 504810 (no cost); Graceful
Fighter 705303 parry rating 0 → 26 and dodge rating 0 → 6; Aggramar's Rage 561346 expertise 4000 → 4010 while Holy
`spell_crit_chance` stayed 2.8592 → 2.8592; Solemn Soldier 572555 `attack_time_ms` 2500 → 2272.73 and expertise
4000 → 4010. `compare` judges these deltas (Verdicts, passive deltas).

Judged probe of 2026-11-06 (`--passive` 300929 705272 561346 705266 712678 572555, stamp 20261106-085206, six
scenarios passed): `ok` for Liberty on its five Librams (1000 → −29000), Solemn Soldier haste (2500 → 2272.73) and
both expertise effects (+10), Serendipity's cost (20 → 19 on Crusader's Brand) and weapon damage (+3%);
`ambiguous_tooltip` for Serendipity on Reckoning (800 → 824: `multiplies` against `adds` 830) and Chivalric
(1500 → 1725: `whole` against `bonus` 1575); alerts for Aggramar's Rage Holy `spell_crit_chance` (2.8592 →
2.8592, expected +6) and Patience on Interdict (spell modifier 1000 → 1000 for both effects; Sacred Restraint, the
mask spell, `measured` 0).

## Max-rank hit scenarios

`hit_parts(class_file, spell, casts)` models the spell's highest rank from its effects, its tooltip read with the
reference stats, the known auras and the reference target. `casts` is the number of casts the mean needs; the scenario
performs `scheduled_casts(casts)`, `ceil(casts x 1.5)`, so that the hits excluded from the mean (critical, blocked)
rarely leave fewer usable hits (ruling R9). It learns the rank, measures the target, then repeats: `set_power` to the
cost (when the cost is a plain `ManaCost`), `reset_cooldown`, the `CasterAuraSpell` fixture of the record (see
above), `cast`, and a wait of
`max(StartRecoveryTime, cast time, duration of a periodic aura) + 500 ms`; a 3 s drain precedes the measurements.

| `kind` | Effects | Hit before modifiers |
|---|---|---|
| `weapon` | 31 percent, 17/58/121 flat | roll times the percent, truncated, plus the floored flats (ADR 0010) |
| `school` | 2 | the floored tooltip value of each effect, or each integer from `$mN` to `$MN`, or each roll (below) |
| `leech` | 9 (`SPELL_EFFECT_HEALTH_LEECH`) | as `school`: the same `SpellDamageBonusDone`/`Taken` path, with mitigation and damage modifiers |
| `heal` | 10 | as `school`, on the caster, without mitigation |
| `periodic_damage`, `periodic_heal` | 6, aura 3 or 8 | one tick; `hits_per_cast` is `Duration / EffectAmplitude` |
| `triggered_weapon` | 6, aura 23 whose `EffectTriggerSpell` is a `weapon` hit | the `weapon` hit of the triggered spell, per tick; `hits_per_cast` is `Duration / EffectAmplitude` |

`hit_kind` can face an effect without its own token, or several effects whose types belong to different kinds.
Temple Guardian 801165/803792 charges an ally and heals both it and the caster for the same amount
(`Effect[1]`/`Effect[2]` both `HEAL`, equal `EffectBasePoints`/`EffectDieSides`), but `Description[enUS]` carries one
`$m2` token on effect 1 only. For a `heal` kind, an effect with no own token whose `Effect`/`EffectBasePoints`/
`EffectDieSides` exactly match a sibling effect's (`matching_sibling`) borrows that sibling's reading and roll, so
both effects contribute the same expected value; this is conservative on purpose (`SHARED_TOKEN_KINDS`), since
`shown_values`/`value_range`/`fixed_value` stay pure functions of their own effect for every other kind and for
rolled/periodic reads. `effect_hit` never sums several effect indexes into one combined roll: each index is an
independent per-cast event (one heal landing on the ally, another on the caster for Temple Guardian), mixed
(equally-weighted averaged) into one distribution, and `expected_hit` multiplies `hits_per_cast` by the index
count so the measured event total still has to clear all of them (ADR 0027). Chastise 503141 has a `school`
effect with a readable token (`$m1`) and a `WEAPON_PERCENT_DAMAGE`
effect gated by an unparsed `$?s` conditional with no token of its own; `hit_kind` resolves several candidate kinds to
one by keeping only the kinds that have an own token on one of their effects (`readout.values`), and raises `effects of
several hit models` as before when more than one kind still has one (or none does).

A periodic effect's token is a total when it grows with `$d` and shrinks with that effect's `$TN` in proportion
(design D15): `period_reading(records, spell_id, caster, shown, effect)` reads the token text alone, then again with
the rank's duration doubled, then with the effect's period doubled (`ScaledPeriod`), and returns `total` when the
value doubles, then halves, `tick` when it does not change, and `mixed` otherwise. The three reads share the same
context (the token alone), so a token whose value depends on the text after it (`$/1000;s1 sec` is ms only before
`sec`) is compared with itself. `periodic_tick_readout` divides a total into one
tick, `total x period / duration`: Blade of Faith 803880's `${($d*1000/$T1)*($m1+0+$SP*.2+$AP*0.1)}` is ten ticks,
and its tick is the total x 3000 / 30000. A `mixed` token (`${($d*1000/$T1)+1}`) is `unmodelled`. In the
no-combat scenario such a total or `mixed` token is `unmeasurable` (`a total over the ticks of periodic effect <n>;
the hit scenario judges one tick`): `spell_effect_value` and `aura_amount` are one tick. Only effects that tick are
read this way: an aura the server makes periodic (`AuraEffect::CalculatePeriodic`, `SpellAuraEffects.cpp:682-702`:
3, 8, 20, 21, 23, 24, 48, 53, 62, 64, 89, 162, 226, 227) with a positive `EffectAmplitude`. Rapid 680323 (aura 107,
amplitude 1500) keeps its `$/1000;s1` as an `effect_value` in ms.

A `triggered_weapon` effect reads the tokens of the described spell's tooltip that belong to the triggered spell, each
on the effect of its first `$<id>sN`/`$<id>mN`, and models them as a `weapon` hit of the triggered spell's effects,
with the same ADR 0010 order. The triggered spell's school gives the mitigation and the modifiers, and its damage is
measured: `hit_spell` in the model (the rank itself for the other kinds) names the spell of `spell_damage_*`,
`critical_hits` and `blocked_hits`; `cast_count` stays the rank. Righteous Tempest 807274: aura 23 every 1000 ms for
5000 ms triggers 570205 (effects 121 and 31); its tooltip shows `$570205s2`% (100) Weapon Damage plus
`${$570205m1+$SP*0.3}` (154), five hits per cast. Known limits: the tokens of the triggered spell are not given the
total reading (a `${$<id>m1*$d/$t1}` there would be modelled as one tick, an alert); and `hits_per_cast` ignores the
extra tick on apply of `AttributesEx5 & 0x200` (`SPELL_ATTR5_EXTRA_INITIAL_PERIOD`): Righteous Tempest lands 6 hits
per cast, so it schedules more casts than needed, while the judged mean is unaffected.

A `school`, `leech` or `heal` effect whose `EffectDieSides` is above 1 and whose tooltip shows one token (Righteous Upheaval:
`${$m1+0+$AP*0.45+$SP*0.45}`, `EffectBasePoints` 658, `EffectDieSides` 224 at rank 572027) is read again with each
roll `EffectBasePoints + 1` .. `EffectBasePoints + EffectDieSides` in place of its points, as the comparison of rolled
effect values does: the server adds one `irand(1, EffectDieSides)` to the points of every direct hit
(`SpellEffectInfo::CalcValue`), so each roll is one equally likely hit and `tooltip_mean` is their mean. A periodic
effect whose amount rolls (one token or `$mN` to `$MN`) is `unmodelled`: `AuraEffect::CalculateAmount` rolls it once
when the aura is applied and every tick reuses it, so the ticks of a cast are not independent hits and an interval
over ticks would be too narrow. Such a spread
can need more casts than one scenario holds: the scheduled casts are split as evenly as possible into the fewest parts
whose casts fit `PART_BUDGET_MS` (532 s: the 600 s scenario limit less the 60 s margin, the 5 s settle and the 3 s
drain; design D16), each part a full scenario with the same measurement labels, named `... part <n> of <parts>` and
keyed `conformance-<class>-hit-<rank>-part-<n>`; a hit that fits one scenario keeps the key
`conformance-<class>-hit-<rank>`. Righteous Upheaval 572027 needs 335 casts, schedules 503 of 1.5 s, in 2 parts of 252
and 251; Reckoning 572741 needs 722, schedules 1083 of 1.75 s, in 4 parts of 271, 271, 271 and 270. A single cast
longer than the budget is `unmodelled`.

The weapon roll is `urand(floor(min + AP / 14 x speed), floor(max + AP / 14 x speed))` (`Unit::CalculateDamage`),
with the normalized speed when an effect is 121 and the weapon speed otherwise. `tooltip_mean` is the same sum without
integer steps: for Argent Blade 807268, 2.15 x ((min + max) / 2 + AP / 14 x 3.3) + (421 + 0.4725 x AP).
Each server integer step is then applied to every possible hit, never as a tolerance:

1. a known aura's modifier, `floor(hit x (100 + percent) / 100)` (`Unit::SpellDamageBonusDone`,
   `Unit::MeleeDamageBonusDone`, `Unit::SpellHealingBonusDone`): aura 341 for damage of its `EffectMiscValue`
   schools, aura 136 for healing, with the amount `SpellEffectInfo::CalcValue` gives at the class level (887007:
   -1 + int(50 x -0.4) + 1 = -20). Only the known auras whose `known_aura` measurement is 1 count, and the model lists
   them (`Modifier`) by spell and effect;
2. armor, `ceil(hit x kept)` (`Unit::CalcArmorReducedDamage`), or each partial-resist step `i` with its share,
   `hit - floor(hit x i / 10)` (`Unit::CalcAbsorbResist`), from `expected_mitigation` and its `resist_shares`.

`mean` and `sigma` are the mean and standard deviation of the resulting distribution; the comparison judges the
measured mean against `mean`, and `tooltip_mean` is shown beside it. `casts_needed(model)` is the Global Constraints
rule: `ceil((2.576 x sigma / (0.01 x mean))^2)` hits, at least one, divided by `hits_per_cast`.

The `hit_mean` expectation carries `model`: the kind, school mask, weapon, modifiers, reference mean, sigma and casts,
`minimum_hits` (the needed casts times `hits_per_cast`: fewer usable hits are insufficient trials), `scheduled_casts`,
`part` (from 0), `parts` and `part_casts` (the casts of this part; every part repeats the totals above),
and the labels of its measurements: `<label> total` and `<label> count` (`spell_damage_*` on `dummy` with
`critical: false` and `blocked: false`, or `spell_heal_*` on the caster with `critical: false`), `target armor`,
`target view_level` and `target resistance <school>`.
`measured_hit_model(class_file, expectation, measured)` recomputes the model from a run's labelled values (caster
stats, known auras, armor, view level and resistances), since creature 36 spawns with armor 528 or 562. Two
diagnostics ride along: `<rank> critical_hits`, `<rank> blocked_hits` (damage only) and `<rank> cast_count`.

`melee_scenario(class_file, swings)` attacks `dummy` for `ceil(swings x 1.5)` weapon swings and measures the plain
main-hand hits (`melee_damage_total` and `melee_damage_count` with `critical`, `glancing` and `blocked` false) under
`melee melee_mean`, beside the swing, critical, glancing and blocked counts; `minimum_hits` is `swings`. Its model is
the weapon roll at weapon speed with the same modifier and armor steps.

A spell that fits no model is never dropped: its expectation has `check` `unmodelled` and a `rule` that starts with
`unmodelled: ` (a passive spell, no damage or healing effect, effects of several models, an effect without a readable
tooltip value, a periodic duration that is unreadable). Its scenario learns the rank and has no hit measurement. The
parts of the tooltip the reader could not evaluate become `hit_mean` expectations whose rule starts with
`unreadable: `, without a measurement. Not modelled: talent or proc modifiers, critical strikes, spell power
coefficients the tooltip does not show, and costs that are a percentage of base mana (no `set_power`).

## Proc rates

A `procs` entry of the class file describes one proc aura:

| Field | Content |
|---|---|
| `aura`, `name` | the proc aura and its `SpellName[enUS]` |
| `tooltip` | its `Description[enUS]`, copied verbatim from the client DBC |
| `chance_token` | the `$h` or `$<id>h` token of the tooltip that shows the chance |
| `trigger` | `{"action": "attack", "spell": 0}` for auto attacks, `{"action": "cast", "spell": <rank>}` for a cast at |
| | `dummy`, with `"target": "ally"` for a cast at a second player |
| `trigger_text` | the words of the tooltip that name the trigger |
| `proc_spell`, `proc_spell_source` | the spell each proc casts, and where that id comes from |
| `event_metric` | `spell_cast_count` or `spell_damage_count`, the metric of `proc_spell`; `spell_charges` when a proc |
| | refreshes a charge of the trigger rank (`proc_spell`) instead of casting a spell |
| `extra_event_terms` | further `{"metric", "spell"}` counts added to the events |
| `events_exclude_trigger_casts` | the events count the trigger's own casts, so the completed player casts are removed |
| `events_per_proc` | the events in one proc |
| `trial_readings` | readings of the trials, `{"name", "meaning", "adds", "minus_events", "trials_metric"}`, if the |
| | text allows several; `"trials_metric": "spell_cast_count"` counts the completed trigger casts as the trials |
| `readings_question` | the log evidence that tells the readings apart without counting, for `questions.md` |
| `handler` | the code that rolls a proc without a `spell_proc` or `spell_script_names` row |
| `dbc` | `ProcChance`, `ProcFlags`, `ProcCharges` of the aura and of the spell of the chance token |
| `spell_proc` | the `spell_proc` row of each spell, `{}` without one |
| `internal_cooldown_ms` | the `spell_proc` `Cooldown`, the internal cooldown between procs |
| `status`, `reason` | `ambiguous_tooltip` or `unmodelled` for an entry without a scenario, and why |
| `question` | the log query of an `ambiguous_tooltip` entry ([questions](#open-conformance-checks)) |

The trigger comes from the tooltip text only. When the text does not say what triggers the proc, the entry is
`ambiguous_tooltip` and never gets a chosen trigger. An entry whose observable the harness cannot separate is
`unmodelled` with its reason. Both have no scenario and are never `ok`.

An aura with two independent chance rolls on the same trigger (two `EffectTriggerSpell` entries, each its own
`proc_spell`) gets two `procs` entries sharing one `aura`: one per `proc_spell`, each with the full tooltip and its
own half's `chance_token`, `trigger_text`, `trial_readings` and `dbc`. `proc_label`/`scenario_key` disambiguate by
`(aura, proc_spell)` only when `shares_aura` finds more than one entry for that aura, so a single-`proc_spell` aura's
label and scenario keys are unchanged. `extra_event_terms` is for a trigger that fires more than one countable event
per proc of the *same* roll; it never folds two independently-chanced effects into one entry.

A tooltip phrase that reads broader than the aura's own `ProcFlags` (for example "physical damage dealt", not
"melee attacks") gets a second `procs` entry sharing both `aura` and `proc_spell` with the first: the first entry
keeps the narrow trigger the DBC's `ProcFlags` already covers (`{"action": "attack", "spell": 0}`), the second
drives the same roll through a trigger the tooltip's wording covers but the current `ProcFlags` does not (a `cast`
of a spell dealing the broader kind of damage). `shares_proc_spell` detects this case and `trigger_key` (the
trigger's action, or its spell id for a `cast` trigger) becomes the extra disambiguator in `proc_label`/
`scenario_key`, so neither collides with the first entry's. `proc_scenario` arms the caster with `armed_for` for a
`cast` trigger, the same equip-requirement check `triggers.py` already applies, so a trigger spell that needs a
different weapon than the class's reference weapon still casts.

When the text leaves open which events are trials, `trial_readings` lists each reading: the triggering hits plus the
counts in `adds`, less the events when `minus_events` is true. No reading is chosen: the comparison judges each one,
gives their common verdict when they agree and `ambiguous_tooltip` with every reading's numbers when they do not, so
that the owner can rule. "Direct damage dealt" (Scourgebane) reads as the auto attacks only, or as every direct
damage event, its own strikes 801832 included (Effect 2 and 31, DmgClass 1).

`trials_needed(p)` is `ceil(2.576^2 x p (1 - p) / 0.025^2)`, the trials that put the half width of the 99% interval
of the rate at 2.5 points: 1699 for 20%, 956 for 10%. The scenario performs `ceil(1.5 x trials_needed)` attempts
(ruling R9), refuses fewer attempts than `trials_needed`, and splits them over parts whose wait fits the 600 s
scenario limit with the 60 s margin of the hit scenarios. Each part learns the aura, then:

- for `attack`: attacks `dummy` for its attempts times the weapon speed; a trial is a main-hand melee hit that deals
  damage (`melee_damage_count` with `hand` 0, `melee_attack_count` beside it). A miss, dodge or parry deals none and
  is not a trial. An internal cooldown makes the entry `unmodelled`: auto attacks cannot be spaced beyond it.
- for `cast`: learns the trigger rank and casts it at `dummy` as the hit scenarios do, one cast every
  `max(StartRecoveryTime, cast time, internal_cooldown_ms) + 500 ms`; a trial is a damage event of the trigger rank
  on `dummy` (`spell_damage_count`, `spell_cast_count` beside it), so a failed cast is no trial (ADR 0011 R11). A
  trigger with periodic damage (aura 3) is cast at most every two ticks (`2 x EffectAmplitude + 500 ms`): a recast
  restarts its tick timer (Blade of Faith, stamp `20261106-130708`: 2058 ticks for 2044 casts 3.5 s apart), so
  only a spacing beyond one tick lets a reading that counts ticks and one that counts casts tell their trials apart.
- for a `cast` at `ally`: the scenario adds a second player `ally` and no creature; a trial is a completed cast
  (`spell_cast_count`). If the trigger rank's own effects close the distance to its target
  (`values.closes_distance`), the caster is also moved 10 yards away with `relocate` before each cast, since a
  charge ends next to its target and Temple Guardian needs 5 to 30 yards; a stationary ally heal such as Testament
  of Faith has no such effect and leaves the caster in place.
- for `spell_charges`: the part restores the charges of the trigger rank and measures the pool, restores them
  again before each cast and measures the charges left after it. A cast leaves the pool less one, or the whole pool
  when it refreshed a charge, and a failed cast leaves the whole pool, so the procs of a part are the summed charges
  plus the completed casts less the pool times the casts.

Each part then measures the event counts, the counts its readings add, and the aura on the character. The `proc_rate`
expectation of every part has the same label, `<aura> proc_rate`; the comparison sums the trials and the events of the
parts whose run measured the aura, removes from the events the player casts that completed (`part_attempts` less the
failed casts of the trigger) when they include them, and divides the events by `events_per_proc`. The chance is the
tooltip token read again with the measured stats. Fewer trials than `trials_needed` are `insufficient_trials`, even at
the exact rate; no usable trial (failed casts, aura absent) is `unmeasured`; otherwise the verdict is `ok` when the
chance lies in the Wilson interval (z = 2.576) of procs over trials, and `alert` outside it, with more procs than
trials, or with fewer events than the player casts. The trial count is the operative condition: an `ok` may carry a half
width above 2.5 points when the measured rate is closer to one half than the chance.

The Templar entries cite the client DBC and the `spell_proc` and `spell_script_names` rows of `acore_world` in the
in-RAM test database, read on 2026-11-05 (`SELECT * FROM spell_proc WHERE SpellId IN (...)`):

| Aura | Chance | Trigger | Proc spell | Entry |
|---|---|---|---|---|
| Scourgebane 92111 | `$520007h` 20% | attack ("Direct damage dealt") | 801832, tooltip `$801832s2` | 2 readings |
| Warrior of Dawn 560648 | `$h` 10% | attack ("Melee damage dealt") | 561156, tooltip `$561156s1` | scenario |
| Retribution 707391 | `$h` 20% | attack ("Melee damage dealt") | 525028 (2 per proc), `EffectTriggerSpell` | scenario |
| Light's Echo 520017, 520883 | `$h` 10%, 20% | cast of Argent Blade 807268 | 804929 or 807268 casts | 2 readings |
| Paladin Training 504808 | `$h` 8% | "Triggering Zealotry" | | `ambiguous_tooltip` |
| Blade Sermon 572548, 572554 | `$h` 5%, 10% | Zealotry | | `ambiguous_tooltip` |
| Condemnation 706325 | `$h` 15% | cast of Blade of Faith 803880 | 801450, `@s:801450:0@` | 2 readings |
| Transcendent Guardian 804571 | `$h` 40% | Temple Guardian 803792 at an ally | its refreshed charge | scenario |
| Lightkeeper (parry) 560835 | `$h` 15% | periodic damage of Condemn 804906 | 561016, `EffectTriggerSpell[0]` | 2 readings |
| Lightkeeper (burst) 560835 | `$h` 15% | periodic damage of Condemn 804906 | 561277 (damage), `EffectTriggerSpell[1]` | 2 readings |
| Pulverizing 524620 | `$h` 15% | cast of Condemn 804906 (damage dealt) | 524619, tooltip `$524619m1` | scenario |

`spell_proc` has rows for 92111 (Chance 100), 520007, 560648 and 707391 (Chance 0, so the DBC `ProcChance`), all
with `ProcFlags` 1048575 and `Cooldown` 0, and none for the other auras; the four are scripted by
`aura_ascension_templar_event`, whose checks for them (`AscensionTemplarEvents.cpp:58-73`) keep no cooldown of
their own, so no entry with a scenario has an internal cooldown. The Light's Echo, Paladin Training, Blade Sermon
and Transcendent Guardian auras have neither a `spell_proc` nor a `spell_script_names` row, yet the code rolls each
of them (`handler`), so none is known to stay at 0%. Condemnation 706325 has a `spell_proc` row (Chance 0, so the
DBC `ProcChance` 15) and the same script, read on 2026-11-06; its check (`AscensionTemplarEvents.cpp:81-83`) accepts
damage of Condemn, Holy Cleave or Blade of Faith within melee range, periodic damage included, and casts Zealotry
801450 (`AscensionTemplarEvents.cpp:121-123`). Only Blade of Faith is in the class set; its damage is periodic only,
so the readings are each cast and each damage tick. Pulverizing 524620 has its own `spell_proc` row too (`Chance`
0, read on 2026-11-08), from the same native re-insert as the four `aura_ascension_templar_event` auras above, with
its `Chance` zeroed by `rev_20260919_20_coa_proc_chance_parity.sql`; the DBC `ProcChance` 15% fallback
(`SpellMgr.cpp:2371-2372`) is a plain `EffectTriggerSpell` roll on each damaging Condemn cast, with no scripted
override and a single reading (damage is the only trigger named by the tooltip), unlike Lightkeeper's two readings.
Transcendent Guardian refreshes the charge of the cast rank on
40% of the casts at another unit (`AscensionTemplarAbilities.cpp:220-224`) and casts nothing; owner ruling 3 of
ADR 0011 (any target other than the caster) stays open, since the scenario casts at an ally only. Temple Guardian is
outside the CharacterAdvancement class set and is cast by live Templars (owner answer Q3); the scenario learns
803792 directly. Light's Echo recasts the rank cast, triggered, after a damaging
hit (`AscensionTemplarAbilities.cpp:296-300`), while its aura's `EffectTriggerSpell[0]` is the first rank 804929:
the events are the casts of both ranks less the completed player casts, which counts the extra strike whichever rank
it uses. Its readings are the player casts only, or every Argent Blade strike, extra strikes included.

Measured on 2026-11-05 (stamp `20261105-201416`, simulated clock, gameplay stage 35.7 s for 26 parts, no failed
cast):

| Aura | Parts | Reading | Procs in trials | Wilson 99% | Reading verdict | Verdict |
|---|---|---|---|---|---|---|
| Scourgebane 92111 | 13 | auto attacks only | 525 in 2554 | 0.186 to 0.227 | `ok` | `ambiguous_tooltip` |
| | | every direct damage event | 525 in 3079 | 0.154 to 0.189 | `alert` | |
| Light's Echo 520017 | 5 | player casts only | 173 in 1435 | 0.100 to 0.145 | `alert` | `ambiguous_tooltip` |
| | | every Argent Blade strike | 173 in 1608 | 0.089 to 0.129 | `ok` | |
| Light's Echo 520883 | 8 | player casts only | 519 in 2552 | 0.184 to 0.225 | `ok` | `ambiguous_tooltip` |
| | | every Argent Blade strike | 519 in 3071 | 0.152 to 0.187 | `alert` | |

Scourgebane parts made 196 or 197 swings, Light's Echo parts 287 and 319 player casts. Every extra Argent Blade
strike was a cast of 807268; 804929 was never cast. A Scourgebane part takes 500.7 s of game time in 3.8 to 4.7 s of
real time, a Light's Echo part 443 to 491 s in 3.2 to 4.3 s.

Measured on 2026-11-06 (stamps `20261106-130841`, 26 Condemnation parts in 36.2 s, and `20261106-130708`, 11
Transcendent Guardian parts, simulated clock, no failed cast):

| Aura | Parts | Reading | Procs in trials | Wilson 99% | Reading verdict | Verdict |
|---|---|---|---|---|---|---|
| Condemnation 706325 | 26 | each cast | 622 in 2054 | 0.277 to 0.330 | `alert` | `ambiguous_tooltip` |
| | | each damage tick | 622 in 4134 | 0.137 to 0.165 | `ok` | |
| Transcendent Guardian 804571 | 11 | casts at the ally | 1509 in 3828 | 0.374 to 0.415 | `ok` | `ok` |

Lightkeeper 560835 is absent from both `TemplarEvents` and `TemplarCastDrivers` (grepped `src/server/coa/*.cpp` for
`560835`): it is one of two Templar proc entries of the nine that are plain, native `ProcFlags`/`ProcChance`/
`EffectTriggerSpell` procs with no scripted override, the other being Pulverizing 524620 below. Its two
`EffectTriggerSpell` slots each roll their own 15% independently on the same periodic tick of Condemn 804906; no
`spell_proc` row exists for it, so `spell_proc` is `{}` for both entries, like the other auras with no row.

Measured on 2026-11-07 (stamp `20261107-184729`, simulated clock, no failed cast, 26 parts each):

| Aura | Parts | Reading | Procs in trials | Wilson 99% | Reading verdict | Verdict |
|---|---|---|---|---|---|---|
| Lightkeeper (parry) 560835 | 26 | each cast | 695 in 2054 | 0.312 to 0.366 | `alert` | `ambiguous_tooltip` |
| | | each damage tick | 695 in 4472 | 0.142 to 0.170 | `ok` | |
| Lightkeeper (burst) 560835 | 26 | each cast | 668 in 2054 | 0.299 to 0.352 | `alert` | `ambiguous_tooltip` |
| | | each damage tick | 668 in 4472 | 0.136 to 0.164 | `ok` | |

Both readings disagree the same way Condemnation 706325 does: counting each Condemn cast as one trial roughly
doubles the apparent rate (Condemn ticks about twice per cast at this attempt spacing), while counting each
periodic damage tick holds the tooltip's 15% within the Wilson interval. Both carry `readings_question` and go to
`questions.md`.

Pulverizing has a single reading (damaging Condemn casts), so it needs no `trial_readings` split. Measured on
2026-11-08 (`report.json` `.cache/verify-all/20261108-125057/report.json`, simulated clock, 26 of 26 parts, no
failed cast):

| Aura | Reading | Procs in trials | Wilson 99% | Verdict |
|---|---|---|---|---|
| Pulverizing 524620 | damage events of Condemn 804906 on the target | 622 in 4472 | 0.126 to 0.153 | `ok` |

## Trigger entries

A `triggers` entry of the class file is a passive whose tooltip says that something always happens on a trigger
("Casting Sacred Swing now grants you Staffguard"): a proc entry whose chance is 100%, without a chance token.

| Field | Content |
|---|---|
| `aura`, `name` | the passive and its `SpellName[enUS]` |
| `tooltip` | its `Description[enUS]`, copied verbatim from the client DBC |
| `trigger` | `{"action": "cast", "spell": <rank>, "target": "self"/"dummy"/"ally"}`, `{"action": "attack", "spell": 0}`, or `{"action": "periodic", "amplitude_ms": <ms>}` for a trigger that is the aura's own tick, not a player action |
| `trigger_text` | the words of the cleaned tooltip that name the trigger |
| `trigger_spell_text` | for a cast, the words of the rank's name or cleaned tooltip that make it such a trigger |
| `trial_metric` | one trial: `spell_cast_count`, `spell_damage_count`, `melee_attack_count`, `melee_damage_count`; for `periodic`, always `spell_cast_count` (descriptive only, no trial-count measurement is taken) |
| `observe_spell`, `observe_source` | the spell a trigger casts, from `EffectTriggerSpell[n]` or tooltip `@s:<id>:0@` |
| `observe_note` | with a tooltip reference, why the text's spell is observed instead of an `EffectTriggerSpell` |
| `attempt_auras` | `{"spell", "stacks", "source"}` set before every cast, `source` quoting the tooltip behind it |
| `ally_health_pct` | for a `target: "ally"` cast, the ally's health percent set before every cast so the heal is effective |
| `caster_health_pct` | the caster's own health percent set before every cast, for a trigger the server code gates on an effective self-heal (`GetHealInfo()->GetEffectiveHeal()`), which is 0 at full health |
| `restore_charges` | for a cast trigger, restores the trigger rank's native charges before every attempt (needed when the rank is also a charge-counting `procs` entry's trigger) |
| `internal_cooldown_ms` | spaces scheduled attempts at least this many ms apart, on top of the trigger rank's own cast time and recovery, for a trigger the server code gates on an internal cooldown |
| `observe_metric` | `spell_cast_count`, `spell_energize_count` or `aura_apply_count` of `observe_spell` |
| `observe_actor` | `"caster"` (default) or `"target"`: which actor's `observe_metric` is measured, for a trigger whose effect lands on the target rather than the caster (`Unit::AddAura`, not a `CastSpell`) |
| `per_trigger`, `per_trigger_text` | the events per trial, 1 or 0.5 for "Every 2nd", and the words that state it |
| `trial_attempts_factor`, `trial_attempts_reason` | multiplies the scheduled attempts (default 1, unchanged); a cited reason, for a trigger whose own cast sometimes executes as a different spell id and so is not counted as a trial of itself |
| `periodic_initial_tick` | for a `periodic` trigger only: the aura's own `AttributesEx5` carries `SPELL_ATTR5_EXTRA_INITIAL_PERIOD`, so one extra tick is expected per counted part on top of `attempts x per_trigger` |
| `status`, `reason` | `unmodelled` or `ambiguous_tooltip` for an entry without a scenario, and why |
| `trigger` (status entries) | optional: a `status` entry with no real trigger mechanism to point to (dead effect, or reachable only through a mechanism this harness cannot drive) omits `trigger`, `trigger_spell_text` and `trial_metric` entirely rather than carry a fabricated shape; the entry-shape test only enforces the full `trigger` shape on entries that have one |
| `question` | the finding text when the entry's verdict is an `alert` the server code explains: a server finding goes to the open conformance checks list, not into a verdict change |

`aura_proc_rate` is not a judge of these entries: their passives have `ProcFlags` 0 and are scripted (design D10).
The observed spell is the passive's `EffectTriggerSpell[n]` (`observe_source` `EffectTriggerSpell[n] of <aura>`)
unless the text names another spell through an `@s:` reference; then the entry observes the named spell
(`tooltip reference @s:<id>:0@ of <aura>`) and says why in `observe_note`. An `attempt_auras` fixture keeps a
condition stated by another tooltip from blocking the claim, for example a cap on stacks.
A trigger is cast as the hit scenarios cast: before each cast the power is set to the cost, the cooldown is reset and
the `CasterAuraSpell` fixture is applied (Sacred Swing 681170, Righteous Upheaval 704576), one cast every
`max(StartRecoveryTime, cast time) + 500 ms`; a `self` trigger is cast without a target. An `attack` trigger attacks
`dummy` for the attempts times the weapon speed. A `target: "ally"` trigger adds a second player `ally`, groups the
caster with it once before the first cast (`{"action": "group", "actor": "caster", "target": "ally"}`, a raid group
so `Unit::IsInRaidWith` holds). If the trigger rank's own effects close the distance to its target
(`values.closes_distance`), the caster is also relocated `CHARGE_OFFSET_YD` away before every cast at the ally
(the same fixture `hits.py`'s ally-targeted hit scenarios use, needed so a charge-type rank is not already in its
minimum range); a stationary ally heal such as Testament of Faith (Binding Scripture's trigger cast) has no such
effect and leaves the caster in place. With `ally_health_pct` set, the ally's health is lowered to that percent of
a 10000 fixed maximum before every cast so a heal lands an effective, non-zero amount. With `caster_health_pct`
set, the caster's own
health is lowered the same way before every cast, for a trigger the server code only recognises on a self-heal
with a nonzero `GetEffectiveHeal()` (the reference caster starts at full health, so an uncapped self-heal would
otherwise always read as 0 effective healing and never fire). With `restore_charges` set, the trigger rank's
charge pool is restored before every cast (`"restore_charges"` fixture), needed for a charge-limited rank cast at
the harness's scheduled attempt rate rather than its native recharge rate. With `internal_cooldown_ms` set, each
attempt is spaced at least that long apart (`max(StartRecoveryTime, cast time, internal_cooldown_ms) + 500 ms`),
for a trigger the server code gates behind its own internal cooldown rather than the trigger rank's.

A `periodic` trigger is not a player action at all: it is `SPELL_AURA_PERIODIC_TRIGGER_SPELL`'s own amplitude tick,
running from the generic engine's periodic-effect path rather than the proc-event path, so it is unaffected by
`ProcFlags` and needs no learned trigger rank. The scenario only learns the passive and waits
`attempts x amplitude_ms`; there is no cast, no attack and no `trial_metric` measurement (the `counts()` step pair
collapses to the single `observe_metric` count). Judging compares the events measured against the attempt count
computed at generation time (`part_attempts`, known from the scheduled wait), not against a game-measured trial
count: `|events - attempts x per_trigger| <= 1`, with the same no-event-in-the-baseline rule as every other
trigger. `per_trigger` is still required and is 1 for every `periodic` entry seen so far (one trigger-spell cast
per tick). The main-phase wait is not followed by the generic `drain` step every other trigger action gets: the
periodic aura keeps ticking for as long as it is applied, so any extra wait after the scheduled attempts would
let more ticks bleed into the same count; the events measurement is taken the instant the scheduled wait ends.
`periodic_initial_tick`, when true, adds one event per counted part on top of `attempts x per_trigger`, for a
passive whose own `Spell.dbc` `AttributesEx5` carries `SPELL_ATTR5_EXTRA_INITIAL_PERIOD` (0x200, "Immediately do
periodic tick on apply"): each part is a separate scenario that re-learns the passive from scratch, so each part
gets its own extra tick at apply, on top of the regular amplitude cadence.

`aura_apply_count` counts a target's `AuraApplyCounter` (`CoAGameplayTest.cpp`), a static `(unit, spell)` map
recorded from `UnitScript::OnAuraApply`, the generic engine hook `Unit::_ApplyAura` calls after every aura
application, including one made by `Unit::AddAura` (which never builds a `Spell` object, so `ProcCounter`'s
`OnSpellCast`-based metrics never see it). It is for an effect applied this way rather than through `CastSpell`;
`observe_actor: "target"` then measures it on the hostile `dummy` fixture instead of the caster.

`TRIGGER_TRIALS` is 182, the smallest N with 0.975^N <= 0.01: a trigger that fires 2.5 points under 100% of the time
misses at least once in 182 trials with 99% probability. The scenario learns the trigger rank, makes
`BASELINE_ATTEMPTS` (20, a choice, not derived) attempts and measures the trials and the events, learns the passive,
makes 273 attempts (`ceil(1.5 x 182)`, ruling R9) and measures the trials, the events and the passive's aura. Parts
split the attempts so that each wait fits the 600 s limit with the 60 s margin; only the first part holds the
baseline. The `trigger_count` expectation of every part has the label `<aura> trigger_count`; the comparison sums the
trials and the events after the learn of the parts whose run measured the aura. Any event in the baseline is an
`alert`; no usable trial is `unmeasured`; fewer than 182 trials are `insufficient_trials`; otherwise
`|events - trials x per_trigger| <= 1` is `ok` and anything else `alert`. A baseline without a trial never gives
`ok`: its verdict is `unmeasured`.

The Templar entries quote their trigger words from the cleaned DBC tooltips:

| Passive | Trigger | Trials | Observed | Per trial |
|---|---|---|---|---|
| Scarlet Secrets 520812 | "Every 2nd cast of Argent Blade", 807268 at `dummy` | casts | 804924 casts (`@s:`) | 0.5 |
| Sanctify 705274 | "Your Libram spells", Libram of Tenacity 801461, `self` | casts | 705275 casts | 1 |
| Blessing of Eonar 705290 | "Using Libram spells", 801461, `self` | casts | 520537 casts | 1 |
| Staffguard 705295 | "Casting Sacred Swing", 572769 at `dummy` | casts | 706583 casts | 1 |
| Conviction 712677 | "Casting Sacred Swing", 572769 at `dummy` | casts | 712679 casts | 1 |
| Fervent Castigation 707606 | "Casting Righteous Upheaval", 572027 at `dummy` | casts | 804924 casts | 1 |
| Mending Ward 806273 | "Oath Breakers", 572027 ("a dominating Oath Breaker") | casts | 806353 casts | 1 |
| Unbroken Creed 804932 | "Damaging abilities", 807268 at `dummy` | damage events | 807648 casts | 1 |
| Heaven's Finest 806516 | "Damaging abilities", 807268 at `dummy` | damage events | 805390 casts | 1 |
| Chakra of Power 803158 | "Melee attacks", auto attack | swings | 804181 energizes | 1 |
| Way of the Monk 805420 | "Damage dealt by Sacred Swing", 572769 at `dummy` | damage events | 572052 casts | 1 |
| Chakra of Light 803844, 803159 | "Oath Breakers", 572027 ("a dominating Oath Breaker") | casts | 803160 casts | 1 |
| Scarlet Training 301065 | "Casting Argent Blade", 807268 at `dummy` | casts | 301172 casts | 1 |
| Binding Scripture 801457 | "Healing an ally", Testament of Faith 801478 at `ally` | casts | 705309 casts | 1 |
| Whirling Tempest 300504 | "While Righteous Tempest is active", 805409 (channel start) `self` | casts | 301340 aura applies | 1 |
| Light's Ward 300529 | periodic, 2000 ms amplitude | ticks | 301283 casts | 1 |
| Light's Chosen 301310 | periodic, 5000 ms amplitude | ticks | 301369 casts | 1 |

Chakra of Light's two ranks share Mending Ward's 806273 `Breaker()` condition and its 572027 fixture (same
`AscensionTemplarAbilities.cpp:192-198`): both are in `TemplarCastDrivers`, so the DBC's own `EffectTriggerSpell[0]`
803160 never fires natively (routed to `SPELL_AURA_DUMMY`, same P3-R8 pattern as Mending Ward); the scripted hook
casts it unconditionally on every Oath Breaker cast, once for the solo caster. Scarlet Training is also in
`TemplarCastDrivers` (its own `EffectTriggerSpell[0]` 301172 likewise decorative); the real condition
(`AscensionTemplarAbilities.cpp:232-235`) is casting Argent Blade 804929-family while a `GetScriptValue(704576)`
set by Warrior of Dawn 561156's apply hook (`AscensionTemplarAuras.cpp:114-120`) is non-zero, which the harness's
`set_aura` fixture (`attempt_auras`) satisfies by applying 561156 fresh before every cast. Once the transform fires,
the next scheduled Argent Blade 807268 cast executes as Scarlet Hammer 807035 instead (`SetTemporarySpellReplacement`)
and is not counted as an 807268 trial, roughly halving the usable trials per scheduled attempt; `trial_attempts_factor`
2 schedules 546 attempts so enough stay valid. Binding Scripture is in `TemplarEvents`; its condition
(`AscensionTemplarEvents.cpp:77-78`) is an effective heal (`GetEffectiveHeal()` non-zero) on a raid member other than
the caster, with no roll (matches `ProcChance` 100): the scenario groups the caster with the `ally` player once and
sets the ally to 50% of a 10000 fixed health before every Testament of Faith 801478 cast, so every heal is effective.

Whirling Tempest 300504 is in `TemplarCastDrivers`, so `ApplyContracts` zeroes its `EffectApplyAuraName[0]`
(`PROC_TRIGGER_SPELL`) at runtime and sets `ProcFlags` 0; the behaviour the entry measures is scripted
(`AscensionTemplarAuras.cpp:154-158`, an apply hook keyed on `Named(GetSpellInfo(), 805409)`, i.e. the self aura
805409 that starts the Righteous Tempest channel being applied while 300504 is known — not its periodic damage
tick 805410, which applies no aura to the caster and so never reaches this hook), not the generic engine. The entry still cites
`EffectTriggerSpell[0] of 300504` as `observe_source` because the DBC's own field happens to equal the real
observed spell (301340) even though the runtime path that actually casts it is the scripted hook, not the DBC
effect — the same coincidence `301065 Scarlet Training` and `301254 Improved Scarlet Hammer` already rely on.
805409 is its own self-channel (`SpellDuration.dbc` id 27, 3000 ms) with `RecoveryTime` and `CategoryRecoveryTime`
both 0, so nothing stops the harness from scheduling the next cast before the current one's 3000 ms duration
ends; recasting into an active channel fails `SPELL_FAILED_SPELL_IN_PROGRESS` (measured live: 146 failed casts
of 273 scheduled before this was caught). The entry sets `internal_cooldown_ms: 3000` to space attempts at least
that far apart; this is not a server-scripted cooldown like Untainted's, only the self-channel's own duration,
reusing the field for the same effect (a floor below the harness's own `CAST_MARGIN_MS` spacing) rather than
adding a second field with an identical mechanism.
Light's Ward 300529 and Light's Chosen 301310 are in neither `TemplarEvents` nor `TemplarCastDrivers`: their
`SPELL_AURA_PERIODIC_TRIGGER_SPELL` effects (23) run unmodified through the generic engine's amplitude tick
(2000 ms and 5000 ms), using the new `periodic` trigger action described above. Warrior of Tyr 301253 carries a
`SPELL_AURA_PROC_TRIGGER_SPELL` effect (42) that no code path in this tree can ever fire: `ProcFlags` 0 on its
own `Spell.dbc` row, `SpellMgr.cpp:2512` ("Skip if no proc flags in DBC") skips generating a `spell_proc` row for
it, no `spell_proc` SQL row exists for 301253 or its `EffectTriggerSpell`, and `AscensionTemplarEvents.cpp`'s
`DoCheckProc`/`OnProc` switch has no case for it — so this entry is `status: "unmodelled"`, same convention as
Disciplined Blows 680397, and (unlike Keeping the Oath below) has no `trigger` field at all since no mechanism
backs one. Keeping the Oath 92109 also carries a `SPELL_AURA_PROC_TRIGGER_SPELL` effect (42,
`EffectTriggerSpell` 681170 `SPELL_RECENTLY_PARRIED_OR_DODGED`), and `ApplyContracts` sets its DBC `ProcFlags` to
0 at runtime the same way, but this one is reachable: `data/sql/updates/pending_db_world/rev_20261001_04_templar_keeping_the_oath_avoid.sql`
(merged, PR #6159) gives 92109 an explicit `spell_proc` row (`ProcFlags` 40, `HitMask` 48 = dodge or parry,
`Chance` 100), and `LoadSpellProcs` populates `mSpellProcMap` from that row before the DBC-autogeneration gate
`SpellMgr.cpp:2512` ever runs, so the generic engine's `AuraEffect::HandleProcTriggerSpellAuraProc` casts 681170
on a taken melee dodge or parry with no scripted `OnProc` case needed. The entry is still `status: "unmodelled"`,
without a `trigger` field, because this harness has no action that makes a creature melee-attack the player
(`hits.py`'s `creature_fixture` is a stationary, non-aggressive dummy) nor one that forces or statistically
bounds a dodge/parry outcome — the same kind of missing-capability gap as 300502/301339/500011 below, not a
dead effect.
Blessing of Aggramar 300502, Holy Tempest 301339 and Holy Combatant 500011 share this lot's remaining P5-family
gap (round3 `trigger-lot-5-spec.md`, part A) but are not yet modelled: each needs mechanism work beyond this
`triggers` schema (an `aura_refresh` check family reading a duration delta instead of a discrete count, and, for
301339, a second creature fixture for the hit's spread target) that this round did not build.

Measured on 2026-11-07 (stamp `20261107-184729`, simulated clock, gameplay stage 57.0 s for 10 parts, no failed
cast, 20 baseline trials and no baseline event in each entry): all four entries are `ok` with 273 events in 273
trials.

Scarlet Secrets' `EffectTriggerSpell[0]` is 520926, a dummy aura its text does not name; the server never cast it in
273 Argent Blade casts (stamp `20261106-092819`), while the text grants Oath: Retribution 804924. Oath Chain 704576
caps the Oaths ("Once 10 stacks are reached you are unable to build more Oaths."): with the chain kept, 100 of 273
casts granted the Oath (stamp `20261106-093118`), so the entry removes the chain before every attempt.

Measured on 2026-11-06 (stamp `20261106-093404`, simulated clock, gameplay stage 29.8 s for 12 parts, no failed
cast, 20 baseline trials and no baseline event in each entry): nine entries are `ok` with 273 events in 273 trials
(Scarlet Secrets 136 in 273, expected 136.5). Two are `alert`, both explained by server code:

- Fervent Castigation 707606: 0 casts of 804924 in 273 Righteous Upheaval casts. The cast only sets a flag
  (`AscensionTemplarAbilities.cpp:178-179`); the Oath is granted when a later Oath starts a new chain
  (`AscensionTemplar.cpp:177-181`), not on the cast as the text says.
- Heaven's Finest 806516: 150 casts of 805390 in 273 Argent Blade hits. At 6 stacks the aura casts The Finest of
  Heaven 806517 and is removed (`AscensionTemplarAuras.cpp:134-138`), and no stack is granted while 806517 (8 s) is
  up (`AscensionTemplarEvents.cpp:208-214`); the text, its `@s:805390:0@` reference included, does not say so.

Both entries carry a `question`, so their alerts go to the "Findings" section of `questions.md`.

## Behaviour scenarios

A `behaviours` entry of the class file is a passive whose tooltip states a behaviour in **prose**, with no `$`
token: "2 additional enemies," "an additional copy," "doubles the healing," "always triggers," "refreshes the
duration." Phase 2's design explicitly parked these as a non-goal of the token method (ADR 0011). This section
crosses that line on purpose, for a bounded, named list of spells, and never becomes a general prose parser.

The expected value is still DBC-derived: it is the literal number or count written in `Description[enUS]`, quoted
verbatim in the scenario's `rule`, never invented or rounded to "look right." Every `Expectation` built from a
`behaviours` entry uses a check name distinct from `effect_value`/`aura_amount`/`passive_delta`, so a reader of
`verdicts.json` can always tell a prose-sourced result from a token-sourced one, even though both ultimately
produce the same status vocabulary (`ok`, `alert`, `unmodelled`, `measured`, `ambiguous_tooltip`,
`insufficient_trials`, `unmeasured`; no new status is invented):

| Check | Claim |
|---|---|
| `behaviour_count` | a count ("N additional targets," "an additional copy" = +1, summon counts) |
| `behaviour_ratio` | a ratio ("doubles the healing" = x2, "twice the damage" = x2) |
| `behaviour_duration` | a duration refresh or reduction |
| `behaviour_duration_ratio` | a duration reduction on a mechanic the engine's own generic `SPELL_AURA_MECHANIC_DURATION_MOD` consumer applies, read off a named vehicle spell cast at the caster rather than off a forced crit |
| `behaviour_trigger` | a scripted "always fires" claim not reachable through `triggers.py`'s native `EffectTriggerSpell` path |
| `behaviour_metric_delta` | a passive whose change is read through a harness metric already used elsewhere in the scenario (`owned_creature_count`, `aura_amount`, ...) around a named active spell, judged by exact equality rather than a tolerance band |
| `behaviour_ratio` (`kind: "health_ratio"`) | a ratio conditional on the caster's own health, read at several health percentages in one scenario |

Every `Expectation.rule` of these checks starts with the literal prefix `prose: ` followed by the quoted
`Description[enUS]` fragment that states the number, e.g.
`prose: "strikes 2 additional enemies near the primary target" (525024)`. This is the one thing that must never be
skipped: it is what keeps a behaviour `ok` honestly distinguishable from a token `ok` if anyone audits later.

| Field | Content |
|---|---|
| `spell`, `name` | the passive and its `SpellName[enUS]` |
| `kind` | `count`, `ratio`, `duration`, `duration_ratio`, `trigger`, `spread`, `metric_delta` or `health_ratio`: which scenario builder and judge rule apply |
| `quote` | the exact prose fragment of `Description[enUS]`, checked to be a substring at generation time |
| `expected` | the number, ratio or duration the quote states (not used by `health_ratio`, which states its ratios in `levels` instead, one per health percentage, or by `duration`, which states its milliseconds in `expected_ms` instead) |
| kind-specific fields | `count`: `target_rank` (the active spell cast), `radius` and `radius_reason` (the source citation that grounds the fixture placement, never a guessed distance), `metric` (`spell_damage_count`, the default, for a spell with a school-damage effect, or `aura` for a spell whose own effect is not damage, such as a silence); `ratio`: `targets`, a list of `[rank_id, name]` pairs; `spread`: `seed_spell` (cast on the primary dummy to install the aura the passive must copy), `aura_spell` (the aura id measured on every extra dummy), `target_rank` (the active whose damage triggers the copy), `radius`/`radius_reason`; `trigger`: `shield_aura` (the absorb aura that must be fully consumed), `trigger_spell` (the spell the break casts), `breaker_spell` (a spell of the absorb's own school that the striker casts directly at the caster to deplete it deterministically), `striker_entry` (a creature template entry to cast it from), `break_timeout_ms` (how long to wait for the aura to clear once the breaker spell lands, default 3000); `metric_delta`: `trigger_spell` (the active spell cast to create the measurable state, learned once up front since it is not otherwise granted to the reference character), `metric`/`fields` (the harness metric and its query fields, e.g. `owned_creature_count`/`{"entry": ...}` or `aura_amount`/`{"spell": ..., "effect": ...}`), `before_expected` (the DBC-derived baseline value asserted on the "before" measurement), `wait_ms` (settle time after the cast before measuring, default 3000), `expire_ms` (wait after the learn before the second cast, long enough for the first cast's effect to fully expire so it cannot contaminate the second measurement, default 20500); `health_ratio`: `probe_spell` (a magic-school spell not exempted from damage-taken modifiers, fed to `script_spell_damage_taken` as a stand-in hit), `levels` (a list of `[health_pct, expected_ratio]` pairs, one `Expectation` per pair); `duration`: `target_aura` (the aura whose `aura_duration_ms` is read before and after one forced melee crit), `expected_ms` (the milliseconds the quote states, added on top of the one swing interval that elapses naturally), `debt_aura` (the real absorb aura that must carry a nonzero debt amount before the crit, so the forcing fixture exercises the real damage-absorb hook instead of a bare `set_aura`), `breaker_spell`/`striker_entry` (the spell and creature template entry that deplete `debt_aura` deterministically before the measured crit), `mechanism_file`/`override_file`/`reduce_function` (free text naming the server source file that resets the duration, the file that overrides the aura's periodic base points, and the function whose early-removal branch the debt fixture must avoid triggering for the wrong reason — generated into the scenario's own `contract` field, so each class supplies its own instead of the builder hardcoding one class's names); `duration_ratio`: `vehicle_spell` (a stock, non-class spell whose own mechanic the passive's `SPELL_AURA_MECHANIC_DURATION_MOD` effect targets, cast by a striker at the caster once before and once after the passive is learned), `striker_entry` (a creature template entry, default 36) |

`behaviours.py`'s `behaviour_scenario(class_file, entry)` dispatches on `kind` to a scenario builder shaped like
`passives.passive_scenario` (base steps, measure "before," `learn`, measure "after"), with a kind-specific measure
step instead of a stat-sheet read. `conformance.py generate --behaviour <spell>` selects one or more entries by
spell id; with no filter, every class behaviour entry is generated.

### Target-count scenarios (`behaviour_count`)

The scenario places `expected + 1` creature fixtures (one "primary," `expected` "extra") along the caster's fixed
spawn axis, the primary at 3 yards and the extras spread within `radius` yards of the primary (the harness places
every creature fixture at `owner position + (distance, 0, 0)`, `CoAGameplayTest.cpp` `CreateTargets`, so creatures
at different `distance` values share the same line). It learns `target_rank` once up front, before the first
cast (matching the pattern `hits.py` and `values.py` already use for their own cast targets, since the reference
character is created directly at level 60 and a cast of an unlearned spell is silently dropped by
`HandleCastSpellOpcode` rather than failing loudly), then casts it at the primary `repeats`
times (5, "ever hit at least once" per dummy rather than a single-cast snapshot, since neither this package nor a
probe established that the harness's AoE or chain targeting hits every dummy in range on one cast), measures
`spell_damage_count {spell, target}` per dummy (or, for an entry whose `metric` is `aura`, `aura {spell, caster}`
read on the dummy itself, for a target spell whose own effect is not a school-damage hit), learns the passive,
repeats the casts and the measurement. The
judge (`compare.behaviour_count_verdict`) counts, among the extra dummies only, how many were hit before the learn
and how many were newly hit after (`after - before > 0`), then judges that count delta against `expected` on the
delta scale (`compare.delta_status`): `ok` when `|delta - expected| <= max(1, 0.5% of expected)`, *except* that a
measured delta of exactly 0 against a nonzero `expected` is always `alert`, never `ok`, even though it would fall
inside that margin (`compare.delta_status`'s explicit zero-vs-nonzero guard); `unmeasured` when an extra dummy was
already hit before the learn, since the delta cannot then be isolated.

### Healing-ratio scenarios (`behaviour_ratio`)

Each `targets` entry is either a 2-element `[rank_id, name]` (method `"cast"`, the default) or a 3-element
`[rank_id, name, {"method": "effect_value", "effect": N}]`. A `"cast"` target is cast at the caster, then measured
with `spell_healing_done {spell, target: caster}`, for each phase; an `"effect_value"` target is never cast at all
— it is measured directly with `spell_effect_value {spell, effect}` before and after the passive is learned, for a
doubling that is fully determined by the target spell's own `SpellEffectInfo::CalcValue` (a `SPELLMOD_EFFECT1`-style
percent modifier applied while computing the effect's amount) rather than by anything that shows up only once the
spell is cast and ticks. Both methods feed the same `Expectation` shape (`before_label`/`after_label`/`expected`/
`quote`/`target_name`), so the judge below needs no per-method branch. The judge (`compare.behaviour_ratio_verdict`)
computes `ratio = after / before` for reporting, but judges the *delta* (`after - before`) against the delta the
expected ratio implies (`before * (expected_ratio - 1)`), on the metric's own scale rather than the ratio scale:
`ok` when `|delta - expected_delta| <= max(1, 0.5% of |expected_delta|)`, with the same zero-vs-nonzero guard as
`behaviour_count` (a measured delta of exactly 0 against a nonzero expected delta is always `alert`); `unmeasured`
when the before measurement is 0 or less, since a ratio needs a positive baseline.

### Aura-spread scenarios (`behaviour_count`, `kind: "spread"`)

`target_count_scenario`'s `aura` metric always reads the *cast* spell's own aura, which does not fit a passive
whose claim is that a different active's damage copies a *pre-existing, independent* aura onto a nearby target
(Holy Tempest 301339: Righteous Tempest's damage spreads Condemn, not Righteous Tempest's own aura). `behaviours.py`
adds a second, additive builder for this shape rather than overloading `TargetCountSpec`'s contract: `AuraSpreadSpec`
names `seed_spell` (cast on the primary dummy before each `target_rank` cast, to install the aura that must spread),
`aura_spell` (the aura id measured on every extra dummy; usually the same spell as `seed_spell`) and `target_rank`
(the active whose damage triggers the copy) separately. `aura_spread_scenario` learns both `seed_spell` and
`target_rank` once (talent-chain ranks this deep are not granted by the reference character automatically, unlike
some lower active ranks reused by other `behaviours` entries), then per phase and per repeat: casts `seed_spell` at
the primary dummy, waits past its cast time, waits one explicit global-cooldown interval, casts `target_rank` (no
explicit target: its own implicit targeting is "nearby enemies"), and waits its full periodic-buff duration
(`Records.duration_ms(target_rank)`) before the next repeat. It then measures `aura {aura_spell, caster}` on every
extra dummy only, never re-measuring the primary (its own copy of `seed_spell`'s aura is a setup fact, not part of
the behaviour under judgment). The resulting `Expectation` is shaped exactly like `target_count_scenario`'s, so
`compare.behaviour_count_verdict` judges it with no change: `ok` when every extra dummy gains the aura between the
before and after phase, `alert` on a measured 0 against a nonzero `expected` (the absent-effect case this check
exists to catch), `unmeasured` when an extra dummy already carries the aura before the passive is learned.

### Shield-break trigger scenarios (`behaviour_trigger`)

This is the first `behaviour_trigger` entry: a tooltip claim that is a scripted "always fires" cast, reachable
only from an `AfterEffectRemove`-style hook, not from `triggers.py`'s native `EffectTriggerSpell` path (that path
only recognises a cast or a swing the caster performs, `triggers.py:47-53`; here the triggering action is damage
*taken*, consumed by an absorb shield). `ShieldBreakTriggerSpec` names `shield_aura` (the absorb aura that must be
fully depleted), `trigger_spell` (the spell the break casts), `breaker_spell` (a spell of the absorb's own school,
cast directly by the striker at the caster, that reliably exceeds the absorb amount), `striker_entry` (a creature
template entry to cast it from) and `break_timeout_ms` (how long to wait for the aura to clear once the breaker
spell lands). `shield_aura`'s own `SchoolMask` decides what `breaker_spell` must be: a generic hostile creature's
melee is Physical and a `SPELL_AURA_SCHOOL_ABSORB` only intercepts its own school (confirmed empirically for
Staffguard 706583, Holy-only: a melee-only striker left its 8-second duration to expire untouched every time,
`without`/`with` elapsed consistently ~7980 ms regardless of real melee damage landing on the caster, never from
an `AURA_REMOVE_BY_ENEMY_SPELL` absorption), so a melee swing can never satisfy this check and a Holy nuke
(Smite 48123 here) must be cast directly at the caster instead. `shield_break_trigger_scenario` spawns one
"striker" fixture, then runs two phases, once without the passive known and once with it: apply `shield_aura`
fresh (`set_aura`), measure `spell_damage_count {trigger_spell, target: striker}` on the caster, have the striker
`cast` `breaker_spell` directly at the caster (the harness's own creature-cast action, bypassing AI pathing and
its timing variance entirely), wait `CAST_SETTLE_MS` (500 ms: the aura-removal callback was observed to still be
mid-flight on the very next assert without this wait, intermittently failing `the shield is fully consumed` even
though the cast had already landed), then assert `shield_aura` is fully gone (`metric: "aura", equals: 0`) within
`break_timeout_ms` (real incoming damage consuming the shield, not an expiry or a manual cancel), and measure
`spell_damage_count` again. The passive is `learn`ed between the two phases. The judge
(`compare.behaviour_trigger_verdict`) computes `without_delta` and `with_delta` (the after-minus-before
`spell_damage_count` of each phase): `ok` only when `without_delta == 0` (the damage never fires without the
passive known) **and** `with_delta >= expected` (it fires at least once, the one time the shield broke, with the
passive known); `alert` when `without_delta > 0` (the damage fires even without the passive, contradicting the
tooltip's gating) **or** `with_delta == 0` (the passive is known but the break never casts the trigger spell -
the absent-effect case this check exists to catch, since a zero effect must never read as `ok`).

### Metric-delta scenarios (`behaviour_metric_delta`)

Some prose passives change a quantity none of the shapes above fit: not a count of targets hit, not a healing
ratio, not a scripted "always fires" trigger, but a plain before/after read of a metric the harness already
exposes for other purposes (how many of a summon creature entry the caster owns, the computed amount of an
aura effect, ...). `metric_delta_scenario` learns `trigger_spell` once up front (the active spell a reference
character this deep in a talent chain is not otherwise granted, the same reason `aura_spread_scenario` learns
its own actives explicitly), casts it, waits `wait_ms`, measures `metric` with `fields` ("before"), `learn`s
the passive, waits `expire_ms` (long enough for the first cast's effect to fully expire, so a still-alive
summon or a still-ticking aura from the "before" phase cannot leak into the "after" reading), casts
`trigger_spell` again and measures again ("after"). The judge (`compare.behaviour_metric_delta_verdict`) checks
both reads by exact equality, not the shared tolerance-margin scale the other behaviour judges use: `ok` only
when `before == before_expected` **and** `after == expected`; `alert` otherwise, including when `before` alone
is wrong (an implementation that gets the delta right from a wrong baseline is still caught) and when `after`
is off by as little as one unit, since the shared margin's floor of 1 absolute unit would otherwise mask the
exact failure this check exists to catch (a modifier of +1 silently not applying). Exact equality is sound here
specifically because both metrics are deterministic integer reads taken with no combat in flight, unlike the
live combat-roll pipeline behind `melee_damage_taken`/`spell_damage_taken`, which does need a tolerance band.

### Health-threshold ratio scenarios (`behaviour_ratio`, `kind: "health_ratio"`)

Some passives state a ratio that only applies while the caster's own health sits above or below a threshold
("while above 80% health or below 20% health, ..."), a condition `healing_ratio_scenario`'s single before/after
pair cannot exercise, since it never varies the caster's health and a passive that always applied the ratio
would pass it just as well as one that gates it correctly. `health_threshold_ratio_scenario` instead sets the
caster's health with `set_health` (`actor` the caster, `maximum` fixed at 10000 so each `levels` percentage maps
to a round `value`) to each `levels` percentage in turn and measures `script_spell_damage_taken {spell:
probe_spell, target}` on the `dummy` fixture right after, once per level before the passive is learned and once
per level after. `script_spell_damage_taken` calls `ScriptMgr::ModifySpellDamageTaken` directly on a fixed probe
amount (1000), the same `UnitScript` hook a real hit of `probe_spell` would invoke, without needing a live caster
to actually land one. One `Expectation` per `levels` pair reuses `compare.behaviour_ratio_verdict` unmodified
(`before_label`/`after_label` naming that level's before/after measurement, `target_name` the health percentage):
`ok` when the measured damage delta matches `before * (expected_ratio - 1)` on the damage scale; `alert` on a
measured ratio of 1.0 (no change) against a `levels` entry whose `expected_ratio` is not 1.0 - the absent-effect
case this check exists to catch, since nulling the gate's health check or its aura check both collapse to this.
A `levels` entry with `expected_ratio` of exactly `1.0` (the mid-health case where neither threshold applies) is
what proves the gate itself is being tested, not just the reduction: a scenario that only measured the reduced
levels could not tell "the ratio is right" apart from "the ratio applies unconditionally."

### Leech-ratio scenarios (`behaviour_ratio`, `kind: "leech_ratio"`)

`healing_ratio_scenario`'s no-combat probe (`spell_healing_done`) never reaches `SpellEffectInfo::CalcValueMultiplier`,
the pipeline a `SPELLMOD_VALUE_MULTIPLIER` passive modifies, and its cast always targets the caster, which a hostile,
health-gated rank (Titanstrike) would refuse outright. `leech_ratio_scenario` instead casts the rank for real, once
before the passive is learned and once after, each at its own dummy (`set_health_pct` cannot raise health back up,
so the same dummy could not take a second cast once the fixture or the first cast's leech has already lowered it),
and measures the real `spell_damage_total` and `spell_heal_total` (`HealBySpell` always heals the caster, regardless
of the cast's target) of that one cast. Both effects of a `SPELL_EFFECT_HEALTH_LEECH` spell share the same random
roll (the heal is computed from the resolved, already-mitigated `damageInfo.damage`), so their ratio is exactly
deterministic once two measurement effects specific to this metric are accounted for:

- `spell_heal_total` sums every matching heal event since the scenario started, not since the last measurement, so
  the "after" phase's reading also carries the "before" phase's heal (the two casts heal the same caster with the
  same spell id). `leech_ratio_verdict` (`compare.py`) subtracts a `heal_baseline_label` (the "before" phase's own
  heal label; `null` for the "before" phase itself, which is naturally the first heal of the scenario) before
  computing the ratio.
- `Spell.cpp`'s health-leech handling computes the heal from `damageInfo.damage`, which already carries the
  reference character's own damage-done percent modifiers (`known_auras`, aura 341), then applies the healing-done
  percent modifiers of the same auras again on top (aura 136, through `SpellHealingBonusDone`/`Taken`) before
  calling `HealBySpell`. The two percents do not cancel against the recorded damage total, so the ratio the scenario
  can actually measure is `healMultiplier x heal_done_factor`, not `healMultiplier` alone.
  `leech_heal_modifier_factor` folds every known `heal`-side `Modifier` (`hits.aura_modifiers`) into the spec's
  `expected_before`/`expected_after` at scenario-build time, the same way `rank_hit` folds known auras into a
  `hit_mean` model, so the expected value stays DBC-plus-known-modifier derived, never invented.

`leech_ratio_verdict` reuses `behaviour_ratio_verdict`'s delta-on-the-damage-scale judging (`compare.py`):
`ok` when `|actual_heal - damage| <= max(1, 0.5% of damage x (expected - 1))`, `alert` otherwise, including a
measured 0 against a nonzero expected delta. Templar: Titanfall 300607 against Titanstrike 806835, expected 1.0
(no Titanfall) and 2.0 ("twice the damage dealt") before the known-modifier factor.

### Duration scenarios (`behaviour_duration`)

Some prose passives state a flat change to another aura's remaining duration ("removes 1 sec from the duration
of X"), gated on a condition — here, a critical strike — that neither `behaviour_count`/`behaviour_ratio`'s
no-combat before/after casts nor any existing `run.py` action can force directly: there is no "guarantee the next
swing crits" action or metric. `duration_scenario` forces the condition instead of adding one: it overrides the
scenario's own player fixture (not the shared class-file `ratings` other scenarios reuse) with an absurd
`melee_crit_rating` (100000), which drives `Unit::RollMeleeOutcomeAgainst`'s crit roll past 10000 (centipercent)
and guarantees the crit branch wins, once the fixture's existing `melee_hit_rating`/`expertise_rating` have
already suppressed miss/dodge/parry/glancing/block/crushing for other scenarios in this class file. The scenario
`learn`s the passive, `set_aura`s the target aura (`stacks: 1`, giving it its DBC `SpellDuration` on application),
measures `aura_duration_ms` ("before"), `attack`s a plain dummy, waits `CAST_SETTLE_MS` (500 ms, reused from the
shield-break scenario's own "let an async effect land" wait), `stop_attack`s, then measures `aura_duration_ms`
again ("after") and `melee_damage_count {hand: 0, critical: true}` as a sanity count of the forced crit. The wait
is `CAST_SETTLE_MS`, not the weapon's own `swing_interval(class_file)`, because starting an attack was observed
(an exploratory `coa-verify --ram` run of this exact scenario) to land its first swing immediately: a
`swing_interval`-length wait measured **two** crits, one essentially instant and one at the weapon's normal
speed, not one — `duration_scenario` therefore refuses to build at all (`NotModelled`) for any class whose
`swing_interval` does not comfortably exceed `CAST_SETTLE_MS`, rather than silently risk the same double-swing on
a faster weapon. The judge (`compare.behaviour_duration_verdict`) first checks the sanity count: anything other
than exactly 1 is `unmeasured`, not `ok` or `alert` — the forcing assumption, not the passive, failed (a miss, a
`CREATURE_FLAG_EXTRA_NO_CRIT` dummy, or the double-swing above, must never silently pass as a non-event or a false
alert). Only once exactly one crit is confirmed does it compute `measured = before - after` and judge it against
`expected = wait_ms + expected_ms` (the natural elapsed time of the wait, which the engine's own duration
decrement removes regardless of the passive, plus the claimed extra milliseconds): `ok` when
`expected - CAST_MARGIN_MS <= measured <= expected + run.max_step_ms` (the lower side is the one-sided window
`judge_time` uses for a wall-clock delta: the server can only lose *at least* the natural elapsed time, never
less; the upper side adds `run.max_step_ms`, the harness's own per-run tick-overshoot bound, because a `wait`
step's actual elapsed time can only round *up* from its nominal `ms`, never finish early, so a correct,
exactly-`expected_ms` fix still measures slightly more than `expected` on a real run), `alert` otherwise —
including exactly `wait_ms` with no extra milliseconds at all, the absent-effect case this check exists to
catch, and any overshoot beyond `run.max_step_ms`.

Templar's own Sacred Oath 712346 scenario (`coa-verify --ram --stages gameplay`, the same exploratory run that
surfaced the double-swing above) measured 2 forced crits, not 1, inside the original `swing_interval`-length wait
— `after` read `0` because the second `ReduceDebt` call emptied Oathkeeper 803237's tiny debt amount and removed
the aura outright (`AscensionTemplar.cpp`'s `if (reduction >= amount) aura->Remove();` branch), not because
anything set its duration directly. This matches the investigation's reading of `ReduceDebt`/`Tick` (neither
calls `SetDuration`) but by a more dramatic path than "no effect at all": a crit can destroy Oathkeeper early
through debt depletion, never shorten its timer the way the tooltip's "removes 1 sec" literally describes. The
fix (`CAST_SETTLE_MS` instead of `swing_interval`) isolates exactly one crit so the check measures the single-crit
claim the tooltip actually makes.

### Mechanic-duration-ratio scenarios (`behaviour_duration_ratio`, `kind: "duration_ratio"`)

`SPELL_AURA_MECHANIC_DURATION_MOD` (232) and `SPELL_AURA_MOD_DEBUFF_RESISTANCE` (178) are generic engine aura
types `passives.py` classifies as family `P6` ("scripted or crowd-control effect") because their handlers are
no-ops in `SpellAuraEffects.cpp` (`HandleNoImmediateEffect`): the real consumer is `Unit::ModSpellDuration`
(mechanic duration mod, called from the live cast path, not the passive's own effect handler) or
`Unit::MagicSpellHitResult` (debuff resistance, a hit/miss roll contribution). Neither is reachable from a
no-combat before/after stat read, but both are reachable through a real cast: `mechanic_duration_scenario`
has a striker (creature entry `striker_entry`, `spell_hit_bonus` forced to 100 so the vehicle cast itself is
never the missing variable) cast `vehicle_spell` — a stock, non-class spell whose own effect mechanic matches
the passive's `EffectMiscValue` (e.g. `MECHANIC_DISARM`, `MECHANIC_SNARE`) — directly at the caster, once before
the passive is learned and once after, reading `aura_duration_ms` of `vehicle_spell`'s own applied aura
`CAST_MARGIN_MS` (500 ms) after each cast. The two casts are separated by `vehicle_spell`'s own DBC duration
plus 15000 ms plus a margin (`records.duration_ms(vehicle_spell) + MECHANIC_DR_RESET_MS + MECHANIC_GAP_MARGIN_MS`
in `behaviours.py`): most of these mechanics (disarm, snare without the disoriented exception, ...) carry their
own stock diminishing-returns group against a player target (`SpellMgr.cpp`'s `GetDiminishingReturnsGroupType`
defaulting non-exempt groups to `DRTYPE_PLAYER`), so a second application inside that window would read a
diminished, not a full or passive-reduced, duration on either side of the comparison.

The judge (`compare.behaviour_duration_ratio_verdict`) computes `ratio = after / before` and
`expected_delta = before * (expected_ratio - 1.0)`: `unmeasured` when `before <= 0` (a ratio needs a positive
baseline — the vehicle cast landed nothing to read, the forced-hit fixture's own absent-effect case); `alert`
when `measured` (`after - before`) is 0 against a nonzero `expected_delta` (the absent-effect case the check
exists to catch); `ok` when `|measured - expected_delta| <= CAST_MARGIN_MS + run.max_step_ms`, `alert` otherwise.
The margin is sized on the full settle window rather than a small fraction of the expected delta because the
two `aura_duration_ms` reads are each taken a fixed wall-clock wait after their own cast, not a fixed number of
milliseconds into the aura's own remaining-duration countdown (missile travel time and tick scheduling both
vary slightly run to run); that per-read jitter is amplified by the ratio itself
(`ratio * elapsed_before - elapsed_after`), which an exploratory `coa-verify --ram` run of this exact scenario
measured at up to ~100 ms for Courage's -20% rank — within `CAST_MARGIN_MS`, comfortably outside the shared
delta-margin scale's usual 0.5%-of-expected floor.

### Templar entries

| Passive | Kind | Quote | Expected | Mechanism |
|---|---|---|---|---|
| Scarlet Judicator 525024 | count | "strikes 2 additional enemies near the primary target" | 2 | Divine Force 807805's school-damage effect (`TARGET_UNIT_TARGET_ENEMY`, `DmgClass` 2/melee) always routes through `Spell::SelectImplicitChainTargets` (`Spell.cpp:1905-1923`), which applies Scarlet Judicator's `SPELLMOD_JUMP_TARGETS` flat modifier to `ChainTarget` and searches a 10-yard jump radius for a melee spell with no `JumpDistance` override (`Spell.cpp:2200-2213`) |
| Justice 712437 | count | "strikes 1 additional nearby target" | 1 | scripted hook `templar_casts::OnSpellBeforeEffects` (`AscensionTemplarAbilities.cpp:95-102`): casting Interdict 560116 with Justice known adds exactly one unit from `Nearby(primary, 8.0f)`; the DBC's own effect 1 (`PROC_TRIGGER_SPELL` to 712364, Sacred Oath's own trigger) does not implement this sentence at all and is not used |
| Final Prayer 705268 | ratio | "Doubles the healing done to you" | 2.0 | two named targets: Testament of Faith 801478 (a direct heal, `SPELL_AURA_MOD_HEALING_RECEIVED` taken-side, method `"cast"`, measured with `spell_healing_done`) and Testament of Fortitude 500678 (a `SPELL_AURA_PERIODIC_TRIGGER_SPELL_WITH_VALUE` self-heal whose doubling is a `SPELLMOD_EFFECT1` percent modifier read inside its own effect-0 `CalcValue`, needing no cast at all, method `"effect_value"`, measured with `spell_effect_value {spell: 500678, effect: 0}`) |
| Holy Tempest 301339 | spread | "spreads Condemn on affected enemies to a nearby enemy" | 1 | `AscensionTemplarAbilities.cpp:294-295` (`OnSpellHitResult`): on a confirmed hit of Righteous Tempest's periodic damage (ranks `805410`/`570200..570205`) with the passive known, `AscensionTemplar.cpp:224-257` (`SpreadCondemn`) copies the Condemn aura already present on the hit target onto the first valid, non-already-afflicted, line-of-sight enemy within `Nearby(target, 10.0f)` - a hardcoded radius, not read from any DBC field |
| Armor of Faith 804930 | trigger | "Whenever the absorption shield from Staffguard breaks, inflict" | 1 | `AscensionTemplarAuras.cpp:213-216` (`aura_ascension_templar_lifecycle::Remove`): when Staffguard 706583's absorb effect is fully depleted (`GetAmount() <= 0`) by `AURA_REMOVE_BY_ENEMY_SPELL` (an enemy's own damage, not an expiry or manual cancel) while the player is alive and knows 804930, it casts Armor of Faith's damage spell 801546 on the player, whose own nearby-enemy Holy damage effect then lands; the amount stays the pre-existing `$801546ppl1` open conformance check (`questions.md:368-374`), unchanged by this entry. Staffguard's absorb is Holy-only (`SchoolMask` 2), so the scenario's striker casts Smite 48123 (`breaker_spell`) directly at the caster rather than swinging at it |
| Tyr's Guard 560649 | metric_delta | "now summons an additional copy of yourself" | 3 | a plain stock `SPELLMOD_EFFECT1` aura (effect 2 of 560649, `EffectSpellClassMask[6]` matching Testament of Hope 1397742's family flags): the engine's own `Player::ApplySpellMod`/`SpellInfo::CalcValue` path adds 1 to Testament of Hope's summon effect's base points (1 -> 2, `CalcValue` 2 -> 3) with no CoA-specific code involved; `owned_creature_count` of the copy entry 50250 is the metric, before (2, no 560649) and after (3, 560649 learned) |
| Spiritual Abdicator 803219 | metric_delta | "reduces damage taken by an additional 5% per copy" | -15 | `AscensionTemplarContracts.cpp:278-281` (`templar_scaling::ModifySpellEffectBaseValue`): when the copy's owner (the Templar) has aura 803219, the copy's own owner-area aura 704409 effect 1 (`MOD_DAMAGE_PERCENT_TAKEN`, base `CalcValue` -10, confirmed by the existing Testament of Hope regression scenario) is overridden to -15 at load, the "additional 5%" the tooltip states on top of 704409's own 10%; 803219's own effect 0 is a pure marker (`dummy()` rewrites its `ApplyAuraName` to `SPELL_AURA_DUMMY` at load, no gameplay value of its own); `aura_amount` of spell 704409 effect 1 is the metric, before (-10, no 803219) and after (-15, 803219 learned) |
| Battlepriest 801202 | health_ratio | "take 20% reduced Magic damage" | 0.8 at 90%/10% health, 1.0 at 50% | the DBC's own mechanism (a periodic trigger casting a conditional `MOD_DAMAGE_PERCENT_TAKEN` aura, `CasterAuraState`-gated on `AURA_STATE_HEALTHLESS_20_PERCENT`/`ASCENSION_TARGET_HEALTH_ABOVE_80_PERCENT`) is `dummy()`-nulled at load (`AscensionTemplarContracts.cpp:151-154`); the real implementation is a direct multiplier in `templar_scaling::Mitigation` (`AscensionTemplarContracts.cpp:242-255`), `factor *= .8f` when the school is magic and the player both knows 801202 and is strictly above 80% or strictly below 20% health (`Unit::HealthAbovePct`/`HealthBelowPct`), called from `ModifySpellDamageTaken`/`ModifyPeriodicDamageAurasTick`/`ModifyMeleeDamage`'s hooks; `script_spell_damage_taken` with `probe_spell` Fireball 133 (magic school, no `TemplarCopies` attribute exemption) exercises the same `ModifySpellDamageTaken` hook the real pipeline uses |
| Titanfall 300607 | leech_ratio | "now heals you for twice the damage dealt" | 1.0 before, 2.0 after (before the known-modifier factor) | a plain data-driven `SPELLMOD_VALUE_MULTIPLIER` (`EffectMiscValue` 27) `ADD_PCT_MODIFIER` passive on Titanstrike's family mask (`EffectSpellClassMask` bit 4, `SpellFamilyName` 25), `EffectBasePoints` 99 (+100%); Titanstrike's own `SPELL_EFFECT_HEALTH_LEECH` effect has `ValueMultiplier` 1.0, run through the generic `Player::ApplySpellMod(SPELLMOD_VALUE_MULTIPLIER)` pipeline (`SpellInfo::CalcValueMultiplier`, `Spell.cpp:2929`) with no CoA-specific code involved; Titanstrike also requires its target below 35% health (`TargetAuraState` 13, `AURA_STATE_HEALTHLESS_35_PERCENT`, a flag `Unit::Update` recomputes every tick from current health, not a settable aura) |
| Sacred Oath 712346 | duration | "remove 1 sec from the duration of" | 1000 ms on top of the `CAST_SETTLE_MS` wait | `spell_proc` row for 712346 (`rev_20260909_04_templar_completion.sql`): `ProcFlags` 1048575, `Chance` 100, overriding the DBC's own `ProcFlags` 0; `aura_ascension_templar_event::Check` case 712346 (`AscensionTemplarEvents.cpp:84-85`) requires `damage && crit && player->HasAura(803237)`; `::Proc` (line 169-170) calls `ReduceDebt(player, 0, true)`, which only ever calls `effect->ChangeAmount(...)` on Oathkeeper 803237's own debt effect or, if the one-tick share would exceed what remains, `aura->Remove()` — it never calls `aura->SetDuration(...)`. An exploratory `coa-verify --ram` run confirmed this reading: with two forced crits in one window, `aura_duration_ms` read `0` (the aura removed outright by debt depletion), not `-1000` beyond the natural decay; a crit's own contribution to the aura's remaining duration is the debt-tick side effect described above, never a direct shortening of the timer the tooltip's "removes 1 sec" literally claims. The harness forces the striker's `spell_hit_bonus` to 100 so the debt-settle assert cannot flake on a missed Smite swing (round3/sacred-oath-flaky-spec.md; round2 misdiagnosed this as a wait-margin issue) |
| Finesse (Rank 1) 705271, effect 1 | duration_ratio | "reduces the duration of disarm effects against you by" | 0.85 | stock engine `SPELL_AURA_MECHANIC_DURATION_MOD` (232), `EffectMiscValue` 3 (`MECHANIC_DISARM`), no CoA code involved; vehicle Melt Weapon 301235 (`Mechanic` 3, `DurationIndex` 32 = 6000 ms), the striker's disarm landing on the caster's own equipped weapon (`class_file`'s `weapon`, already equipped by `base_steps`) |
| Finesse (Rank 2) 707851, effect 1 | duration_ratio | "reduces the duration of disarm effects against you by" | 0.70 | same mechanism and vehicle as Rank 1 |
| Courage (Rank 1) 707754, effect 1 | duration_ratio | "reduces the duration of movement slowing effects on you by" | 0.90 | stock engine `SPELL_AURA_MECHANIC_DURATION_MOD` (232), `EffectMiscValue` 11 (`MECHANIC_SNARE`), no CoA code involved; vehicle Hamstring 1715 (`EffectMechanic[0]` 11, `DurationIndex` 8 = 15000 ms); `MECHANIC_SNARE` is exempted from `ModSpellDuration`'s duration-mod reduction only when the applied spell's own mechanic mask also carries `MECHANIC_DISORIENTED`, which Hamstring does not |
| Courage (Rank 2) 712466, effect 1 | duration_ratio | "reduces the duration of movement slowing effects on you by" | 0.80 | same mechanism and vehicle as Rank 1 |

The 10-yard and 8-yard fixture radii above are both read from server source, never guessed, per each entry's own
`radius_reason`.

## Player observations

A class file's `player_observations` entry is `{"spell", "name", "date", "citation", "claim", "corroborates"}`: a
player's report of how a spell behaves on the CoA production server (this fork's own code, possibly a different
commit; never Ascension's own, closed live realm). `citation` is always `"player report <date>"`, with no
character or player name ([no raw log lines or names rule](../../../AGENTS.md)), and `date` must match it;
`checked_observation` (`observations.py`) raises otherwise. `claim` is the player's own observation in prose.
`corroborates` names the `label` of the verdict it bears on — a `report.md`/`verdicts.json` label such as
`"706325 proc_rate"` or `"520608 e1"`, not a spell id alone, since several labels can share a spell.

This mechanism is generic and class-agnostic: `compare.py`'s `observation_lines` reads the array from whatever
class file `report.md` is built from and prints each entry beside the *current* status of the verdict it names,
without knowing anything about Templar or any other class's spells. A player observation never sets an expected
value, never settles a verdict and never picks a tooltip reading on its own ([ADR
0025](../../../docs/adr/0025-player-observations-corroborate-never-settle-a-verdict.md)): it is prose evidence
that a verdict's `ambiguous_tooltip`/`unmodelled` status, or its chosen reading, holds (or does not hold) on the
production server, read beside the DBC-derived expectation the run already judges. When `corroborates` names a
label the current run does not carry — because the scenario that would measure it has not been written yet, or
its name changed — the row says so (`label not in this run`) instead of silently matching nothing, so a stale
citation is visible rather than hidden.

## Player tooltip readings

A class file's `player_tooltip_readings` entry is `{"spell", "token", "value", "ap", "sp", "citation", "note"?}`:
a tooltip *number* the client showed a player at a stated attack power and one or two candidate spell powers
(`sp` a list; empty when the formula has no spell-power term). It is a different mechanism from "Player
observations" above (behaviour, never a number): `citation` is validated the same way
(`tooltip_readings.checked_tooltip_reading`), but `spell`+`token` (not `corroborates`) is the key, matched against
the exact `$`-token text of a now-readable `${...}` expression ([ADR
0031](../../../docs/adr/0031-ppl-tokens-scale-by-actual-level-not-skill-rank.md)). It is read-only evidence from
production, never an expected value: the no-combat `effect_value`/`hit_mean` check already judges the token
against the DBC formula evaluated at the harness's own reference caster, unaffected by which spec or gear the
player's screenshot was taken under.

Two generic, class-agnostic uses, both read-only:

- `compare.py`'s `unreadable_question` looks up `(rank_id, entry_token)` in the class file's
  `player_tooltip_readings` before building a `tooltip_value`/`data_issue` question for a still-unreadable entry;
  a match stops that question from being asked again (the citation already answers it), without changing the
  verdict's `unreadable` status.
- `report.md`'s "Player tooltip readings" section (`tooltip_reading_lines`) re-evaluates the *same* token against
  the reading's own `ap`/`sp` (one value per `sp` candidate, re-reading `tooltips.read` with a synthetic
  level-60 `CasterStats` at that `ap`/`sp`) and reports the resulting band next to the run's measured value for
  that label: `ok` when the measured value falls in the band (± the existing flat tolerance), `alert` otherwise,
  `label not in this run` when the scenario that would measure it has not been generated. This is corroboration
  only: it never feeds `judge_expectation`, and a `band unreadable` row means the token could not be re-evaluated
  (not a verdict).

Templar's 7 entries (`classes/templar.json`) cite the 2026-11-07 player report for Force of Golganneth,
Norgannon's Wrath, Divine Charge, Eternal Blessing, Libram of Consecration, Silverhand Incantation and Armor of
Faith; each `note` states which candidate spell power the reading fits, or that it fits neither exactly. Argent
Blade/Scourgebane's `scalingbp` reading (report of 280 Holy) is deliberately **not** cited here: evaluated at
either candidate spell power it comes out 260-330 points higher than reported, so citing it would read as model
confirmation it is not; it stays an open conformance check instead (`questions-round3.md`).

## Talent stack (lever map)

The class file's `rotation` is a fixed sequence, `stack` the configurations that add talents to it one group at a time,
and `talent_modifiers` the talents whose tooltip states a change of one damage source:

| Field | Content |
|---|---|
| `rotation.learn` | the spells every configuration learns (Templar: Argent Blade 807268, Scourgebane 92111) |
| `rotation.set_power`, `auto_attack` | the power set before the rotation, and auto attacks from its start to its end |
| `rotation.cycle`, `cycles` | the steps of one cycle (a cast at `dummy`, a wait) and their repetitions |
| `rotation.drain_ms` | the wait after the last cycle, before the measurements |
| `rotation.sources`, `cast_sources` | the spells whose damage is measured, and those whose casts are counted |
| `stack[].name`, `talents` | a configuration and the talents it adds to every earlier one |
| `talent_modifiers` | `talent`, `name`, `tooltip`, `token`, `source` and its `source_text`, `question`; see below |

The Templar rotation, configurations and talents are those of the measurements of 2026-11-05
(`.agents/plans/class-spell-audit/stacking-scenarios/c0_base.json` to `c7_scarlet.json`): 120 cycles of a cast of Argent
Blade and a 1000 ms wait under auto attack, 100 Energy at the start, a 3000 ms drain, and the configurations c0 (no
talent), c1 Paladin Training 520009, c2 Divine Strikes 705255, c3 Light's Echo 520017 and 520883, c4 Warrior of Dawn
560648 and Scourge-Defense Training 520608, c5 Retribution 707391, c6 Legacy of the Silver Hand 806522 and Pure Focus
705253 and 707852, c7 Scarlet Training 301065, Scarlet Secrets 520812 and Martial Training 806525. The scenarios use
the package's base steps (weapon equipped and stats measured before the learns), so the steps come in a different
order from the files of 2026-11-05.

`stack_scenarios` writes `passes` scenarios per configuration, each named `... <config> pass <n> of <passes>`, that
learn the rotation spells and every talent of the configuration and the earlier ones, measure the health of `dummy`,
run the rotation, measure its health again after the drain, then per source the damage and hit count on `dummy` of
every hit and of the non-critical, unblocked hits (`spell_damage_*`, `melee_damage_*` for the auto attacks), and the
casts of the cast sources. Fewer than 2 passes give no interval and are refused. Each pass carries:

- `stack <config> dps` (`stack_dps`): the health the target lost per second of rotation (120 s), so that a source
  missing from `sources` still counts; the difference with the sum of the sources is shown as unattributed.
- `stack <config> source <spell>` (`stack_source`, 0 for the auto attacks): the damage of the source per second.
- `stack <config> talent_delta <talent> <source>` (`talent_delta`) for each `talent_modifiers` entry of a talent
  the configuration adds.

The comparison groups the passes of a configuration. `stack_dps` and `stack_source` are `measured`: the mean of the
passes and its 99% Student t interval (n − 1 degrees of freedom; with 5 passes the quantile is 4.604, not 2.576).
Missing passes are `insufficient_trials`; a source without a hit in any pass after failed casts of it is `unmeasured`
(R11). The rotation presses Argent Blade every second against its 5 s cooldown: in c0 and c1, 96 of its 120 casts per
pass fail with `SPELL_FAILED_NOT_READY` (67). The explanation counts the failed casts per spell and reason.

A `talent_delta` is the change of the mean non-critical, unblocked hit of the source between the configuration and
the previous one, in percent: the ratio of the means of the per-pass hit means, with a 99% interval from the Welch
degrees of freedom and the variance of each mean (delta method). Failed casts lower the hits, not the hit mean. The
expectation comes from the entry:

- `status` (`unmodelled`, `ambiguous_tooltip`) and `reason`: a talent whose change of the source has no fixed amount
  (Divine Strikes: stacks over time; Scourge-Defense Training: the casts after a Warrior of Dawn proc; Martial Training:
  Scarlet Hammer appears only with it) or whose text is unclear (Legacy of the Silver Hand: critical damage of the
  whole hit or of its bonus). Such a delta is never `ok`; an `ambiguous_tooltip` entry has a `question` for players.
- otherwise `claim` (the words of the tooltip) and `dbc` (the effect fields, checked against the client DBC by the
  tests) cite the effect of the talent whose `EffectSpellClassMask` (three words per effect) meets the
  `SpellFamilyFlags` of the source, in the same `SpellFamilyName`; the `token`, read with `read_tooltip`, must be that
  effect's value. The rule is `ratio` only for aura 108 (`SPELL_AURA_ADD_PCT_MODIFIER`) with misc 0
  (`SPELLMOD_DAMAGE`): the tooltip "Increases the damage of <source> by $s1%" and a percent modifier of the spell's
  damage give an expected ratio of hits of 1 + $s1/100. Another aura (Martial Training: aura 107, a flat modifier)
  or a token of another effect is `unmodelled`.

Interactions are not absorbed. A change of the same source by another talent the configuration adds makes the delta
`unmodelled`; a change by an earlier talent whose amount is not a stated percent makes it `ambiguous_tooltip`, since
no text says how the two combine. Neither the tooltip nor the DBC says how the bonus composes with the other percents
of the hit: the damage modifiers of the known auras that apply to the source's school (887007 effect 0, aura 341,
-20%; aura 341 and aura 108 are different mechanisms, not a stated composition) and the stated percents of earlier
talents on the same source (rulings R12, R14). When there are any, the delta has two readings, judged like the proc
readings: `multiplies` (the bonus scales the damage of the previous configuration, the other percents included, so they
cancel in the ratio) and `adds` (the bonus adds to the other percents, 100 × b / (100 + Σ others)). Agreeing readings
give their verdict; disagreeing readings are `ambiguous_tooltip` with both expected values and the measurement, until
the owner rules (ADR 0011). A known aura present in some passes only makes the delta `unmodelled`. The integer steps
of a hit (truncation after a modifier, armor) are not modelled here: each moves a hit by under one point, about 0.1%
of the 1014 measured Argent Blade hit. The bonus is read again with the measured stats: a changed value is an alert.
Fewer passes than generated in either configuration are `insufficient_trials`; no hit of the source in either
configuration is `unmeasured`. An interval whose half-width exceeds 1% of the expected ratio 1 + b/100, the bound of
the hit means (`MEAN_HALF_WIDTH`), is `insufficient_trials` even when it holds the bonus; the explanation gives the
half-width and the passes that would meet the bound, the current passes times (half-width / 1%)², from the observed
variance at the same t quantile.

`levers(verdicts)` gives one `Lever` per configuration in stack order: the DPS mean and interval, its change in percent
from the previous configuration, the DPS of each source and the tooltip bonus of the configuration's single judged
talent delta (`None` otherwise). `levers.md` holds the configurations, the DPS per source and its change, the talent
deltas, the known and probe auras with the runs that measured them, and every pass value. A configuration's DPS change
is marked decisive only when the 99% Welch interval of the ratio of its passes to the previous configuration's
excludes 0 and its half-width is at most 1% of the ratio; otherwise the column says why it is not (a configuration
whose DPS mean is not above 0 has no ratio and is never decisive), and the percent is
no result.

Measured on 2026-11-05 on the worktree server, which does not yet hold PR #11297 (Argent Blade's flat bonus after its
percent), with 5 passes per configuration (stamp `20261105-204050`, simulated clock, gameplay stage 32.5 s for 40
passes of 1.3 s each):

| Config | DPS | 99% interval | Change (not decisive) | Argent Blade | Scourgebane | Retribution | Scarlet Hammer |
|---|---|---|---|---|---|---|---|
| c0 | 298.1 | 289.6 to 306.5 | | 202.8 | 76.2 | 0 | 0 |
| c1 | 333.2 | 328.8 to 337.6 | +11.8% | 244.0 | 70.2 | 0 | 0 |
| c2 | 436.0 | 426.3 to 445.8 | +30.9% | 346.2 | 70.8 | 0 | 0 |
| c3 | 538.8 | 449.6 to 628.0 | +23.6% | 435.4 | 84.4 | 0 | 0 |
| c4 | 701.2 | 568.6 to 833.8 | +30.1% | 587.2 | 95.0 | 0 | 0 |
| c5 | 776.0 | 426.8 to 1125.1 | +10.7% | 605.9 | 90.6 | 60.4 | 0 |
| c6 | 926.7 | 575.8 to 1277.7 | +19.4% | 672.1 | 169.3 | 66.4 | 0 |
| c7 | 1027.2 | 664.5 to 1389.9 | +10.8% | 669.8 | 230.3 | 79.9 | 28.2 |

The auto attacks dealt 19.0 per second in every configuration and nothing was unattributed. Paladin Training raised
the Argent Blade hit by 20.27% (99% interval 19.51 to 21.03, half-width 0.64% of the ratio) against its $s1 of 20:
`multiplies` (20%) is `ok` and `adds` with 887007's -20% (25%) an alert, so the verdict is `ambiguous_tooltip`; a run
of c0 and c1 alone (stamp `20261105-203950`) gave 20.00% (19.22 to 20.78), the same verdict. No DPS change is
decisive: the intervals of c1 to c4 exclude 0 but their half-widths are 2.58%, 2.03%, 16.31% and 18.41% of the
ratio, and the intervals of c5 to c7 hold 0. The procs spread the passes of a configuration (c5: 615 to 1031 per
second).

## Generate and compare

```sh
cd apps/coa-gameplay-test/conformance
python3 -B conformance.py generate --class 19 --out DIR [--spell ID ...] [--passive ID ...] [--proc AURA ...] \
  [--trigger AURA ...] [--stack [--passes N]]
python -B ../../../tools/verify_all.py --stages gameplay --scenario DIR/scenarios/*.json
python3 -B conformance.py compare --manifest DIR/manifest.json --results .cache/verify-all/STAMP [--out OUT]
```

`generate` writes one no-combat scenario per rank, the hit scenario of each active spell's highest rank, the
with/without scenario of each passive (kind `passive`, no `hit` entry), the parts of each proc and trigger entry
and, without `--spell`, `--passive`, `--proc` or `--trigger`, the melee scenario, into `DIR/scenarios/`, and
`DIR/manifest.json`. `--spell` takes a class spell id or a rank id, `--passive` a passive class spell id or rank id
(its passive scenario only; an active spell is an error), `--proc` the aura of a proc entry, `--trigger` the aura of
a trigger entry, `--stack` the passes of the talent stack (`--passes`, 5 by default); each selects only what it
names. A passive scenario is named `conformance-<class>-passive-<rank>`, a proc part
`conformance-<class>-proc-<aura>-part-<n>`, a trigger part `conformance-<class>-trigger-<aura>-part-<n>`, a stack
pass `conformance-<class>-stack-<config>-pass-<n>`. A hit expectation that is entirely
`unmodelled` gets no scenario file. A file holds `json.dumps(scenario, indent=2)` and a newline, the bytes the
runner writes and hashes as `scenario_sha256` (`batch.py` `write_case`), and is named after its exploratory key
(`batch.py` `exploratory_key`), for example `conformance-templar-value-807268`. The manifest keeps the class file,
the DBC directory, the known modifiers read from `Spell.dbc` and, per scenario, its key, file, SHA-256, spell, rank,
the tooltip tokens read at generation and its `Expectation` list.

`compare` reads `STAMP/gameplay/exploratory/<key>/result.json`, or the result folder whose recorded hash is the
manifest hash when no folder has the key. The recorded hash is `scenario_sha256` of the folder's `summary.json`
(or the hash of its `scenario.json`). A result whose hash differs from the manifest stops the comparison with an
error and no verdict. A scenario without a result has no verdict and is listed in the report. The harness writes
every `actual` as a string; it is converted to a number, and a value that is not one is an error. `alerts.tsv`
(default: the manifest directory) has one row per verdict that is neither `ok` nor `measured`; `report.md` counts the
verdicts per status, per spell and, for passive scenarios, per measurement family ("Passives"), and lists the known
modifiers, the probe auras, the scenarios without a result and the runs that did not pass. `verdicts.json` keeps every
verdict with its interval, detail and explanation (schema 1) for `diff`. `questions.md` lists the checks a reviewer must
settle from the reference logs (see [Open conformance checks](#open-conformance-checks)). When the run holds stack
verdicts, `compare` also
writes `levers.md`.

### A full class run

`--stack` selects only the stack, so a class takes two manifests. From this directory, with `W` the worktree:

```sh
python3 -B conformance.py generate --class 19 --out $W/.cache/conformance/templar
python3 -B conformance.py generate --class 19 --stack --out $W/.cache/conformance/templar/stack
python -B $W/tools/verify_all.py --stages gameplay --scenario $W/.cache/conformance/templar/scenarios/*.json
python -B $W/tools/verify_all.py --stages gameplay --scenario $W/.cache/conformance/templar/stack/scenarios/*.json
python3 -B conformance.py compare --manifest $W/.cache/conformance/templar/manifest.json \
  --results $W/.cache/verify-all/STAMP --out OUT
python3 -B conformance.py compare --manifest $W/.cache/conformance/templar/stack/manifest.json \
  --results $W/.cache/verify-all/STACK_STAMP --out OUT/stack
```

Add `build` to `--stages` when the server sources changed since the last build. The runs end `INCOMPLETE`: a
selection of exploratory files leaves the gameplay stage `unavailable` even when every scenario passes; the
gameplay line of the run gives the passed and failed counts. `compare` reads one stamp, so the scenarios of one
manifest go in one call. Keep the outputs outside Git (`.agents/plans/class-conformance/<class>/`).

The Templar pilot of 2026-11-05 (270 spell scenarios and 40 stack passes, simulated clock, 15 lanes) took 93 s for
the spell scenarios in one call and 42 s for the stack; the outputs are `report.md`, `alerts.tsv`, `verdicts.json`
and `levers.md`. To check a run's reproducibility, run the same manifest twice and `diff` the two outputs: a
significant change between two runs of the same build is a defect of the tool.

The phase-2 Templar run of 2026-11-06 (`generate --class 19`: 610 entries, 492 scenarios: 303 value, 66 passive,
83 proc parts, 27 hit parts, 12 trigger parts, melee; 118 entries without a scenario) took 83 s in one call
(stamps 20261106-153135 and 20261106-153725, simulated clock, 15 lanes, 492 passed), then `compare`, `coverage`
against the phase-1 output and `diff` between the two runs. Outputs outside Git in
`.agents/plans/class-conformance-2/templar/`: `report.md`, `alerts.tsv`, `verdicts.json`, `questions.md`,
`coverage.md`, `impact.md`. Results: 1801 verdicts (ok 1261, alert 103, unreadable 72, unmodelled 242,
ambiguous_tooltip 24, unmeasured 9, measured 90); class spells judged 180 of 194 (phase 1: 102 of 172), passives with
a judged behaviour check 79 of 145 (3), actives with a judged hit model 13 of 49 (2). The second run lists 15 changes,
4 of them significant: two hit means that are alerts on both runs (Sacred Swing, Righteous Lunge: their model sigma
does not describe the server's hits) and two `passive_delta` deltas of a rolled `spell_effect_value`, where the before
and after reads are two separate rolls; the other 11 are rolled values and ambiguous proc rates that moved inside
their intervals or had none.

Fix round of the same day (ADR 0017, commit after `7780decbc7`): the 77 alerts of that run that were not server
findings were tool defects and are fixed: modifier targets (ADR 0017), two effects on one metric (judged together),
the melee crit field, which `melee_crit_chance` reads stale (0 before the learn on a reference character whose
field was last computed before its weapon was equipped; passive scenarios now read `melee_crit_chance_refreshed`,
which calls `Player::UpdateCritPercentage` before the read, and `melee_crit_chance` stays the plain read that other
scenarios assert on), `parry_chance` on a character that cannot parry, and the duration clamp of `spell_modifier`. The
regenerated manifest (491 scenarios, stamps 20261106-162551 and 20261106-163218, 82.6 s each) gives 1756 verdicts:
ok 1282, alert 25, unreadable 72, unmodelled 240, ambiguous_tooltip 30, unmeasured 15, measured 92. Two runs differ
on 12 listed verdicts; the significant ones are the Righteous Lunge hit mean (an alert on both runs, its model
sigma does not describe the server's hits) and, before `diff` used the deterministic tolerance for intervals of no
width, the Divine Force hit (400 then 402, `ok` on both, sigma 0). Rolled `effect_value` verdicts were still judged on
one read: those whose server value adds a per-level part the expected value omits switched between `ok` and `alert`
with the roll, so six of them were false `ok` verdicts (ADR 0018 replaces the rule).

Final-review round of the same day (ADR 0018, ADR 0017 D8, `melee_crit_chance_refreshed`): the same 491 scenarios,
now with 2 to 1716 reads per rolled token (stamps 20261106-175907 and 20261106-180224, 85.6 s and 84.4 s, 491
passed), give 1756 verdicts: ok 1268, alert 39, unreadable 72, unmodelled 240, ambiguous_tooltip 30, unmeasured 15,
measured 92. The 14 new alerts are rolled values that one read had passed: 10 server values that add a per-level part
the expected value omits (every Vindication rank, Reckoning 805421, 748505 to 748507 and 572739 to 572741), 4 whose
server value truncates a per-level part the expected value keeps (Chastise 801165, 503136 and 503137, Benediction
803373). Two runs list 6 changes, none significant: the truncation cases Chastise 801165 and Benediction 803374, whose
means sit on the lower bound, the Blade of Faith hit mean at the edge of its interval, and 3 proc rates without one.

### Impact report

```sh
python3 -B conformance.py diff --before OUT_A --after OUT_B [--intended 804929,807268] [--out DIR]
```

`diff` reads the `verdicts.json` of two compare outputs of the same class (an output written before it existed must be
compared again) and writes `impact.md` (default: the `--after` directory). A verdict is identified by its label, check
and scenario; a label on one side only is `added` or `removed`. `--intended` takes spell or rank ids: a change is
`intended` when its spell or rank is in the set, and never for the verdicts without a spell (stack DPS). A change is
**significant** when the two measured values differ by more than the root of the sum of the squares of the half-widths
of their own 99% intervals, taken on the sides that face each other (so a Wilson interval keeps its asymmetry):

| Check | Interval of the measured value |
|---|---|
| `hit_mean`, `melee_mean` | `measured` plus or minus the half-width of the verdict (`Z` x sigma / sqrt(hits)) |
| `proc_rate`, stack DPS and source, talent delta | the `low` and `high` of the verdict |
| every other check | none: significant when the difference exceeds `max(1, 0.5% of expected)`, the tolerance of the comparison (cooldowns: the larger timing window; a `passive_delta` verdict: `delta_margin` of the metric in its `detail['metric']`, so a 0.5-point crit change is significant), plus the larger `roll_spread` of the two sides for a rolled effect |

A side without a measured value is never significant. When the values differ and an interval check (the first two rows)
has no interval on a side, the change is `not judged`: not significant, and listed like a significant one, never as
moved inside the intervals. `impact.md`
lists, with the unintended changes first, the significant and not judged changes, every status change and the added and
removed labels; the moves inside the intervals with an unchanged status come last. Stamp 20261105-191313 compared twice
gives no change; two runs of the 270 Templar scenarios on the same build (stamps 20261105-213612 with 20261105-213753,
and 20261105-214020) give no significant change, while without the roll spread the 26 rolled effect values were listed
as significant; stamps 20261105-203950 (configurations c0 and c1) and 20261105-204050 (all eight) give nine moves inside
the intervals, no significant change and 40 added verdicts (the report then opens with its warning: when more than half
of the verdicts of a side have no counterpart, the keys probably changed or the runs cover other scenarios).

### Coverage comparison

```sh
python3 -B conformance.py coverage --before OUT_A --after OUT_B [--out DIR]
```

`coverage` reads the `verdicts.json` of two compare outputs of the same class (another class is an error, exit 3)
and writes `coverage.md` (default: the `--after` directory): the verdicts per status, and the class spells, passives
and actives judged on each side, with the differences. The phase-1 placeholders, a `hit_mean` label with the rule
`unmodelled: passive spell is never cast`, are left out of every count (design D8: phase 2 gives each passive effect
its own verdict instead). A class spell is a spell id with a verdict in a value, hit or passive scenario
(`conformance-<class>-value-`, `-hit-`, `-passive-`) or with a placeholder; a passive is the spell of a passive
scenario or of a placeholder; an active is any other class spell. A spell is judged when one of its verdicts other
than `known_aura` is `ok` or `alert` (a proc or trigger verdict counts for its aura when that aura is a class spell).
A passive has a behaviour check when one of its `passive_delta`, `proc_rate` or `trigger_count` verdicts is `ok` or
`alert`; an active has a hit model when one of its `hit_mean` verdicts is. `coverage.md` also lists the spells judged
on one side only and the class spells present on one side only.

`coverage.md`'s `## Coverage` table prints the hit-model row twice, over two denominators. "actives with a hit
model" divides by every active (phase 2's original metric, kept for trend continuity with earlier `coverage.md`
files). Many actives are buffs, utility or proc-only spells with no damage or healing effect at all — their
`hit_mean` verdict is `unmodelled` with the exact reason `hits.py`'s `hit_kind` raises when no effect fits a hit
model (`unmodelled: no damage or healing effect among effects [...]`), and they can never clear that row. "actives
with a hit model (of those with an effect)" divides instead by `actives_with_effect`: actives whose `hit_mean`
verdict's explanation does not start with that reason, i.e. actives that structurally could have a hit model. The
numerator is unchanged between the two rows; only the denominator differs.

### Verdicts

| Status | Given to |
|---|---|
| `ok` | a measurement within its rule below |
| `alert` | a measurement outside its rule, a missing measurement, or tokens that changed since generation |
| `unreadable` | an expectation whose rule starts with `unreadable: ` |
| `unmodelled` | an `unmodelled` check, a `unmodelled: ` or `unmeasurable: ` rule, a hit model left unmodelled, a mask spell beside named targets that are all unmodelled |
| `ambiguous_tooltip` | a sign opposite to the measured value, a proc of unstated trigger, disagreeing talent or passive readings, a named spell outside the class mask while a mask spell moves |
| `insufficient_trials` | a hit mean below `minimum_hits`, a proc rate below `trials_needed` (R9), a missing pass |
| `unmeasured` | a check after a failed single cast; a hit mean, proc rate or talent delta without usable hit (R11); a passive whose aura is absent after `learn`; damage against an aura state the scenario does not establish; a passive delta that cannot move (a multiplying relation on a before value of 0, a `stat` change below 1, `parry_chance` on a character that cannot parry) |
| `measured` | a stack DPS or source damage that no tooltip value judges, a passive plan with `judged` false, a mask spell the tooltip does not name, a namesake of a named spell that moves, two effects on one quantity whose relations do not combine, rolled reads fewer than the mean needs; never an alert |

The tooltip of each rank is read again with the `CasterStats` measured by the run's base steps. If its tokens differ
from the tokens read at generation, every token check of the rank is an alert; so is a token whose text differs
from the expectation. A token's value includes its caster stat terms: Argent Blade 807268 measured
`spell_effect_value` 568 where `${$AP*0.4725+$sph*1.35+$m1+0}` reads 568.89 with 313 attack power (stamp
`20261105-191313`); the server can add such terms through `ScriptMgr::ModifySpellEffectBaseValue`, which
`SpellEffectInfo::CalcValue` calls.

- Deterministic values (`effect_value`, `aura_amount`, `power_cost`, `spell_duration`):
  `|measured - expected| <= max(1, 0.5 % of expected)`. A `power_cost` is divided by the display divisor of its
  rule. A `$/N;` token expects N times the value it shows, except a `$/1000;sN sec` token of kind `duration_ms`,
  which the reader already gives in ms. A token of another spell reads its points, sign and rolls from that
  spell's effect (`model`).
- Counts (`max_stacks`): `measured == expected`, no tolerance.
- Sign: the client shows `$sN`, `$mN` and `$MN` (with or without `$/N;` or a spell id) unsigned, while the
  `Spell.dbc` record is signed. The expected value of such a token takes the sign of the points it shows
  (`EffectBasePoints + 1`, or `+ EffectDieSides` for `$MN`) of the named spell, and signed values are compared:
  `-50` measured for `$s1` shown as 50 is `ok` when the record is -51 and an alert when it is 49. Expressions and
  `$<name>` variables keep their sign; a measured value of the opposite sign is `ambiguous_tooltip`.
- Rolled effects (`effect_value`, `aura_amount` of an effect whose `EffectDieSides` is neither 0 nor 1):
  `spell_effect_value` returns `info->Effects[effect].CalcValue(caster)` (`CoAGameplayTest.cpp:4674`), and
  `SpellEffectInfo::CalcValue` (`SpellInfo.cpp:474`) adds one `irand(1, EffectDieSides)` roll (or
  `irand(EffectDieSides, 1)`) to `EffectBasePoints` before the caster stat terms of
  `ScriptMgr::ModifySpellEffectBaseValue`; 0 adds nothing and 1 adds 1. The token is read again with each roll
  `EffectBasePoints + 1` .. `EffectBasePoints + EffectDieSides` in place of the effect's points (`ForcedPoints`);
  values that are not monotone in the roll give `unmodelled`. Otherwise the reads are judged by the hit-mean rule:
  the rolls are equally likely, so the expected mean and sigma are the mean and population sigma of the per-roll
  values, re-read with the measured stats; with n reads (`detail['reads']`) the mean of the reads must lie in
  expected mean ± 2.576 x sigma / sqrt(n), widened by 1 toward zero because `CalcValue` returns `int32(value)`
  (`SpellInfo.cpp:587`, a truncation). Fewer reads than the count the mean needs at the measured stats
  (`detail['reads_needed']`), or a mean of 0, give `measured`. A single read inside the roll range proves nothing
  about a constant offset smaller than the range: the fix round of the phase-2 Templar run found six such `ok`
  verdicts (Reckoning 572741, 748507, 805421; Vindication 501589, 501590, 501592), whose server value adds a
  per-level part the expected value omits. An `aura_amount` of a rolled effect has one read (one cast) and is
  therefore `measured` unless one read is enough. The Templar has rolled tokens on Righteous Upheaval, Vindication,
  Reckoning, Chastise, Benediction, Titanstrike and others (`EffectDieSides` 3 to 224).
  Every `effect_value` and `aura_amount` verdict whose measured effect rolls (the token's effect, or the first
  active effect for an unreadable value) keeps `roll_spread`, `abs(EffectDieSides) - 1`, in its `detail`: two
  `CalcValue` draws of that effect at the same stats differ by at most that much.
- Time (`cooldown_ms`, `aura_duration_ms`, ruling R8): `expected - W <= measured <= expected`. W bounds the game
  time elapsed between the cast step and the measuring step: for every step after the cast up to the measurement,
  its `elapsed_ms` plus the run's `max_step_ms`; the `cast time` wait of a cast-time spell counts only its 500 ms
  margin plus `max_step_ms`, because the cooldown or aura starts when the cast completes. `CoAGameplayTest::Tick`
  runs one step per world update (`Progress` calls `RunStep` once), a step's `elapsed_ms` is the game time from its
  start to its completion, and `max_step_ms` is the largest update diff of the run (`docs/coa/verification.md`, fidelity
  limits: at most 25 ms in a wait, 10 ms while polling). Measured on 2026-11-05 (stamp `20261105-181206`): cooldowns 6,
  12 and 18 ms below the record two, four and six steps after the cast, durations 12 and 15 ms below; W was 50 to 150
  ms.
- Hit means (`hit_mean`, `melee_mean`): `measured_hit_model` recomputes the model from the run's stats, known auras
  and target; the measured mean of the non-critical, non-blocked hits must lie in `mean ± 2.576 x sigma / sqrt(n)`,
  n the usable hits. `tooltip_mean` is shown in the explanation only. The parts of a hit (same label) give one
  verdict, on the first part's key: totals and counts are summed over the parts with a result, the model is recomputed
  per part (the dummy's armor can differ) and pooled, `mean = sum(n_i x mean_i) / n` and half-width
  `2.576 x sqrt(sum(n_i x sigma_i^2)) / n`, and the explanation says how many parts counted (`1 of 2 parts`); a
  missing part leaves its hits out, so the sum can fall below `minimum_hits`.
- `known_aura`: the aura must be measured on the character.
- Failed casts (ruling R11): the harness records each `SMSG_CAST_FAILED` or `SMSG_PET_CAST_FAILED` an actor
  receives as `{spell, reason}` in the result's `cast_failures` list and keeps the last reason per spell for the
  `cast_failure` metric (`CoAGameplayTest.cpp:1288-1299`, `:2010-2019`, `:5016-5020`; a new cast clears it, `:7176`).
  A reason of 0 is ignored: it is `SPELL_FAILED_SUCCESS` (`src/server/shared/SharedDefines.h:1048`). When either
  names the measured rank of a no-combat scenario, which casts it once, its `cooldown_ms`, `aura_amount` and
  `aura_duration_ms` checks are `unmeasured`, with `cast failed: <name> (<code>)`, the name read from
  `enum SpellCastResult` in `SharedDefines.h` (22 is `SPELL_FAILED_CASTER_AURASTATE`, line 1070). Effect values and
  the power cost, measured before the cast, stay judged, and a token drift of the rank stays an alert. A hit
  scenario casts its rank many times: a failed cast only produces no hit, so the mean is judged on the usable hits
  as above, and the explanation lists the failed casts per reason (`failed casts: 2 x <name> (<code>)`); fewer
  usable hits than `minimum_hits` is `insufficient_trials`, and no usable hit after failed casts is `unmeasured`.
- Passive deltas (`passive_delta`, `judge_passive`): the judged quantity is `delta = after - before`. In order:
  `<passive> aura_present` 0 makes every check of the passive `unmeasured: passive aura <id> absent after learn`
  with its `EquippedItemClass`, `Stances` and `CasterAuraSpell`; a missing before or after value is an alert (a
  plan with `judged` false: `unmeasured`); a plan with `judged` false is `measured`, never `ok` or alert; an
  effect of aura 303 (damage against a target in aura state `EffectMiscValue`, Pious Sweep 520034 effect 0, state
  23) is `unmeasured`, since the scenario neither establishes nor measures that state on the dummy. The tooltip is
  then read again with the measured base stats; a token text absent from that reading is an alert. The token value
  (times N for `$/N;`, except a `$/1000;sN sec` token of kind `duration_ms`, which the reader gives in ms) takes the
  sign of the effect's own points (`copysign`, own or shared token); for points that scale with level, the sign rule of
  the token checks above. With v that signed value, the expected delta per relation (readings, as R12/R14: agreeing
  readings give their status, disagreeing ones `ambiguous_tooltip`):

  | Relation | Expected delta |
  |---|---|
  | `spell_mod_flat`, `add` | v |
  | `spell_mod_pct`, `scale`, `ratio` | before x v / 100 |
  | `share` | source x v / 100, source the base-step value of `source_label`, measured before the learn |
  | `haste` | `divides`: before / (1 + v / 100) - before (one reading, owner answer Q5) |
  | `crit_damage` | `whole`: before x v / 100; `bonus`: (before - 1000) x v / 100, 1000 the metric's fixed base |
  | `composition` | `multiplies`: before x v / 100; `adds`, when a known modifier of the metric's kind (`damage`, `heal`) and school is measured on the character: before x v / (100 + the sum of their percents) |

  Tolerance on the delta (D3): `delta_margin(metric, expected)` is `max(0.01, 0.5% of |expected|)` for the
  percentage-point metrics `PERCENT_POINT_METRICS` (`melee_crit_chance`, `melee_crit_chance_refreshed`,
  `spell_crit_chance`, `melee_hit_chance`, `spell_hit_chance`, `parry_chance`, `dodge_chance`, and
  `spell_done_crit_chance`, the crit chance a spell modifier of op 7 changes) and for `weapon_damage_min`, a float
  field whose 3% delta is
  about 1.9 (a 1-point floor would accept 1.4% to 4.6%), else `max(1, 0.5% of |expected|)`. Liberty 705266 on Libram
  of Tenacity 801461: `$/1000;s1` reads 30000 ms, points −30000, expected −30000 ± 150; 1000 → −29000 is `ok`, 1000 →
  −28800 an alert. Solemn Soldier 572555: 2500 → 2272.73 ms is `ok`, 2500 → 2250 an alert.
  Spell modifier targets (D5, ADR 0017): a mask spell the tooltip does not name, beside named targets of the same
  effect and metric, is `measured`; beside named targets that are all `unmodelled` for that effect and metric (a
  named spell without the consumer's effect: `target <id> has no effect <n>`) it is `unmodelled`, the reason naming
  them; with no named target at all (category targets) the mask spells are judged. A named spell
  outside the mask is `ok` when its own delta is the expected one; otherwise `measured` when a named spell of the
  same name shows the expected non-zero delta (a namesake the modifier does not reach: Legacy of the Silver Hand on
  Scourgebane 92111 beside 801832), `ambiguous_tooltip` when another mask spell of the same effect and metric, named
  or not, shows it ("the tooltip names X, the modifier applies to Y": Templar's Might names the spells its Condemn
  debuff boosts), else an alert (Patience 712678 names Interdict 560116, its mask matches Sacred Restraint 102208).
  A measured delta of 0 against a non-zero expected delta is never `ok` (the 1-point floor does not apply to it).
  Not judged, `unmeasured` with the reason: a relation that multiplies a before value of 0 (`spell_mod_pct`,
  `scale`, `ratio`, `composition`, `crit_damage`); `parry_chance` 0 before the learn (the reference character cannot
  parry, and a parry aura enables parry when applied, `AuraEffect::HandleAuraModParryPercent`); a `stat` delta below
  1 (the server truncates stats to integers, `Unit::UpdateStats` `SetStat(stat, int32(value))`). Two judged effects
  of one passive on the same metric and fields (no target) are judged together: the product of their factors when
  both scale (Call of the Monastery: 313 x 1.05 x 1.05), the sum of their deltas when they add or share (Paragon:
  10 + 10% of 132 Agility), else `measured`. A `spell_modifier` of a flat duration or cast-time reduction starts
  from 1000 plus the reduction, since the server clamps those at 0 (`Player::ApplySpellMod`).
  An `ambiguous_tooltip` passive verdict keeps `detail['question']` = `question_detail(kind, question, readings,
  measured)`: `kind` `readings` (disagreeing readings) or `text` (named spell outside the mask), the question in
  observable terms ("With Chivalric learned, does a critical hit of Reckoning change by +15% or by +5%?"), per
  reading its `name`, `expected` (the after value), `delta`, `status` and `measured` (the after value of that
  reading's spell), and `measured`, the after value of the verdict's own measurement. The verdict's `measured`,
  `expected`, `low` and `high` are deltas, and every passive verdict keeps its metric in `detail['metric']`.

The report lists each known aura's modifier effects with `EffectBasePoints`, `EffectRealPointsPerLevel`, the
value at the class level and the runs that measured the aura; a hit model applies a modifier only in a run that
measured its aura.

### Open conformance checks

`questions.md` is what a reviewer settles from the reference Ascension combat logs (`~/Projects/coa-log-history`);
each entry names the log evidence that decides it, so it is English and self-contained. A verdict asks a question
when its `detail['question']` is `question_detail(kind, question, readings, measured)`; an `ambiguous_tooltip`
verdict without one asks its explanation (kind `text`). An `ok` verdict never asks one, whatever its detail.

Kinds, what gives them and what they ask:

- `readings`: disagreeing readings of a passive delta, of a proc rate (`judge_proc`) or of a talent delta
  (`judge_talent_delta`), and a token value whose measured sign is the opposite of the tooltip's (`judge_token`); the
  change or rate each reading expects, from the tooltip numbers.
- `text`: a named spell outside the class mask (passives), a class-file entry whose `status` is `ambiguous_tooltip`
  (`procs`, `talent_modifiers`) or a generated `ambiguous_tooltip` rule; the entry's `question`, else the rule's
  reason.
- `tooltip_value`: an `unreadable` value or hit whose entry holds a `$<id>pplN` token, a per-level value without client
  evidence; the number the tooltip shows at that level, with the attack power and spell power a log line would carry.
- `data_issue`: an `unreadable` value or hit whose entry holds a `$<name>` variable while the spell's
  `SpellDescriptionVariableID` is 0; what the tooltip shows in its place.
- `server_behaviour`: an `alert` of a proc or trigger entry that has a class-file `question`; the finding that
  explains the tooltip and the test server disagreeing, and the log evidence (if any) that would confirm or rule out
  a defect.

Every readings question also carries `conditions`, what our test did: the level, what was learned, what was cast or
attacked and how, the counts, and the other percent modifiers measured on the character (known auras such as 887007
by name and percent, earlier talents of the stack) when the expected number depends on them. Readings carry `name`,
`meaning` (one plain sentence: `multiplies` multiplies the whole value after every other modifier, `adds` is added to
the named other percent modifiers, `whole` applies to the whole critical hit, `bonus` only to the extra damage of a
critical strike; proc readings take the class file's `meaning`), `expects` and `measured_text` (the percent change of
a hit, a critical hit as a percent of a normal hit, the share of triggers that proc), `expected`, `status` and, as
they apply, `delta`, `measured`, `predicted`, `procs`, `trials`,
`rate`, `low` and `high` (the 99% Wilson interval), `unit`. A proc reading predicts procs per trigger of the first
reading (the trigger the player performs): with `d` the extra trials per proc that the reading counts, measured as
(its trials - the first reading's trials) / procs, a chance `p` gives `p / (1 - d p)` (Scourgebane: 20% and 25% of auto
attacks; Light's Echo 520017: 10% and 11.1% of casts). `observations` is the count at which the 99% ranges of the
readings no longer overlap, the largest over each pair. For proc rates, in the player's triggers:
`n = ceil((2.576 (s1 + s2) / (q2 - q1))^2)` with `s = sqrt(q (1 - q))` (1842 auto attacks for 20% against 25%, 20282
casts for 10% against 11.1%). For hits, the readings are ratios `r` of two averages of `n` hits each (with and
without the bonus, or critical against normal), whose relative spread is `c sqrt(2 / n)`, `c` the hit's standard
deviation over its mean: `n = ceil(2 (2.576 c (r1 + r2) / (r2 - r1))^2)` hits each way, at least 1. `hit_spread`
gives `c` from the client data of the measured spell: each school damage or heal effect rolls `EffectBasePoints` + 1
to `EffectBasePoints` + `EffectDieSides` (variance `(EffectDieSides^2 - 1) / 12`), and weapon effects roll the class
file weapon from `min_damage` to `max_damage` times their percent (variance `(percent (max - min))^2 / 12`), plus
their flat points. The mean leaves out the attack power, spell power and per-level parts of the hit, so `c` and the
count are upper bounds (Serendipity on Reckoning, 49 roll values on a mean of at least 190: at most about 5588 hits
each way); a weapon count holds for the test weapon only, and a fixed amount needs about 1 hit. The `adds` meaning
says whether the bonus then counts for more or less than `multiplies`, from the two numbers (more for Serendipity and
Paladin Training, whose other modifier 887007 is -20%). In `compare.py`,
`tooltip_value_question(spell_name, level, entry, description)` builds the `tooltip_value` detail of an entry with a
`$<id>pplN` token, for any judge that reports one, and `data_issue_question(spell_name, entry, description)` the
`data_issue` detail; `unreadable_question` chooses between them for the `unreadable: ` rules of value and hit
scenarios. The sentence of the tooltip that holds the entry is quoted with `___` in its place. A `$<name>` of a spell
whose `SpellDescriptionVariableID` is not 0 but does not define the name stays `unreadable` without a question: the
tooltip source gives no access to the definitions.

Verdicts with the same cleaned tooltip and kind make one `Question`, which lists every spell id and check label, its
distinct questions, and each reading, condition and observation tagged with its spell (Blade Sermon 572548 and 572554;
Light's Echo 520017 and 520883, one entry with the readings of each rank; the seven Argent Blade ranks 804929 to
807268, whose `$<scalingbp>` has no definition). `measured` is kept only when all the entry's verdicts agree.
`questions.md` has a `# Tooltips` section (kinds `readings`, `text`, `tooltip_value`, `data_issue`, then any other
kind) and a `# Findings` section. Each entry is
`## <name> (<ids>)`, the tooltip in a quote block (color codes removed, `$` tokens kept, `@s:<id>:<flags>@` shown as
"followed by the tooltip of spell <id>"), the token values that are the same at any level and stats (read with two
opposite `CasterStats`), "How we tested", one line per reading (prefixed by its spell id when the entry has several
spells), "Observations needed", one line starting `To settle:` (`Finding:` in the `# Findings` section) per distinct
question and the check labels.

Produced on 2026-11-06 from the existing probe stamps (manifests generated again with the class file of this change,
same scenario hashes): triggers `20261106-093404` give the two findings (Fervent Castigation 707606, expected
273 against 0; Heaven's Finest 806516, 273 against 150), passives `20261106-085206` the Serendipity and Chivalric
readings, procs `20261105-201416` the Scourgebane readings, one Light's Echo entry with both ranks' readings and the
Paladin Training and Blade Sermon text questions, the stack `20261105-204050` Paladin Training (20% against 25%,
measured 20.27%) and Legacy of the Silver Hand, and the value and hit scenarios of `20261105-214020` the six `ppl`
questions and the Argent Blade data issue.

## Run

Tests run through `verify_all` only; the `conformance` suite of `tools/check_source.py` lists them.

```sh
python -B tools/verify_all.py --stages source --base origin/main
```

The tests that read the client DBC set are skipped when `/srv/coa/server-data/dbc` does not exist; the fixture tests
always run.
