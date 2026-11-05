# CoA class tooltip conformance

Python 3.11+ standard library only. Tools that check, per class, that spells behave as their client tooltip says.
Expected values come from the effective client DBC set (`/srv/coa/server-data/dbc`), never from server code.

## Modules

- `mitigation.py`: expected armor and partial-resist mitigation of a target.
- `classes.py`: `class_spells(dbc_dir, class_id, progression_header, level=60)` lists a CoA class's spells as
  `ClassSpell(spell_id, name, ranks, max_rank, required_level, passive)`.
- `tooltip.py`: `read_tooltip(dbc, spell_id, caster)` evaluates a spell's `Description[enUS]` with the caster's
  measured `CasterStats` and returns `Readout(values, unreadable)`.
- `profile.py`: the reference character of a class file and `base_steps(class_file)`, the steps every scenario starts
  with. Its name shadows the standard library `profile`: run the package from its own directory.
- `values.py`: `value_scenario(class_file, spell, rank_id)` returns the no-combat scenario of one rank and its
  `Expectation` list.
- `hits.py`: `hit_scenario(class_file, spell, casts)` and `melee_scenario(class_file, swings)` return the hit scenario
  of a spell's highest rank and the auto-attack scenario, with their `Expectation` lists; `expected_hit` and
  `casts_needed` give the expected mean, its sigma and the number of casts.
- `procs.py`: `proc_scenario(class_file, entry, part)` returns one part of the proc-rate scenario of a `procs` entry
  and its `Expectation`; `proc_plan` sizes the parts, `trials_needed(p)` gives the trials a chance `p` needs and
  `wilson_interval(procs, trials)` the 99% Wilson interval of a rate.
- `compare.py`: `compare(manifest, results_dir)` judges a run against the manifest and returns `Verdict(label, status,
  measured, expected, low, high, explanation)`; `write_outputs` writes `alerts.tsv` and `report.md`.
- `conformance.py`: the command line, `generate` and `compare`.
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

## Tooltip reading

The rules follow the stock 3.3.5a client parser (wowdecomp `WoW/Source/Ui/QuestTextParser.cpp` and `MathState.cpp`,
evidence rather than authority). Each value is `Displayed(text, value, effect_index, kind)`: `text` is the token as
written in the DBC, `value` the number before any player modifier.

| Token | Value | Kind |
|---|---|---|
| `$sN`, `$<id>sN` | `EffectBasePoints + 1`, unsigned, only if `EffectDieSides` is 1 | `percent` before `%`, or `flat` |
| `$mN`, `$MN` (with `<id>`) | `EffectBasePoints + 1`, `EffectBasePoints + EffectDieSides`, unsigned | as `$sN` |
| `$/N;` then `$sN`/`$mN`/`$MN` | divided by N; `$/1000;` followed by `sec` stays in ms | `duration_ms` or as `$sN` |
| `$d`, `$<id>d` | `SpellDuration` `Duration`, capped by `MaxDuration` | `duration_ms` |
| `$h`, `$<id>h` | `ProcChance` | `chance_pct` |
| `$u`, `$i` (with `<id>`) | `StackAmount`, `MaxAffectedTargets` | `count` |
| `$aN` (with `<id>`) | `SpellRadius` radius of effect N | `flat` |
| `${...}` | `+ - * /`, parentheses and the variables below | as `$sN` |
| `$<name>` | a `SpellDescriptionVariables` formula of the described spell | as `$sN` |

Inside `${...}`: `$mN`/`$MN` (signed), `$h $u $i`, `$d` in seconds, `$aN`, each with an optional spell id; `$AP`,
`$RAP`, `$PL`; `$SP` is the lowest spell power of schools 1 to 6, `$sph $spfi $spn $spfr $sps $spa` one school each;
`$STR $AGI $STA $INT $SPI` the effective stats 0 to 4; `$<name>` a variable defined earlier.
`effect_index` is the effect of the first `$sN`/`$mN`/`$MN` of the spell itself in the token (for `$<name>`, in its
formula), otherwise `None`. The client reads `$D $H $U $I $AN` as their lowercase forms, and so does the reader.
Color codes `|c........` and `|r` are removed, in either case.

