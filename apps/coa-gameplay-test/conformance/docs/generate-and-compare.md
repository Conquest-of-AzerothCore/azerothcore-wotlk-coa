# Generate and compare

```sh
cd apps/coa-gameplay-test/conformance
python3 -B conformance.py generate --class 19 --out DIR [--spell ID ...] [--passive ID ...] [--proc AURA ...] \
  [--trigger AURA ...] [--behaviour SPELL ...] [--target-gate SPELL ...] [--learned-hit SPELL ...] \
  [--stack [--passes N]] [--controls]
python -B ../../../tools/verify_all.py --stages gameplay --scenario DIR/scenarios/*.json
python3 -B conformance.py compare --manifest DIR/manifest.json --results .cache/verify-all/STAMP [--out OUT] \
  [--build BUILD]
```

`generate` writes one no-combat scenario per rank, the hit scenario of each active spell's highest rank, the
with/without scenario of each passive (kind `passive`, no `hit` entry), the parts of each proc and trigger entry
and, without `--spell`, `--passive`, `--proc` or `--trigger`, the melee scenario, into `DIR/scenarios/`, and
`DIR/manifest.json`. `--spell` takes a class spell id or a rank id, `--passive` a passive class spell id or rank id
(its passive scenario only; an active spell is an error), `--proc` the aura of a proc entry, `--trigger` the aura of
a trigger entry, `--stack` the passes of the talent stack (`--passes`, 5 by default), `--controls` the control
entries of `controls/<class>.json` (stock spells that check engine behaviour, ADR 0255); each selects only what it
names. A passive scenario is named `conformance-<class>-passive-<rank>`, a proc part
`conformance-<class>-proc-<aura>-part-<n>`, a trigger part `conformance-<class>-trigger-<aura>-part-<n>`, a stack
pass `conformance-<class>-stack-<config>-pass-<n>`. A hit expectation that is entirely
`unmodelled` gets no scenario file. A file holds `json.dumps(scenario, indent=2)` and a newline, the bytes the
runner writes and hashes as `scenario_sha256` (`batch.py` `write_case`), and is named after its exploratory key
(`batch.py` `exploratory_key`), for example `conformance-templar-value-807268`. The manifest keeps the class file,
the DBC directory, the known modifiers read from `Spell.dbc` and, per scenario, its key, file, SHA-256, spell, rank,
the tooltip tokens read at generation and its `Expectation` list.

`generate`, `sheets` and `scaffold` refuse a DBC set whose `Spell.dbc` sha256 differs from the server set's
(`profile.DBC_DIR`), whether it comes from the class file's `dbc_dir` or from `scaffold --dbc-dir`; `generate`
records the sha in the manifest (`spell_dbc_sha256`) and `compare` refuses a manifest whose recorded sha is not the
server set's.

`compare` reads `STAMP/gameplay/exploratory/<key>/result.json`, or the result folder whose recorded hash is the
manifest hash when no folder has the key. The recorded hash is `scenario_sha256` of the folder's `summary.json`
(or the hash of its `scenario.json`). A result whose hash differs from the manifest stops the comparison with an
error and no verdict. A scenario without a result has no verdict and is listed in the report. The harness writes
every `actual` as a string; it is converted to a number, and a value that is not one is an error.

Each run carries its build: the server commit parsed from `server_version` of `result.json` (`AzerothCore rev.
<commit>`, a trailing `+` for a modified tree kept), the worldserver `binary_sha256` of `summary.json`, and the
`run_id`. `compare --build <sha256 or commit>` names the build being judged and refuses the runs of any other build
(no verdict, listed in `report.md` under "Runs refused"); without `--build` the results must hold one build,
otherwise `compare` stops with exit 5 and no verdict. Every verdict, alerts included, then carries `server_commit`,
`build` (the worldserver sha256) and `runs` (the run ids it was judged from, empty for a verdict decided by rule), in
`verdicts.json` and as the last three `alerts.tsv` columns (ADR 0118).

`alerts.tsv`
(default: the manifest directory) has one row per verdict that is neither `ok`, `measured`, `closed` nor
`not_measured`; `report.md` counts the
verdicts per status, per spell and, for passive scenarios, per measurement family ("Passives"), and lists the known
modifiers, the probe auras, the scenarios without a result and the runs that did not pass. `verdicts.json` keeps every
verdict with its interval, detail and explanation (schema 1) for `diff`, with the manifest's `Spell.dbc` sha256 and
the judged `build` and `server_commit` (shared by every verdict, `null` otherwise) in its header. `questions.md` lists the checks a reviewer must
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

