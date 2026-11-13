# Conformance modules

## Modules

- `mitigation.py`: expected armor and partial-resist mitigation of a target.
- `classes.py`: `class_spells(dbc_dir, class_id, progression_header, level=60)` lists a CoA class's spells as
  `ClassSpell(spell_id, name, ranks, max_rank, required_level, passive)`; `class_skill_lines(dbc_dir, spells,
  weapon_subclass)` lists the `SkillLineAbility` lines of their ranks and of the weapon's skill spell.
- `tooltip.py`: `read_tooltip(dbc, spell_id, caster)` evaluates a spell's `Description[enUS]` with the caster's
  measured `CasterStats` and returns `Readout(values, unreadable)`; its `Records.field` prefers a streamed text.
- `streamed.py`: `streamed_texts()` replays the `coa_client_spell_description` rows of the world SQL updates and
  `streamed_field(spell, name)` gives the `Description[enUS]` or non-empty `ToolTip[enUS]` the server streams
  (ADR 0192).
- `profile.py`: the reference character of a class file and `base_steps(class_file)`, the steps every scenario starts
  with; `spell_dbc_sha256(dbc_dir)` hashes a set's `Spell.dbc` and `server_dbc_dir(dbc_dir)` /
  `require_server_sha(sha, source)` raise `DbcSetMismatch` for a set other than the server's (`load_class_file`
  applies it to a class file's `dbc_dir`). Its name shadows the standard library `profile`: run the package from its own directory.
- `values.py`: `value_scenario(class_file, spell, rank_id)` returns the no-combat scenario of one rank, its
  `Expectation` list, and the `periodic_totals` of any `OVER_TICKS` token deferred to a companion scenario (below).