Everything else goes to `unreadable` verbatim and is never guessed: `$?` conditionals, `@...@` markup, other `|`
escapes, other tokens (`$t`, `$o`, `$x`, `$S`, `$l`, `$g`...), expression functions and variables such as `$BH`,
`$ppl1` or lowercase `$ap`, points that scale with level (`EffectRealPointsPerLevel` or `DurationPerLevel` not
zero), spread values (`EffectDieSides` not 1 for `$sN`), missing records, non-positive durations, a `$<name>` that
the described spell's `SpellDescriptionVariableID` does not define, and a stat or school missing from `CasterStats`.

A level-scaled entry names its field, for example `${$m1+0} [EffectRealPointsPerLevel[0] of spell 706323]`. The
client does not scale by the character level: `Spell_C_GetSpellLevel` divides by 5 the rank that
`CGPlayer_C::GetSpellRank` returns. That rank is the player's skill value in the spell's `SkillLineAbility` skill
line (or weapon skill), capped at 5 × `MaxLevel`, and 0 when the spell has no ability row. `CasterStats` holds no
skill values, so these values stay unreadable.

## Reference character

`classes/<name>.json` holds `class_id`, `name`, `race`, `level`, `weapon` (`item`, equipment `slot`, 15 is the main
hand), `ratings` (fixture hit and expertise ratings, so that an aura or hit is never lost to a miss; they do not change
a tooltip value), `reference_stats`, `known_auras`, `probe_auras`, `procs` (see [Proc rates](#proc-rates)) and the
sections `talent_modifiers`, `rotation`, `stack` that later tasks fill. The Templar reference is a human with the
Walking Stick (item 2495).

`weapon` also freezes the `item_template` row of the weapon: `min_damage` (`dmg_min1`), `max_damage` (`dmg_max1`),
`speed_ms` (`delay`), `inventory_type` and `normalized_speed`, the speed `Unit::GetAPMultiplier` uses for normalized
weapon damage (3.3 for a two-handed weapon, inventory type 17). Walking Stick, read on 2026-11-05 from `acore_world`
in the in-RAM test database with `SELECT dmg_min1, dmg_max1, delay, InventoryType FROM item_template WHERE entry =
2495`: 6.5625, 10.9375, 2500, 17. With 313 attack power, 6.5625 + 313 / 14 x 2.5 = 62.455 is the measured
`weapon_damage_min`. `reference_stats` holds the `base_steps` values measured on the naked reference character (Templar:
2026-11-05, `.cache/verify-all/20261105-181206`); they size the scenarios, and the comparison uses the values measured
in the run.

`base_steps` waits 5 s, adds and equips the weapon, then measures with the extreme bounds of an exploratory
measurement (the judgement is made by the comparison, never by the scenario): `attack_power`,
`ranged_attack_power`, `spell_power 1`..`6`, `stat 0`..`4`, `weapon_damage_min`, and one `aura` per entry of
`known_auras` (label `known_aura <id>`) and of `probe_auras` (label `probe_aura <id>`). `caster_stats_from(measured,
level)` rebuilds the `CasterStats` that `read_tooltip` needs from those labelled values.

A naked level-60 Templar knows no class spell and carries one class aura: measured on 2026-11-05 on the worldserver of
the worktree, `knows_spell` is 0 for all 221 spell ids of the class and `aura` is 1 only for the class tuning aura
887007 (887043/887044/887045, the spec auras, and the passive Scourgebane 92111 read 0). `known_auras` therefore lists 887007
only; Scourgebane is in `probe_auras`, which is measured and reported but never explains a deviation.

## No-combat scenario of a rank

`value_scenario` returns a schema 1 scenario of one rank and its `Expectation(label, check, spell_id, rank_id,
effect_index, displayed, rule)` list. `label` is also the label of the measurement step, and is unique in the scenario.
`displayed` is the token as written in the DBC: the comparison reads the tooltip again with the measured caster
stats, since the value depends on them. The scenario learns the rank, then measures (assertions with extreme bounds):

| `check` | Measurement | Expected from |
|---|---|---|
| `effect_value` | `spell_effect_value` of the token's effect | the tooltip token (`rule` `read <kind>`) |
| `power_cost` | `spell_power_cost` before any cast | `ManaCost` divided by the client display divisor of the power type (1, 10 rage and runic power, 1000 happiness) |
| `cooldown_ms` | `cooldown_ms` right after the cast | `max(RecoveryTime, CategoryRecoveryTime)`, as the client tooltip |
| `aura_amount` | `aura_amount` of the effect after the cast | the same tooltip token as `effect_value`, for an effect that applies an aura |
| `aura_duration_ms` | `aura_duration_ms` after the cast | the `$d` token of the rank, for an instant spell that applies an aura |
| `known_aura` | `aura` before any learn | the class file; the aura's own tooltip gives its modifier |

The cast, when a cooldown or an aura is measured, targets the fixture creature `dummy` (entry 36) when an active
effect has an enemy target (implicit targets 2, 6, 15, 16, 24) and the caster otherwise; an aura whose target is the
caster is read on the caster. A cost in a power other than mana is set to its cost before the cast. Two diagnostic
measurements ride along without an `Expectation`: `<rank> cast_failure` and `<rank> aura_present`.
The remaining aura duration is read in the cast step's own tick: measured 12 to 15 ms below the record on instants.
`cooldown_ms` is the remaining cooldown, measured 6 ms below the record right after the cast.

A value that cannot be compared is never dropped; its `rule` starts with a stable prefix:
`unreadable: <entry>` for a part the reader could not evaluate (the scenario measures the spell's first active effect
beside it, which is not the token's own effect), `unreadable: tooltip without value` for an empty readout,
`unreadable: ManaCostPercentage ...` or `unreadable: ManaCostPerlevel ...` for a cost the DBC alone does not give, and
`unmeasurable: <reason>` for a readable token with no no-combat metric (other spell's effect, radius, stack or chance
token, an aura of a passive or cast-time spell). Only `unmeasurable` expectations may lack a measurement step.

## Max-rank hit scenarios

`hit_scenario(class_file, spell, casts)` models the spell's highest rank from its effects, its tooltip read with the
reference stats, the known auras and the reference target. `casts` is the number of casts the mean needs; the scenario
performs `scheduled_casts(casts)`, `ceil(casts x 1.5)`, so that the hits excluded from the mean (critical, blocked)
rarely leave fewer usable hits (ruling R9). It learns the rank, measures the target, then repeats: `set_power` to the
cost (when the cost is a plain `ManaCost`), `reset_cooldown`, `cast`, and a wait of
`max(StartRecoveryTime, cast time, duration of a periodic aura) + 500 ms`; a 3 s drain precedes the measurements.

| `kind` | Effects | Hit before modifiers |
|---|---|---|
| `weapon` | 31 percent, 17/58/121 flat | roll times the percent, truncated, plus the floored flats (ADR 0010) |
| `school` | 2 | the floored tooltip value of each effect, or each integer from `$mN` to `$MN` |
| `heal` | 10 | as `school`, on the caster, without mitigation |
| `periodic_damage`, `periodic_heal` | 6, aura 3 or 8 | one tick; `hits_per_cast` is `Duration / EffectAmplitude` |

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
| `trigger` | `{"action": "attack", "spell": 0}` for auto attacks, `{"action": "cast", "spell": <rank>}` for a cast |
| `trigger_text` | the words of the tooltip that name the trigger |
| `proc_spell`, `proc_spell_source` | the spell each proc casts, and where that id comes from |
| `event_metric` | `spell_cast_count` or `spell_damage_count`, the metric of `proc_spell` |
| `events_per_proc` | the events of that metric in one proc |
| `dbc` | `ProcChance`, `ProcFlags`, `ProcCharges` of the aura and of the spell of the chance token |
| `spell_proc` | the `spell_proc` row of each spell, `{}` without one |
| `internal_cooldown_ms` | the `spell_proc` `Cooldown`, the internal cooldown between procs |
| `status`, `reason` | `ambiguous_tooltip` or `unmodelled` for an entry without a scenario, and why |

The trigger comes from the tooltip text only. When the text does not say what triggers the proc, the entry is
`ambiguous_tooltip` and never gets a chosen trigger. An entry whose observable the harness cannot separate is
`unmodelled` with its reason. Both have no scenario and are never `ok`.

`trials_needed(p)` is `ceil(2.576^2 x p (1 - p) / 0.025^2)`, the trials that put the half width of the 99% interval
of the rate at 2.5 points: 1699 for 20%, 956 for 10%. The scenario performs `ceil(1.5 x trials_needed)` attempts
(ruling R9), refuses fewer attempts than `trials_needed`, and splits them over parts whose wait fits the 600 s
scenario limit with the 60 s margin of the hit scenarios. Each part learns the aura, then:

- for `attack`: attacks `dummy` for its attempts times the weapon speed; a trial is a main-hand melee hit that deals
  damage (`melee_damage_count` with `hand` 0, `melee_attack_count` beside it). A miss, dodge or parry deals none and
  is not a trial. An internal cooldown makes the entry `unmodelled`: auto attacks cannot be spaced beyond it.
- for `cast`: learns the trigger rank and casts it at `dummy` as the hit scenarios do, one cast every
  `max(StartRecoveryTime, cast time, internal_cooldown_ms) + 500 ms`; a trial is a damage event of the trigger rank
  on `dummy` (`spell_damage_count`, `spell_cast_count` beside it), so a failed cast is no trial (ruling R11).

Each part then measures `event_metric` of `proc_spell` and the aura on the character. The `proc_rate` expectation of
every part has the same label, `<aura> proc_rate`; the comparison sums the trials and the events of the parts whose
run measured the aura, and divides the events by `events_per_proc`. The chance is the tooltip token read again with the
measured stats. Fewer trials than `trials_needed` are `insufficient_trials`, even at the exact rate; no usable trial
(failed casts, aura absent) is `unmeasured`; otherwise the verdict is `ok` when the chance lies in the Wilson
interval (z = 2.576) of procs over trials, and `alert` outside it or with more procs than trials.

The Templar entries cite the client DBC and the `spell_proc` and `spell_script_names` rows of `acore_world` in the
in-RAM test database, read on 2026-11-05 (`SELECT * FROM spell_proc WHERE SpellId IN (...)`):

| Aura | Chance | Trigger | Proc spell | Entry |
|---|---|---|---|---|
| Scourgebane 92111 | `$520007h` 20% | attack ("Direct damage dealt") | 801832, tooltip `$801832s2` | scenario |
| Warrior of Dawn 560648 | `$h` 10% | attack ("Melee damage dealt") | 561156, tooltip `$561156s1` | scenario |
| Retribution 707391 | `$h` 20% | attack ("Melee damage dealt") | 525028 (2 per proc), `EffectTriggerSpell` | scenario |
| Light's Echo 520017, 520883 | `$h` 10%, 20% | Argent Blade | no spell names the extra strike | `unmodelled` |
| Paladin Training 504808 | `$h` 8% | "Triggering Zealotry" | | `ambiguous_tooltip` |
| Blade Sermon 572548, 572554 | `$h` 5%, 10% | Zealotry | | `ambiguous_tooltip` |
| Transcendent Guardian 804571 | `$h` 40% | a charge to an ally | | `unmodelled` |

`spell_proc` has rows for 92111 (Chance 100), 520007, 560648 and 707391 (Chance 0, so the DBC `ProcChance`), all
with `ProcFlags` 1048575 and `Cooldown` 0, and none for the other auras; the four are scripted by
`aura_ascension_templar_event`, whose checks for them (`AscensionTemplarEvents.cpp:58-73`) keep no cooldown of
their own, so no entry with a scenario has an internal cooldown. The Light's Echo, Paladin Training, Blade Sermon
and Transcendent Guardian auras have neither a `spell_proc` nor a `spell_script_names` row.

Scourgebane, measured on 2026-11-05 (stamp `20261105-195549`, simulated clock): 13 parts of 197 swings, each
500.7 s of game time in 3.6 s of real time, the gameplay stage 30.9 s. 484 procs in 2561 trials, rate 0.189,
Wilson interval 0.170 to 0.210 around the tooltip 20%: `ok`.

## Generate and compare

```sh
cd apps/coa-gameplay-test/conformance
python3 -B conformance.py generate --class 19 --out DIR [--spell ID ...] [--proc AURA ...]
coa-verify --ram --stages gameplay --scenario DIR/scenarios/*.json
python3 -B conformance.py compare --manifest DIR/manifest.json --results .cache/verify-all/STAMP [--out OUT]
```

`generate` writes one no-combat scenario per rank, the hit scenario of each spell's highest rank, the parts of each
proc entry and, without `--spell` or `--proc`, the melee scenario, into `DIR/scenarios/`, and `DIR/manifest.json`.
`--spell` takes a class spell id or a rank id, `--proc` the aura of a proc entry; either one selects only what it
names. A proc part is named `conformance-<class>-proc-<aura>-part-<n>`. A hit expectation that is entirely
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
(default: the manifest directory) has one row per verdict that is not `ok`; `report.md` counts the verdicts per
status and per spell, and lists the known modifiers, the probe auras, the scenarios without a result and the runs
that did not pass.

### Verdicts

| Status | Given to |
|---|---|
| `ok` | a measurement within its rule below |
| `alert` | a measurement outside its rule, a missing measurement, or tokens that changed since generation |
| `unreadable` | an expectation whose rule starts with `unreadable: ` |
| `unmodelled` | an `unmodelled` check, a `unmodelled: ` or `unmeasurable: ` rule, a hit model left unmodelled |
| `ambiguous_tooltip` | a signed value whose sign differs from the measured value, a proc of unstated trigger |
| `insufficient_trials` | a hit mean below its `minimum_hits`, a proc rate below `trials_needed` trials (R9) |
| `unmeasured` | a check after a failed single cast, a hit mean or proc rate with no usable hit or trial (R11) |

The tooltip of each rank is read again with the `CasterStats` measured by the run's base steps. If its tokens differ
from the tokens read at generation, every token check of the rank is an alert; so is a token whose text differs
from the expectation. A token's value includes its caster stat terms: Argent Blade 807268 measured
`spell_effect_value` 568 where `${$AP*0.4725+$sph*1.35+$m1+0}` reads 568.89 with 313 attack power (stamp
`20261105-191313`); the server can add such terms through `ScriptMgr::ModifySpellEffectBaseValue`, which
`SpellEffectInfo::CalcValue` calls.

- Deterministic values (`effect_value`, `aura_amount`, `power_cost`): `|measured - expected| <= max(1, 0.5 % of
  expected)`. A `power_cost` is divided by the display divisor of its rule. A `$/N;` token expects N times the value
  it shows.
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
  if the values are monotone in the roll, the measured value must lie between the lowest and the highest, each bound
  widened by the deterministic tolerance; otherwise the verdict is `unmodelled`. The Templar has seven such tokens,
  `${$m1+0+$AP*0.45+$SP*0.45}` of ranks 501562 to 501566, 572021 and 572027 (`EffectDieSides` 32 to 224).
- Time (`cooldown_ms`, `aura_duration_ms`, ruling R8): `expected - W <= measured <= expected`. W bounds the game
  time elapsed between the cast step and the measuring step: for every step after the cast up to the measurement,
  its `elapsed_ms` plus the run's `max_step_ms`. `CoAGameplayTest::Tick` runs one step per world update
  (`Progress` calls `RunStep` once), a step's `elapsed_ms` is the game time from its start to its completion, and
  `max_step_ms` is the largest update diff of the run (`docs/coa/verification.md`, fidelity limits: at most 25 ms
  in a wait, 10 ms while polling). Measured on 2026-11-05 (stamp `20261105-181206`): cooldowns 6, 12 and 18 ms
  below the record two, four and six steps after the cast, durations 12 and 15 ms below; W was 50 to 150 ms.
- Hit means (`hit_mean`, `melee_mean`): `measured_hit_model` recomputes the model from the run's stats, known auras
  and target; the measured mean of the non-critical, non-blocked hits must lie in `mean ± 2.576 x sigma / sqrt(n)`,
  n the usable hits. `tooltip_mean` is shown in the explanation only.
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

The report lists each known aura's modifier effects with `EffectBasePoints`, `EffectRealPointsPerLevel`, the
value at the class level and the runs that measured the aura; a hit model applies a modifier only in a run that
measured its aura.

## Run

Tests run through `verify_all` only; the `conformance` suite of `tools/check_source.py` lists them.

```sh
coa-verify --ram --stages source --base origin/main
```

The tests that read the client DBC set are skipped when `/srv/coa/server-data/dbc` does not exist; the fixture tests
always run.