### Behaviour sheets and reader records

```sh
python3 -B conformance.py sheets --class 19 --out DIR --spell ID [--spell ID ...] [--verdicts COMPARE_OUT]
python3 -B score.py --records RECORDS_DIR [--records-b RECORDS_B_DIR] --class-file classes/templar.json [--strict] [--out score.json]
```

`sheets` (`sheets.py`) writes one `DIR/<spell_id>.json` and one `DIR/<spell_id>.txt` per `--spell`, built only from
code this package already runs: the tooltip's `Description[enUS]`, its cleaned text (`behaviours.cleaned_tooltip`),
and its resolved tokens at two `CasterStats` bounds (`questions.ANY_STATS`: level 1 all-zero, level 80
thousand-everywhere, the same pair `questions.py` uses to find stat-independent tokens) via `tooltip.read_tooltip`,
which already expands one `@s:<id>:<flags>@` reference inline (`tooltip.py`'s own `MAX_EXPANSION_DEPTH`); every
effect's family, token, targets and reason from `passives.classify`, called directly with `spell_id == rank_id` so
it works on any spell id, not only a class's own passive ranks; the raw `ProcFlags`, `ProcChance`, `ProcCharges` and
`EffectTriggerSpell[0..2]` fields (candidate proc/trigger material no existing module decodes for a spell with no
hand-written entry yet); `values.facts_of`'s duration/cooldown/cast-time/aura-state facts; every `grep -rn -w
<spell_id>` hit under `src/server/coa` (file:line, verbatim, not interpreted) as the scripted-hook material a DBC-only
reading cannot see; `sheets.talent_catalog_entry`, the spell's own entry in `CharacterAdvancement.dbc` (CoA's talent
catalog, not the stock `Talent` table) when the spell is one of a `RankSpell[0..4]`, giving `entry`, `rank_index` and
every sibling `ranks` id so a reader can tell a talent rank apart from an ordinary ability and key a
`talent_modifiers` record on it; and, when `--verdicts` names a `compare` output directory, that spell's existing
verdicts. A sheet never includes a `classes/<name>.json` entry or a verdict's pass/fail judgement beyond the raw
verdict rows themselves, so a reader given only the sheet cannot see what the class file already claims (the
blind-reader requirement of the scale-out design, `.agents/plans/class-conformance-3/scale-out-sheets.md`).

A **reader record** (`records.py`) is a reader's claim about one spell's one `entry_kind`: `spell_id`, `entry_kind`
(one of the 9 kinds a class file's `procs`/`triggers`/`behaviours`/`passive_targets`/`talent_modifiers`/
`effect_overrides`/`unmodelled_effects`/`literal_tokens`/`effect_notes` lists already carry), `entry` (the literal
class-file entry, validated against `REQUIRED_ENTRY_FIELDS[entry_kind]`, the fields every existing Templar entry of
that kind has in common), `sources` (one `{token_or_field, sheet_section, value, citation}` per cited sheet value),
`reader`, `confidence` (`high`/`low`) and `rationale`. `records.record_schema()` exports this shape as a JSON
Schema document, with a `guidance` block spelling out two conventions the schema fields alone do not state:
`literal_tokens` is only for a tooltip number with no DBC token or effect behind it at all, never a hedge for a
number a reader cannot bind to an effect index (that belongs in a residual); and `unmodelled_effects`/
`effect_notes` are scored as the same claim (see `score.py` below), so either name is correct.
`records.write_record_schema` writes it to a file. `records.validate_record` checks the required fields and that
every kind's key fields (`KEY_FIELDS`, e.g. `aura` for `procs`/`triggers`, `spell` for `behaviours`) are present.
`records.traceability_errors(record, sheet)` is the deterministic gate: every source's `value` (a bare literal, or
a list of them for a multi-target claim; description and units belong only in `citation`) must appear verbatim in
`json.dumps(sheet, sort_keys=True)`, and every number in `entry` other than its own key fields must equal some
source's `value` — a record that cites nothing, or claims a number no source matches, is rejected before any human
sees it. `records.convert_records` groups a list of records by `entry_kind` into the `{kind: [entry, ...]}` shape a
`classes/<name>.json` merge expects. A reading round's own output is one of three batch shapes, not one file per
record (a single record, a `{..., "records": [...], "residuals": [...]}` wrapper, or a bare list mixing record and
residual dicts); `records.extract_batch_records`/`extract_batch_residuals` recognise all three, and
`records.load_records`/`load_residuals` apply them to every `*.json` file in a directory, so `score.py` below runs
directly on a round's own `records/<class>/<side>/` directory.

`score.py` (`score.py --records RECORDS_DIR --class-file FILE`) loads every record in `RECORDS_DIR`
(`records.load_records`, batch shapes included) and, per kind, groups both ground-truth and generated entries by
their `KEY_FIELDS` key (a list per key, not a single entry: a `KEY_FIELDS` key is not guaranteed unique — e.g.
Templar's `procs` carry two distinct `aura=560835` entries, two field-for-field identical `aura=803163` entries
that differ only in a non-`KEY_FIELDS` `trigger` sub-object, `triggers` has a duplicate `aura=804927`, `behaviours`
a duplicate `spell=300504`). `unmodelled_effects` and `effect_notes` require the same fields (`effect`, `reason`,
`spell`) and are scored as one claim under `effect_notes`; `unmodelled_effects` is not a separate row.
Within one key, each ground-truth entry claims the first generated entry it field-matches (removing it from that
key's remaining pool); a ground-truth entry left unclaimed is a **miss** only if the pool is then empty, otherwise
it consumes one remaining generated entry as a **wrong_value**; every generated entry still unclaimed at the end
(whether its key matches no ground-truth key, or outnumbers it) is a **false_claim**. A **match** is a key shared
by both sides whose *scored* fields agree within the same tolerance `compare.py` uses to call a measurement `ok`:
`max(compare.ABSOLUTE_TOLERANCE, compare.RELATIVE_TOLERANCE * expected)` (currently `max(1, 0.5%)`), not an
arbitrary separate constant — so "close enough" means the same thing here as it means in `alerts.tsv`. By default
the scored fields are each kind's `OPERATIONAL_FIELDS` (plus its key fields): the measurable substance of the
claim (`aura`+`observe_spell` for `triggers`, `spell`+`effect`+`targets` for `passive_targets`, and so on) rather
than every field either side happens to carry — two independent readers, or a reader and the hand file, phrase a
`name`/`quote`/`tooltip`/`reason`/… field differently for the identical fact, and a field only one side bothers to
add (an investigation aside the schema does not require) counts for neither side. `--strict` compares every field
of both entries instead, the literal field-by-field equality the design doc first proposed; it is far stricter
since free-text wording is almost never identical between two independent authors.
`precision = match / (match + false_claim + wrong_value)`; `recall = match / (match + miss)`; both `None` when
their denominator is 0. `--records-b RECORDS_B_DIR` scores only the records both sides agree on: `score.merge_sides`
groups each side by kind and key, promotes a pair that `entries_match`es (same strictness) into the merged set,
and reports the rest as `only_a`/`only_b` (one side only) or a same-key disagreeing pair as a conflict — the
`merge` block in the output gives these four counts. This is the validation protocol of
`.agents/plans/class-conformance-3/scale-out-sheets.md` part 3, scored against Templar's own hand-written entries
as ground truth.

### Prove runner

```sh
python3 -B conformance.py prove --class 19 [--behaviour SPELL ...] [--proc AURA ...] [--trigger AURA ...] \
    --out DIR --worktree W [--runs 2] [--build] [--timeout-ms 600000] [--clauses LEDGER]
```

`prove` runs the gameplay passes of chosen class-file entries deterministically (ADR 0121). Run it from
`apps/coa-gameplay-test/conformance`, in the foreground; `--timeout-ms` (default 600000) limits one `coa-verify` run.
It starts nothing but the `coa-verify` command below.

`coa-verify` is optional external tooling from the separate coa-server-guide project, not part of this
repository: a workstation wrapper that forwards its arguments to `tools/verify_all.py` (its `--ram` route uses an
in-RAM MySQL). `prove` has no option for another runner (`ProveSpec.verify` defaults to `('coa-verify',)`), so
without that tooling it cannot run as documented. Run the generated scenarios twice through
`python -B tools/verify_all.py --stages gameplay --scenario ...` and judge each run with `compare` instead.

1. Generates exactly the given entries into `DIR/scenarios` with `DIR/manifest.json`: the behaviour entries of the
   `--behaviour` spells, the proc entries of the `--proc` auras and the trigger entries of the `--trigger` auras. At
   least one is required; `DIR` must be new or empty and lie under the worktree or its main checkout, the two
   directories `coa-verify` mounts.
2. For each run (at least 2), executes in the foreground `coa-verify --worktree W --ram --stages gameplay --scenario
   <every scenario file>` (`build,gameplay` on run 1 only with `--build`), with the timeout; never `--jobs`. A timeout
   stops the process group (SIGTERM, then SIGKILL after 30 s) and the run fails. The run directory comes from the
   `VERIFY ALL: <status> <report.json>` line of `DIR/run<n>/verify.log`; `INCOMPLETE` is the normal status of
   exploratory scenario files. A failed build stage, scenario drift, results of several builds, or a run (pilot
   included) in which any scenario of the manifest has no result fails the proof; so do runs judged on different
   builds. A missing result stops the proof at that run, writes no fragment and lists the scenarios (ADR 0122).
3. Compares each run into `DIR/run<n>/` (`alerts.tsv`, `report.md`, `verdicts.json`, `questions.md`, a copy of
   `verify-report.json`) and diffs run 1 against each later run into `DIR/flips/` (`impact.md`).
4. With `--clauses`, writes `DIR/fragment.json`: the ledger claims whose labels all run here (an ordinal-free label
   resolved to every `#<n>` occurrence; an entry with declared `claims` gives one row when every claim's labels run,
   otherwise one row per claim whose labels run, which never closes the clause, see
   [Stated claims](clause-ledger.md#stated-claims)), kept when every label is `ok`, `tolerated` or `closed` in every
   run, each
   with `evidence` (`behaviour` only when [clause coverage](clause-ledger.md#two-proof-statuses) gives it in every
   run, else `data`) and the server `Spell.dbc` sha256. Without `--clauses` the fragment is empty.
5. Writes `DIR/summary.json`: `sizing` (the pilot's trials and per-label records, null without a pilot, see
   below); per run the `coa-verify`
   command, status, stage seconds (`gameplay_seconds`), scenarios with and without a result (`missing_results`
   names the latter), the worldserver `build`,
   the `server_commit` and the verdict counts per status; `flips`, `not_judged`, `flip_reports`, the `fragment` row
   count and the excluded rows, `coverage` per run when `--clauses` is given (proven, behaviour, data, total,
   not_measured, tool_gaps_accepted, tool_gaps_pending, resolved), `missing_results` (the run directory and scenario
   keys of the run that lacked results),
   `failed_run` (that run's record), `failure` and `exit`.

A flip is two judged verdicts of one (label, check, scenario) whose status classes differ: conformant (`ok`,
`tolerated`, `closed`) against another status, or one non-conformant status against another, or a label present in
one run only. `ok` against `tolerated` is not a flip. `insufficient_trials` is not judged: it never flips and never
sets exit 1 by itself; `not_judged` lists each such verdict with its per-run statuses and the largest
`trials_needed`, the count to rerun with. Exit status: 0 no flip, 1 a flip, 2 scenario drift, 3 a scenario without
result, 4 a failed run. Exit 0 needs a result for every scenario of the manifest in every run.

`prove.py` holds the runner; `prove_ledger.py` supplies the ledger rows, their evidence and the coverage per run.
`prove.prove` also takes a `Pilot` (three callables: generate a pilot manifest or none, size labels from the pilot
verdicts, generate the sized manifest): the pilot runs once into `DIR/pilot/` before the judged runs, is never
judged, and the judged runs must be on its build. The command passes `pilot.hit_ratio_pilot` when a `--behaviour`
entry is a `hit_ratio`: the pilot generates those entries at 20 trials (`generate(..., trials={label: n})`), each
verdict's `detail.sized_trials` (the trials whose 99% half-width would be 0.8 of half the owner's band, ADR 0125)
sizes the judged runs, never below the pilot's 20 and capped at what one scenario holds (`detail.trial_limit`;
`capped` in the record); a label without a pilot verdict or interval keeps its class-file trials.

### Server mutants and K3 consumption

```sh
python3 -B conformance.py mutate --manifest DIR/manifest.json --mutants MUTANTS
python3 -B conformance.py k3 --probes PROBES --mutants MUTANTS --manifest DIR/manifest.json \
    --baseline BASE --mutant MUT --out K3.json [--consumption classes/<class>_consumption.json]
```

A server mutant asks whether the value a readback reads is the value the acting path uses (ADR 0129). `mutate`
rewrites a generated manifest in place: every scenario carrying a mutant's `label` gets, right after its `settle`
wait, the harness step `spell_mod_mutant` (a player-scoped percent spell modifier of one native operation on one
spell, owned by a harness dummy aura, see the gameplay-test README) and, as its last step, an assert that every
mutant of the scenario is still active (`spell_mod_mutants`), so a mutant lost mid-case fails the scenario instead
of reading as unconsumed. The manifest records the mutants and their scenarios; the scenario sha256 entries are
rewritten. A mutants file is a JSON array of `{label, spell, op, factor}`: `op` by name (`duration`, `effect1`,
`effect2`, `effect3`, `all_effects`, `radius`, `cooldown`, `jump_targets`, `chance_of_success`,
`value_multiplier`), `factor` 2 or 0 only (x0 where the mechanic allows a zero, such as a chance or an amount; x2
for a duration or a target count, whose zero can mean unlimited). A probe only asks whether the value is read, so
the change lies far outside every tolerance. Mutants that change an aura amount must come before the aura exists:
the step fails when the player already has an aura of the spell.

Run the unmutated and the mutated manifests of one build at least twice each through `coa-verify`, compare each run
into `BASE/run<n>` and `MUT/run<n>`, then run `k3`. A probe file is a JSON array of `{label, spell, effect,
observation[, mutant, predicted]}`: `label` is the readback the row is about, `observation` the verdict label read in
the baseline runs, `mutant` (default `observation`) the verdict label read in the mutant runs, `predicted` the
reading the observation would give if the value were consumed. `k3` writes `K3.json`
(`build`, `contaminated`, per probe `result` and `reason`, `rows`) and exits 3 when an unmutated verdict changed
status class between the baseline and the mutant runs or went missing (shared-process contamination). Per probe:

- the observation must be conformant in every baseline run and observe an acting outcome (an event, a count, a
  rate, an expiry: coverage `acting`), never a readback or a `data_only` read;
- `consumed` when the mutant reading alerts in every mutant run with a measured value;
- `not_consumed` when it stays conformant in every mutant run and `predicted` lies outside the tolerance of the
  baseline expected value; without such a prediction no row is written;
- no row when CoA code passes its own amount through the mutated spell's modifier channel
  (`ApplySpellMod(<spell>` in `src/server/coa`, outside the harness): a spell modifier mutant then moves the
  reading whether or not the DBC value is read (Scourgebane's literal 20% chance, `AscensionTemplarEvents.cpp`).

Rows `{label, route: K3, spell, effect, build, evidence, result}` merge into `--consumption`
(`classes/<class>_consumption.json`, a rerun of the same label and build replaces its row). `coverage --clauses`
reads the file beside the ledger: on the verdicts' build, a `consumed` row turns a conformant readback label into
behaviour evidence; a `not_consumed` row keeps it data and lists it. K3 is the only consumption route: the K1
static join needs the value dump, which is not adopted, and no K1+K2 rows are written.

### Drawing a batch sample

```sh
python3 -B conformance.py sample --buckets BUCKETS.json --seed SEED --total 40 --bucket U --bucket D --bucket A \
  --minimum A=4 --first-chunk 10 --out SAMPLE.json
```

`sample` draws the clauses a cost-measuring batch works on, with no judgement: the unit is the spell. The bucket file
is a JSON array (or `{"clauses": [...]}`) of clauses, each with an integer `spell` and a `bucket`; clauses of a bucket
not named by `--bucket` are never drawn. Quotas are proportional to the bucket sizes (largest remainder, summing to
`--total`); a `--minimum` raises a bucket to its floor (or to its size when smaller) and the other buckets share the
rest. Inside each bucket the spells are ordered by sha256 of `<seed>|<spell id>`, ascending, and each drawn spell
brings every clause it has in that bucket, until the bucket holds its quota (whole spells, so a bucket may exceed
it). Chunk 1 takes whole spells, interleaved across the buckets in `--bucket` order, until it holds at least
`--first-chunk` clauses; a spell drawn in two buckets goes to one chunk with all its clauses. The output keeps the
seed, sizes, quotas, the clauses held per bucket, both chunks and the draws in draw order (`order`, `bucket`,
`spell`, `sha256`, `chunk`, `clauses`); the same inputs write the same file.

### Per-spell packets

```sh
python3 -B conformance.py packets --class 19 --sample SAMPLE.json --chunk 2 --buckets BUCKETS.json \
  --class-map CLASS-MAP.json --out PACKETS/
```

`packets` writes `<spell id>.md` for every spell of one chunk of a `sample` file, built with no judgement from the
server DBC set, the class file, the bucket file and an optional class map, which it only reads:

- the tooltip, with each token followed by the value read with the class file's reference stats (`$s1[=3]`), and the
  tokens it cannot read;
- the `Spell.dbc` fields of the spell, of the spells its tokens name and of its triggered spells, with the DBC labels;
- the `script_touch_hits` of the spell's bucket rows (file and line);
- every bucket row of the spell (bucket, evidence, `token_kind`, labels and their statuses), marked by chunk;
- the class-file entries of a check section (`behaviours`, `procs`, `triggers`, `talent_modifiers`,
  `target_aura_gates`, `learned_hits`, the player observations and tooltip readings) that name the spell or a spell its tokens name;
- for each check kind those entries or the rows' labels name, the nearest other entry of that section and kind: the
  most shared `(Effect, EffectApplyAuraName)` pairs, then the smallest spell id distance;
- the fixtures: the other class-file sections naming those spells, and the behaviour kinds the generator builds;
- the class map fields `risk`, `gap`, `custom_mechanics`, `log_casts`, `log_other_events` and `log_linked_events`,
  matched by spell id, else by a map spell of the same name whose hits name the id.

The command prints its runtime. The same inputs write the same files.

### Verdicts

| Status | Given to |
|---|---|
| `ok` | a measurement within its rule below |
| `alert` | a measurement outside its rule, a missing measurement, or tokens that changed since generation |
| `unreadable` | an expectation whose rule starts with `unreadable: ` |
| `unmodelled` | an `unmodelled` check, a `unmodelled: `, `unmeasurable: ` or `generic: ` rule, a hit model left unmodelled, a mask spell beside named targets that are all unmodelled |
| `ambiguous_tooltip` | a sign opposite to the measured value, a proc of unstated trigger, disagreeing talent or passive readings, a named spell outside the class mask while a mask spell moves |
| `insufficient_trials` | a hit mean below `minimum_hits`, a proc rate below `trials_needed` (R9), a missing pass |
| `unmeasured` | a check after a failed single cast; a hit mean, proc rate or talent delta without usable hit (R11); a passive whose aura is absent after `learn`; damage against an aura state the scenario does not establish; a passive delta that cannot move (a multiplying relation on a before value of 0, a `stat` change below 1, `parry_chance` on a character that cannot parry) |
| `not_measured` | an `effect_value` read by `spell_effect_value` (`SpellEffectInfo::CalcValue`) of an effect that an aura script's `DoEffectCalcAmount` hook sets later (`<label> calc_amount_hooks` above 0): the read does not measure the applied amount, whatever it reads; not an alert, never conformant, listed in `report.md` (ADR 0118) |
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
  `$<name>` variables keep their sign; a measured value of the opposite sign is `ambiguous_tooltip`. A class
  file's `effect_overrides` entry with `base_points` replaces the record's points when a class contract rewrites
  them at load, so the sign follows the decision the server applies: Patience 712678 effect 1 is -5001 in
  `Spell.dbc`, the owner ruled on 2026-11-10 that "Increases ... its cooldown by $/1000;s2 sec" lengthens
  Interdict's cooldown, and `AscensionTemplarContracts.cpp` sets 4999, so the token's 5 sec expects +5000.
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
  (`SpellInfo.cpp:592`, a truncation). Each read must also lie in the range of the per-roll values (ADR 0145, owner
  ruling of 2026-11-11 on integer truncation): a read at most 1 below it, toward zero, is "known engine rounding,
  int32 truncation" only when it is the truncation of a per-roll value (`float32`, then toward zero), and
  `detail['engine_rounding']` lists those formula values (Force of Golganneth 500694: 388.25 read as 388); any other
  read outside the range, above it, further below, or one below that no value truncates to, is an `alert`, with one
  exception (ADR 0147, owner ruling "Per-level truncation", 2026-11-11): when the rolled effect has a fractional
  per-level term, the engine truncates `level x EffectRealPointsPerLevel` before the sum (`SpellInfo.cpp:497`, with
  stock's MaxLevel/BaseLevel clamp and `max(BaseLevel, SpellLevel)`). If every read is the int32 truncation of a
  per-roll value less that lost fraction, and the fraction changes the integer set the rolls give, the verdict is
  "known engine rounding, per-level term truncated before the sum", judged around the engine mean, and
  `detail['per_level_rounding']` holds the term, its truncation, the loss and the engine's integer range. The model
  has no effect-modifier factor and follows stock's level clamp, so it is used only when the run shows both hold:
  every value scenario reads, for an effect with a per-level term, `spell_modifier` on base 1000 for
  `SPELLMOD_ALL_EFFECTS` and the effect's own `SPELLMOD_EFFECTn` (`<label> effect_modifier all` and `e<n>`, the
  modifiers `Unit::ApplyEffectModifiers` applies), and the tooltip's own per-level part (the token read with and
  without the effect's `EffectRealPointsPerLevel`) must equal stock's `levels x rate`. A modifier other than 1000, a
  run without those reads, or a different per-level part leaves a read outside the range an `alert` labelled
  "per-level truncation, engine computation not modelled", never `ok`. Known limit: a CoA
  `ModifySpellEffectBaseValue` hook that multiplies the value (such as `ascension_scaling_base`,
  AscensionScalingBase.cpp:51) or changes the level is not detected; the tool cannot see it. That hook applies to
  the 454 `{spell, effect mask}` rows of `AscensionCompatData::ScalingBaseSpells`
  (`src/server/coa/AscensionScalingBaseData.h`): an ok verdict is exposed to it only when its spell is listed with
  that effect's bit; no Templar spell judged by this rule is listed. A rank whose tooltip
  leaves the per-level term out (the cancel list, ADR 0014) fails the per-level part check and never takes this
  rounding. Inherent limit: where the lost fraction exceeds the per-roll minimum's fraction, a flat 1-below server
  error gives exactly the engine's integer set and cannot be told apart from it. A fixed (`EffectDieSides` 0 or 1)
  `effect_value` with a fractional per-level term takes the same rule instead of the `max(1, 0.5%)` band: `ok` only
  when the read is the int32 truncation of the tooltip value or, under the same model checks, of that value less
  the lost fraction; otherwise an `alert`, labelled "not modelled" when a model check failed. A `hit_mean`,
  `melee_mean` or `periodic_total` alert on a rank with such a term says
  "per-level truncation, engine computation not modelled" and stays an alert. Fewer reads than the count the mean
  needs at the measured stats (`detail['reads_needed']`), or a mean of 0, give `measured`. A single read inside the
  roll range proves nothing about a constant offset smaller than the range: the fix round of the phase-2 Templar
  run found six such `ok` verdicts (Reckoning 572741, 748507, 805421; Vindication 501589, 501590, 501592), whose
  server value adds a per-level part the expected value omits. An `aura_amount` of a rolled effect has one read (one
  cast) and is therefore `measured` unless one read is enough. The Templar has rolled tokens on Righteous Upheaval,
  Vindication, Reckoning, Chastise, Benediction, Titanstrike and others (`EffectDieSides` 3 to 224).
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
  23) adds a `has_aura_state` measurement of that state on the dummy, taken after an `AURA_STATE_WAIT_MS` wait so
  `Unit::Update` has ticked (`passives.py`'s `aura_state_label`); when it reads 1 the delta is judged normally,
  when it reads 0 the check is `unmeasured: aura state <n> is not set on the dummy`, and when the measurement is
  absent (an older manifest, or a probe without this field) it keeps the original blanket reason. The tooltip is
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
  Deterministic stat readings (ADR 0135, owner ruling of 2026-11-11): for a metric of
  `compare.DETERMINISTIC_STAT_METRICS` (stats, armor, ratings, power, hit, crit, parry, dodge and block chances,
  expertise, attack time, weapon damage, resistances, mana regeneration, run speed) the margin is the metric's floor
  alone, the rounding of the reading (1 point, or 0.01 for the percent-point metrics and `weapon_damage_min`), with
  no 0.5% relative part and no `tolerated` tier: outside it the verdict is an alert. Blessed Padding 301311 armor
  +802 expected: +803 is `ok`, +805 and +834 are alerts. The same holds for the pre-truncation `stat_exact` reading
  (0.01) and for the readings of a `behaviour_group_stack_cap` on such a metric. Where the rounding cannot separate
  the stated value, `data_only` below keeps the clause data conformant.
  Percent-path stats (ADR 0141, owner ruling "Sturdy, no server change" of 2026-11-11): for a metric of
  `compare.PERCENT_PATH_METRICS` (`stat`, `armor`, `max_health`, `max_power`, `resistance`), the stats the engine
  reaches through its percent modifiers and truncates to an integer, the symmetric 1-point floor is replaced by the
  truncation: the delta must be the expected delta truncated (`compare.truncated`, +108 for +108.65), so one above is
  an alert (Blessed Padding +803 for +802). One below is `ok`, "known engine rounding", only on a `scale` relation
  where the float emulation reproduces the reading (`compare.engine_rounding_verdict`): the factor `AddPct` builds
  in float from 1 (`Util.h:52-60`), the float product with the before value, then the truncation
  (`Player::UpdateMaxPower`, `SetMaxPower(power, uint32(value))`). The verdict's `detail['engine_rounding']` holds the
  computed float value: Sturdy 681009 Energy 100 to 104 for +5% carries 104.99999237060547. It keeps `data_only` when
  a percent one point away emulates to the same reading (+4% also gives 104 from 100); else the reading tells the
  stated percent (120 to 125 for +5%: +4% gives 124, +6% 127). A one below the emulation does not reproduce (80 to 83
  for +5%, where the float gives 84), two or more away, a zero delta, combined effects and every other metric
  (damage, healing, durations, attack power) never take this rule.
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
  `scale`, `ratio`, `composition`, `crit_damage`) **on a named target, or on a non-modifier check (`named` is
  `None`)** — a mask-only collateral target (`named` is `False`) with that same structurally-always-zero before
  value instead falls through to the spell-modifier target rules above, so it reports `measured`/"reported, not
  judged" when a named sibling target is present, exactly like a `spell_modifier` check on the same ids (round 5:
  Final Prayer 705268's `spell_effect_value` on the Ascetic Abdication chain, whose own effect is
  `SPELL_EFFECT_PLAY_SOUND` and never reads the value a `SPELLMOD_EFFECT1` modifier that only incidentally also
  matches it changes — the quantity is always zero before and after on every build, not a measurement gap);
  `parry_chance` 0 before the learn (the reference character cannot
  parry, and a parry aura enables parry when applied, `AuraEffect::HandleAuraModParryPercent`) — a `parry_chance`
  probe's scenario primes `CanParry()` first (apply the rank's own aura once, then remove it, same pattern as
  `cultist-adaptive-combatant.json`), so this guard fires only when that priming itself was skipped; a `stat` delta
  below 1 (the server truncates stats to integers, `Unit::UpdateStats` `SetStat(stat, int32(value))`) unless a
  parallel `stat_exact` measurement (`Player::GetExactStatValue`, the pre-truncation float) is present, in which
  case the exact delta is judged against the same expected value with a tighter, `stat_exact`-only tolerance
  (`FRACTIONAL_FLOOR` 0.01) instead of the 1-point floor. Proof status (ADR 0124): a conformant verdict whose
  reading differs from the expected delta while the metric's floor is wider than the 5% band of that delta (`stat`
  +6 for an expected +6.6 at 132 Agility: the 1-point floor is 15% of it) carries `detail['data_only']` with the
  reason (`compare.floor_only_reason`), and so does a `stat_exact` verdict (the integer stat the game uses did not
  move); coverage counts both as data, not behaviour. An exact reading (+5 expertise for +5) keeps its evidence.
  Two judged effects
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
