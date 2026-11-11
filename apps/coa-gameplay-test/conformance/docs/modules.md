# Conformance modules

## Modules

- `mitigation.py`: expected armor and partial-resist mitigation of a target.
- `classes.py`: `class_spells(dbc_dir, class_id, progression_header, level=60)` lists a CoA class's spells as
  `ClassSpell(spell_id, name, ranks, max_rank, required_level, passive)`; `class_skill_lines(dbc_dir, spells,
  weapon_subclass)` lists the `SkillLineAbility` lines of their ranks and of the weapon's skill spell.
- `tooltip.py`: `read_tooltip(dbc, spell_id, caster)` evaluates a spell's `Description[enUS]` with the caster's
  measured `CasterStats` and returns `Readout(values, unreadable)`.
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
- `compare.py`: `compare(manifest, results_dir, build=None)` judges a run against the manifest and returns
  `Verdict(label, status, measured, expected, low, high, explanation, ..., server_commit, build, runs)`; `evaluate`
  returns the `Comparison` with the judged `Build` and the runs refused as `other_build` (`BuildMismatch` when the
  results hold several builds and none is named); `write_outputs` writes `alerts.tsv`, `report.md`, `verdicts.json`
  and `questions.md`.
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
  [Coverage comparison](generate-and-compare.md#coverage-comparison)).
- `observations.py`: `player_observations(class_file)` reads and validates a class file's `player_observations`
  array (see [Player observations](player-observations.md#player-observations)) and `observations_by_spell` groups them by spell id.
- `conformance.py`: the command line, `generate`, `compare`, `diff` and `coverage`.
- `classes/<name>.json`: one class file per class (`classes/templar.json`).