- `passives.py`: `passive_effects(class_file, spell)` classifies each effect of a passive into a family, its expected
  token, its metric plans and, for a spell modifier, its targets (see [Passive effects](passive-effects.md#passive-effects));
  `passive_scenario(class_file, spell)` returns its with/without scenario, or `None` when no effect is measured, and
  its `Expectation` list (see [Passive scenario](passive-effects.md#passive-scenario)).
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
  and its `Expectation`; `delta_proc_scenario`/`delta_proc_plan` do the same for a `kind: "proc_rate_delta"` entry
  (see [Nested proc rate](proc-rates.md#nested-proc-rate-round-6-blade-sermon)); `proc_plan` sizes the parts, `trials_needed(p)` gives the trials a chance `p` needs and
  `wilson_interval(procs, trials)` the 99% Wilson interval of a rate.
- `triggers.py`: `trigger_scenario(class_file, entry, part)` returns one part of the scenario of a `triggers` entry and
  its `Expectation`; `trigger_plan` sizes the parts and `trigger_entries(class_file, auras)` selects the entries (see
  [Trigger entries](trigger-entries.md#trigger-entries)).
- `expiry.py`: `behaviour_expiry(class_file, entry)` and `trigger_expiry(class_file, entry)` return the expiry-pair
  scenario of a duration entry and its `behaviour_expiry` expectation (or `None` for another kind); `margins_of`
  places the readings and `expiry_readings` judges each arm from the recorded step timing (see
  [Expiry pairs](behaviour-scenarios.md#expiry-pairs-behaviour_expiry)).
- `compare.py`: `compare(manifest, results_dir, build=None)` judges a run against the manifest and returns
  `Verdict(label, status, measured, expected, low, high, explanation, ..., server_commit, build, runs)`; `evaluate`
  returns the `Comparison` with the judged `Build` and the runs refused as `other_build` (`BuildMismatch` when the
  results hold several builds and none is named); `write_outputs` writes `alerts.tsv`, `report.md`, `verdicts.json`
  and `questions.md`.
- `prove.py`: `prove(spec, generate, rows, enrich, annotate, runner, compare, pilot)` runs the gameplay passes of a
  generated selection at least twice through `coa-verify`, compares each run, reports flips and unjudged verdicts,
  and writes `fragment.json` and `summary.json` (see [Prove runner](generate-and-compare.md#prove-runner));
  `prove_ledger.py` supplies the ledger rows, their per-run evidence and the coverage per run; `pilot.py`
  (`hit_ratio_pilot`) runs the hit-ratio entries at 20 trials first and sizes the judged runs from their verdicts.
- `mutants.py`: `load_mutants(path)` reads `{label, spell, op, factor}` server mutants (factor 2 or 0), `mutate(manifest,
  mutants)` adds the `spell_mod_mutant` step after the `settle` wait and an active-mutant assert at the end of every
  scenario carrying a mutant label, and `contamination(baseline, mutant, mutated)` lists the unmutated verdicts whose
  status class changed; `k3.py`: `k3_rows(probes, mutants, baseline, mutant, evidence)` judges K3 consumption probes
  into `consumed`/`not_consumed` rows (`literal_modifier_sites` refuses a spell whose modifier channel CoA code feeds
  with its own amount) and `merge_consumption(path, rows)` writes `classes/<class>_consumption.json` (see
  [Server mutants and K3 consumption](generate-and-compare.md#server-mutants-and-k3-consumption)).
- `sample.py`: `sample_document(clauses, seed, total, buckets, minimums, first_size)` draws a batch sample of whole
  spells from a bucket file (`spell_order` by sha256 of `<seed>|<spell id>`, `bucket_quotas` proportional with
  floors) and splits it into two chunks (`chunk_split`) (see
  [Drawing a batch sample](generate-and-compare.md#drawing-a-batch-sample)).
- `packets.py`: `write_packets(dbc_dir, class_file, sample, chunk, bucket_rows, out_dir, class_map)` writes one
  Markdown packet per spell of a sample chunk (`packet`, `render_packet`) (see
  [Per-spell packets](generate-and-compare.md#per-spell-packets)).
- `class_map.py`: the command line `--worktree W --out OUT [--dbc-dir DIR] [--log-events EVENTS.csv]` maps every
  spell of the 21 CoA classes to the code that touches it (`risk`, `gap`, `custom_mechanics`, log counts) and writes
  `class-map.json` and `class-map-table.md`, the input of `packets --class-map` (see [Class map](class-map.md)).
- `bonus.py`: the owner's band on a percent bonus (`bonus_band`, the larger of 5% of it and 2 points), the bonus of
  two arms with its 99% Welch half-width (`per_event_sample`, `bonus_of`), the status with power and negative arm
  (`bonus_status`), the trials a band needs (`sized_trials`) and the interval a verdict excludes (`excluded_text`)
  (see [Hit-ratio scenarios](behaviour-scenarios.md#hit-ratio-scenarios-behaviour_hit_ratio-kind-hit_ratio)).
- `questions.py`: `questions(verdicts, tooltips)` turns the verdicts that carry a question into one `Question(tooltip,
  spells, kind, question, readings, measured, labels, conditions, observations)` per tooltip and kind, and
  `write_questions(items, out_dir)`
  writes `questions.md` (see [Open conformance checks](generate-and-compare.md#open-conformance-checks)).
- `diff.py`: `diff(before, after, intended)` returns the `Change` of every verdict that moved between two compare
  outputs, and `write_impact` writes `impact.md` (see [Impact report](generate-and-compare.md#impact-report)).
- `stack.py`: `stack_scenarios(class_file, passes=5)` returns the passes of every cumulative talent configuration of
  the class file with their `Expectation` lists; `levers(verdicts)` turns the stack verdicts into one `Lever(config,
  dps_mean, dps_low, dps_high, delta_pct, sources, tooltip_delta_pct)` per configuration; `mean_interval`,
  `ratio_interval` and `student_t_quantile` give the 99% intervals of the passes.
- `coverage.py`: `coverage(header, verdicts)` counts the verdicts per status and the class spells, passives and actives
  that a compare output judges (`Coverage`), and `write_coverage` writes `coverage.md` for two outputs (see
  [Coverage comparison](generate-and-compare.md#coverage-comparison)); `clause_coverage(clauses, verdicts, build,
  consumption)` returns the `ClauseCoverage` of a clause ledger with the behaviour-proven and data-conformant counts
  from the closed `EVIDENCE` and `METRIC_EVIDENCE` tables, the `not_measured` labels and the readbacks a K3
  consumption row of that build promotes or shows not consumed (`load_consumption`, `acting`); `require_build` refuses verdicts of
  another build than the one judged; `clause_claims` and `require_claims` read and check an entry's declared claims
  (a clause is closed only when every one is proven, `ClauseCoverage.claim_evidence`); `fragment_entries`,
  `write_fragment` and `read_fragment` write and check ledger fragments that carry the computed evidence and the
  `Spell.dbc` sha256, one row per claim for a clause not fully proven (see
  [Two proof statuses](clause-ledger.md#two-proof-statuses) and [Stated claims](clause-ledger.md#stated-claims)).
- `observations.py`: `player_observations(class_file)` reads and validates a class file's `player_observations`
  array (see [Player observations](player-observations.md#player-observations)) and `observations_by_spell` groups them by spell id.
- `conformance.py`: the command line, `generate`, `compare`, `diff` and `coverage`.
- `classes/<name>.json`: one class file per class (`classes/templar.json`).
