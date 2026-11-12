# Proc rates

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
| `event_metric` | `spell_cast_count` or `spell_damage_count`, the metric of `proc_spell`; `melee_attack_count` (a `cast` |
| | trigger only) for the main-hand auto attacks of an extra-attack proc (Paladin Training 504808); `spell_charges` when a proc |
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
| `attempt_auras` | `{"spell", "stacks", "source"}` set before every cast of a `cast` trigger, for a fixture that keeps another |
| | roll out of the trials (Blade Sermon 572548: Oath Chain at its cap, so Vindication grants no Oath: Vindication) |
| `applied_by` | `{"spell", "source"}`: the aura is not learned but granted by a cast of `spell` (an Oath), so the |
| | scenario sets it (`set_aura`, 1 stack) instead of learning it, and the chance is the aura's own `$<aura>s1` |
| | percent token in the tooltip of `spell`, which `tooltip` then copies (ADR 0151) |
| `question` | the log query of an `ambiguous_tooltip` entry ([questions](generate-and-compare.md#open-conformance-checks)) |

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
that the owner can rule. "Direct damage dealt" (Scourgebane) is settled by the owner ruling of 2026-11-11 (ADR 0130):
the chance applies to weapon hits, 20% per hit, and a Scourgebane strike 801832 never triggers another one, so its
entry has no `trial_readings` and counts strikes per landed swing instead (below).

An `attack` entry with `most_procs_per_trigger` (a positive whole number, with its citation in
`most_procs_per_trigger_source`, refused without one, with `trial_readings` or with a `cast` trigger) makes every
auto attack its own trigger: the part reads the main-hand hits and the event counts once, then for each trigger
attacks `dummy`, waits one weapon swing, stops and reads them again (`trigger_boundaries` in the model, one reading
of each count per boundary, 25 ms per step budgeted beside the swing). The comparison keeps the triggers with
exactly one landed main-hand hit, states how many it left out and gives the histogram of procs per one-hit
trigger. A trigger with more procs than the limit is an `alert` whatever the rate: under a chain a proc's own event
rolls again, so some swings give two or more procs (the prototype's chaining server: 77 of 1540 one-hit swings),
which a summed rate cannot see. Otherwise the rate is the one-hit triggers with a proc over the one-hit triggers,
judged like any other rate. With `events_per_proc` above 1, a one-hit trigger whose events are not a whole multiple
of it (one strike of Retribution's two) is an `alert` too, so the entry proves the stated number of events per proc
and not only their mean (ADR 0180).

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
| Scourgebane 92111 | `$520007h` 20% | attack ("Direct damage dealt") | 801832, tooltip `$801832s2` | scenario |
| Warrior of Dawn 560648 | `$h` 10% | attack ("Melee damage dealt") | 561156, tooltip `$561156s1` | scenario |
| Retribution 707391 | `$h` 20% | attack ("Melee damage dealt") | 525028 (2 per proc), `EffectTriggerSpell` | scenario |
| Light's Echo 520017, 520883 | `$h` 10%, 20% | cast of Argent Blade 807268 | 804929 or 807268 casts | 2 readings |
| Paladin Training 504808 | `$h` 8% | "Triggering Zealotry" | | `ambiguous_tooltip` |
| Blade Sermon 572548, 572554 | `$h` 5%, 10% | Zealotry | | `ambiguous_tooltip` |
| Condemnation 706325 | `$h` 15% | cast of Blade of Faith 803880 | 801450, `@s:801450:0@` | scenario |
| Transcendent Guardian 804571 | `$h` 40% | Temple Guardian 803792 at an ally | its refreshed charge | scenario |
| Lightkeeper (parry) 560835 | `$h` 15% | periodic damage of Condemn 804906 | 561016, `EffectTriggerSpell[0]` | scenario |
| Lightkeeper (burst) 560835 | `$h` 15% | periodic damage of Condemn 804906 | 561277 (damage), `EffectTriggerSpell[1]` | scenario |
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
so Condemnation has a single reading, each damage tick (settled from the Ascension logs below; its own `Check()`
does not gate on the periodic flag, but Blade of Faith's only damage-dealing effect is its DoT tick, so every
damage event the check sees is in practice a tick). Pulverizing 524620 has its own `spell_proc` row too (`Chance`
0, read on 2026-11-08), from the same native re-insert as the four `aura_ascension_templar_event` auras above, with
its `Chance` zeroed by `rev_20260919_20_coa_proc_chance_parity.sql`; the DBC `ProcChance` 15% fallback
(`SpellMgr.cpp:2371-2372`) is a plain `EffectTriggerSpell` roll on each damaging Condemn cast, with no scripted
override and a single reading (damage is the only trigger named by the tooltip), like Lightkeeper's two entries
below.
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
| Light's Echo 520017 | 5 | player casts only | 173 in 1435 | 0.100 to 0.145 | `alert` | `ambiguous_tooltip` |
| | | every Argent Blade strike | 173 in 1608 | 0.089 to 0.129 | `ok` | |
| Light's Echo 520883 | 8 | player casts only | 519 in 2552 | 0.184 to 0.225 | `ok` | `ambiguous_tooltip` |
| | | every Argent Blade strike | 519 in 3071 | 0.152 to 0.187 | `alert` | |

Light's Echo parts made 287 and 319 player casts. Every extra Argent Blade strike was a cast of 807268; 804929
was never cast. A Light's Echo part takes 443 to 491 s of game time in 3.2 to 4.3 s of real time. Scourgebane
92111 was also measured this round with the same two readings (13 parts, 196 or 197 swings each, 525 in 2554
auto attacks only, 525 in 3079 every direct damage event); round 4's Ascension-log pass (below) read its own
strikes as triggering further strikes and kept the second reading only; the owner ruling of 2026-11-11 withdrew
that reading (a strike never triggers another one) and the entry now counts strikes per landed swing.

Measured on 2026-11-06 (stamps `20261106-130841`, 26 Condemnation parts in 36.2 s, and `20261106-130708`, 11
Transcendent Guardian parts, simulated clock, no failed cast):

| Aura | Parts | Reading | Procs in trials | Wilson 99% | Reading verdict | Verdict |
|---|---|---|---|---|---|---|
| Transcendent Guardian 804571 | 11 | casts at the ally | 1509 in 3828 | 0.374 to 0.415 | `ok` | `ok` |

Condemnation 706325 was measured the same session with the same two readings this round settled (622 in 2054 each
cast, `alert`; 622 in 4134 each damage tick, `ok`); see the single-reading measurement below.

Lightkeeper 560835 is absent from both `TemplarEvents` and `TemplarCastDrivers` (grepped `src/server/coa/*.cpp` for
`560835`): it is one of two Templar proc entries of the nine that are plain, native `ProcFlags`/`ProcChance`/
`EffectTriggerSpell` procs with no scripted override, the other being Pulverizing 524620 below. Its two
`EffectTriggerSpell` slots each roll their own 15% independently on the same periodic tick of Condemn 804906; no
`spell_proc` row exists for it, so `spell_proc` is `{}` for both entries, like the other auras with no row.

Pulverizing has a single reading (damaging Condemn casts), so it needs no `trial_readings` split. Measured on
2026-11-08 (`report.json` `.cache/verify-all/20261108-125057/report.json`, simulated clock, 26 of 26 parts, no
failed cast):

| Aura | Reading | Procs in trials | Wilson 99% | Verdict |
|---|---|---|---|---|
| Pulverizing 524620 | damage events of Condemn 804906 on the target | 622 in 4472 | 0.126 to 0.153 | `ok` |

### Two-reading tooltips settled from the Ascension logs (round 4)

Round 4's owner ruling (2026-11-08) settles an ambiguous tooltip from the Ascension logs
(`~/Projects/coa-log-history`, May-Aug 2026) before asking a player. Three entries above (Lightkeeper's two
`trial_readings` entries and Condemnation's) carried an "each cast" reading alongside "each damage tick"; the
logs settle all three as "each damage tick" only, and Scourgebane's own two readings settle as "every direct
damage event, Scourgebane strikes included" only (dropping "auto attacks only"), so `trial_readings` for all
four now held a single entry and no `ambiguous_tooltip` verdict remained for any of them. The Scourgebane part of
this ruling is withdrawn by the owner ruling of 2026-11-11 (ADR 0130); the bullet below records what round 4 and
round 10 read and why it did not hold:

- **Lightkeeper 560835 (561016, 561277) and Condemnation 706325 — "each cast" is mechanically impossible, not
  just disfavoured.** Lightkeeper's own `ProcFlags` is `262144`, exactly `PROC_FLAG_DONE_PERIODIC`
  (`src/server/game/Spells/SpellMgr.h:140`): the engine only rolls `EffectTriggerSpell[0]`/`[1]` on a periodic
  tick, so a plain Condemn cast never reaches the check. Condemnation 706325 is scripted
  (`AscensionTemplarEvents.cpp:81`) and does not itself gate on the periodic flag, but Condemn/Blade of Faith's
  only damage-dealing effect is their DoT tick, so every damage event the check sees is in practice a tick too.
  Log corroboration: one Zealotry-bearing log gives 2259 periodic ticks of Condemn against 250 casts (about 9
  ticks per cast); archive-wide, Zealotry 801450's dominant triggers are periodic Condemn/Blade of Faith damage
  (9712 and 6164 of about 48000 hits), an order of magnitude ahead of any cast-shaped trigger. Citation:
  `2026-11-08, Condemn 567539 periodic-tick/cast ratio ~9:1, Ascension combat log, private archive`.
- **Scourgebane 92111 — settled in round 4 as "every direct damage event, Scourgebane strikes included",
  withdrawn on 2026-11-11.** `Check()`'s case
  `92111`/`520007` (`AscensionTemplarEvents.cpp:58`) excludes only Light's Echo's extra Argent Blade strike
  (804929) from re-triggering Scourgebane; it does not exclude Scourgebane's own strike (801832). Across the 13
  archive logs containing Scourgebane (18476 hits), 982 pairs of consecutive Scourgebane hits from the same
  source land on the same target at the exact same millisecond with no other event between them — one
  Scourgebane strike's own damage re-rolling the 20% chance and landing a second strike inside one server tick;
  this is a lower bound (same-target-same-millisecond only). Citation: `2026-11-08, Scourgebane 801832
  same-target same-ms chains 982 of 18476 hits (13 logs), Ascension combat log, private archive`. This drops the
  verdict from `ambiguous_tooltip` to a reported `alert`, not `ok`: the single surviving reading is the
  tooltip-correct one, and the measured rate undershoots 20% once self-chains are counted — a real finding for
  an implementer to trace (root cause not established by this pass), not a fix proposed here.
  Round 10 then added the chain to the server (`822b1f5a74`) so that this reading would pass, and capped it at 8
  strikes (`59cac10ecd`). The prototype's K4 diagnosis (2026-11-10) showed both were wrong: the same-millisecond
  grouping does not separate a chain from other same-millisecond strikes, and after 1229 isolated melee swings in
  the same 13 logs, 263 gave a strike on the swing's target within 200 ms and 1 a second one, where a chain gives
  about 64; the summed rate of this reading gives 0.20 for a 20% chain and for a 25% server without one alike.
  Owner ruling 2026-11-11: a Scourgebane strike never triggers another one. The chain and its cap are removed
  (`AscensionTemplarEvents.cpp` is back to the reentrancy guard and the `Derived()` exclusion that refuse 801832),
  the entry counts strikes per landed swing (`most_procs_per_trigger` 1), and catalog scenario
  `templar-scourgebane-strike-never-retriggers` forces the chance to 100% and reads exactly 1 strike per landed
  swing, where the chaining server read 8.

Measured on 2026-11-09, before the chain was added (gameplay stage, `.cache/verify-all/20261109-093335/report.json`,
simulated clock, no failed cast, exploratory-only selection, 91 of 91 parts passed natively; `conformance.py compare`
against that stamp, `.cache/conformance/r4-log-checks/verdicts.json`):

| Aura | Parts | Reading | Procs in trials | Wilson 99% | Verdict |
|---|---|---|---|---|---|
| Scourgebane 92111 | 13 | every direct damage event, Scourgebane strikes included | 523 in 3084 | 0.1529 to 0.1877 | `alert` |
| Condemnation 706325 | 26 | each damage tick | 627 in 4134 | 0.1379 to 0.1666 | `ok` |
| Lightkeeper (parry) 560835 | 26 | each damage tick | 689 in 4472 | 0.1407 to 0.1685 | `ok` |
| Lightkeeper (burst) 560835 | 26 | each damage tick | 659 in 4472 | 0.1342 to 0.1615 | `ok` |

`questions.md` from this run lists no open check for any of the four: Lightkeeper and Condemnation are `ok` and
Scourgebane's `alert` is a server finding for an implementer, not a player question (its tooltip reading is
already settled; no reading disagreement remains to ask about). `report.md` cross-checks the player reports on
file: the 2026-11-07 report "Zealotry can proc back to back on each damage tick of Blade of Faith" corroborates
Condemnation's settled reading (`ok`); the 2026-11-07 report "Scourgebane does not proc off itself" is
contradicted by the settled reading (`alert`) and is set aside per the owner's ruling that the logs decide. The
isolated-swing log count and the owner ruling of 2026-11-11 later agreed with that report; the Scourgebane row's
`alert` was the round 4 reading's own blindness (523 strikes in 2561 swings is 0.204 per swing).

Measured on 2026-11-11 with one strike per landed swing at most (`most_procs_per_trigger` 1, server without the
chain, `.cache/verify-all/20261111-033743` and `20261111-033923`, simulated clock, 13 of 13 parts each):

| Aura | Run | Procs per one-hit swing (0 / 1) | Swings with a strike | Wilson 99% | Verdict |
|---|---|---|---|---|---|
| Scourgebane 92111 | 1 | 2060 / 488 | 488 in 2548 | 0.1723 to 0.2124 | `ok` |
| Scourgebane 92111 | 2 | 2029 / 519 | 519 in 2548 | 0.1839 to 0.2250 | `ok` |

Zealotry 801450 itself has three independently-coded trigger paths, found while tracing Condemnation's trigger
for this pass: the already-modelled 706325 periodic-tick path and 92108 off-hand-swing path, plus an
Oath: Vindication (805332) ability-cast roll (`AscensionTemplarAbilities.cpp:297`) outside both auras, confirmed
by 1021 archive instances of a logged Vindication cast immediately preceding a Zealotry hit. This third path
already has its own code and is not itself a `procs`/`triggers` entry in this class file; no entry or check is
added for it here. Citation: `2026-11-08, Zealotry 801450 trigger attribution across 16 logs (48473 hits),
Ascension combat log, private archive`.

Two further two-reading disagreements named by this round could not be settled from the archive and stay open in
`owner-decisions.md` instead: Blade Sermon 572548/572554's double-hit rate (`grep` for its name or either spell
id returns zero files across all 186 logs) and Light's Echo 520017/520883's self-chain question and real-play
mismatch (neither rank is ever applied anywhere in the archive). Both entries are unchanged by this pass.

### Nested proc rate (round 6, Blade Sermon)

Owner ruling 2026-11-09 settles Blade Sermon 572548/572554 (`$h` chance to trigger Zealotry 801450 twice): the
chance applies to all three Zealotry sources (periodic tick 706325, off-hand swing 92108, Oath: Vindication
805332), which already reach a single shared helper (`AscensionTemplar.cpp:212-220` `Zealotry()`) with the
reroll unconditional for every caller. No `procs`/`triggers` entry kind in this file can measure this directly:
the reroll's own cast (801450) is the *same spell id* as the hit that triggered it, so no existing metric tells
a first hit from its repeat apart within one sample. A `kind: "proc_rate_delta"` entry (`procs.py`) adds a
with/without-the-aura delta inside one scenario instead of a direct rate:

| Field (beyond the plain `procs` fields above) | Content |
|---|---|
| `kind` | `"proc_rate_delta"` |
| `baseline_co_learn` | the spell(s) that must be learned so the `trigger` produces the `proc_spell` at all, *without* this entry's own `aura` (for Blade Sermon: `[706325]`, Condemnation, the periodic-tick Zealotry source) |
| `delta_attempts` | attempts scheduled per phase; defaults to `trials_needed(chance/100)` (no safety margin), but a delta needs far more than a single-rate `procs` entry at the same chance (see below) and is usually set explicitly |

Each part of the scenario runs two phases over the identical `trigger`/`proc_spell`: a baseline phase with only
`baseline_co_learn` known, then a phase with the entry's own `aura` additionally learned. Both phases measure
the same way a plain `procs` CAST-trigger entry does (`trials_step`, `spell_count_step`); because the main
phase's counters are cumulative since the scenario (not the phase) began, its own trials/events are the
cumulative reading at the end less the baseline phase's own cumulative reading, not the raw end value.

`judge_proc_delta` (`compare.py`) computes `p_baseline = baseline_events / baseline_trials` and `p_main =
events / trials` (after that subtraction) and a two-proportion z: `(p_main - p_baseline) / sqrt(p_main(1 -
p_main)/trials + p_baseline(1 - p_baseline)/baseline_trials)`. The verdict is `ok` when `z >= 2.576` (one-sided
99%, i.e. the with-aura rate is above the baseline rate, not by chance) **and** the measured chance (`p_main /
p_baseline - 1`) lands between 0 and 3x the tooltip chance (a loose sanity envelope, not a precision target).
This is a weaker standard than the `WILSON_RULE` a plain `procs` entry holds itself to: it proves the chance is
positive and roughly the right order of magnitude, not that it sits within +-2.5 points of the tooltip value.
Reaching that tighter standard with this with/without design needs, by the delta method's own variance
(`Var(chance_hat) ~= (Var(p_main)/p_baseline^2 + Var(p_baseline) x (p_main/p_baseline^2)^2)`, both terms O(1/n)),
roughly two orders of magnitude more trials than a direct `procs` rate at the same chance (about 130000 for
Blade Sermon's 10% rank from its ~15% baseline) - out of proportion with a single round, so this kind does not
attempt it.

The z-statistic's own sampling variance is always ~1 regardless of trial count (only its mean shifts with more
trials), so a trial count picked to put the *expected* z just over 2.576 gives a check that is `ok` about half
the time and `alert` the other half - flaky, not wrong. `delta_attempts` should be sized so the expected z clears
the 99% threshold with margin (empirically, 2031 attempts/phase gave z between 1.67 and 3.08 across repeated
runs of Blade Sermon 572554's 10% rank against its ~15% Condemnation baseline; 12000 attempts/phase gave z 5.00
and 5.90 across two repeated runs, reliably `ok`).

Blade Sermon 572554 (10%) carries this check (`baseline_co_learn: [706325]`, `delta_attempts: 12000`,
300 parts), measured `ok` (stamp `20261109-163213`: baseline 3662 in 24300, with-aura 4139 in 24300, z 5.90,
measured chance +0.1303 against tooltip 0.1). Blade Sermon 572548 (5%) could not reach `ok` within this round's
budget: its smaller nested chance needs a baseline many times larger before the same two-proportion z reliably
clears 2.576 (at 2031 attempts/phase, stamp `20261109-162302`: baseline 590 in 4131, with-aura 645 in 4131, z
1.70, measured chance +0.0932 against tooltip 0.05 - directionally consistent, underpowered); it stays
`unmodelled` with this measurement recorded in its `reason`, since 572554's identical code path (same function,
same lines, only a different `ProcChance` operand) is the runtime evidence for both ranks sharing one mechanism.
The off-hand-swing (92108) and Oath: Vindication (805332) sources named by the same ruling are not independently
measurable by this harness for reasons already on their own entries (92108: no `CanDualWield` path for Templar;
805332/504107: no fixture to co-learn the Oath aura before a roll that depends on it) - not a gap this round
introduces, and out of scope for a `baseline_co_learn` fixture to close.
