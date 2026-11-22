# Ally arm (`metric_delta` `ally_arm`, ADR 1016)

`ally_arm` is an object of these keys, at least one:

- `allies`: 1 to 7 (default 1). Grouped ally players `ally`, `ally2` .. `ally7` (the class's player fixture,
  regeneration off with `disable_regeneration`), grouped right after the base steps. `measure_actor`, `target` and
  `fields.target` may name them. The harness `group` step converts a full party to a raid
  (`CoAGameplayTest.cpp` `action == "group"`), and a raid member joins the first subgroup with fewer than five
  (`Group::AddMember`): from `ally5` on, the allies stand in raid subgroup 2, outside the caster's party (code
  reading only). Seven allies and the caster fill the scenario schema 1 cap of 8 players (`run.py` `MAX_PLAYERS`),
  so a scenario that adds another player, such as an enemy player, is refused at validation.
- `ally_health`: `[value, maximum]`, set on every ally in both phases, ahead of the trigger.
- `ally_casts`: spells the caster casts at `ally` in both phases ahead of the trigger, 2000 ms after each (global
  cooldown). Each spell must be in the entry's `learn` and must not be its trigger or a setup cast; a cast time above
  1500 ms (the settle less the 500 ms cast margin) and `attack_swings` are refused. Before each cast the option sets
  the spell's flat power cost, its required caster aura and its reagents, as for a setup cast (a percentage or
  per-level cost is paid by the caster's power at that point). After each settle an `assert` reads the caster's
  `spell_go_count` of the spell at its running total, so the scenario fails when an ally cast did not go off.
  An item is a spell id (one SPELL_GO per cast) or `{spell, spell_go_per_cast, source}` for a cast that also makes
  the caster cast the same spell: `spell_go_per_cast` is an integer of at least 2 and `source` cites the code or data
  line that casts the extra SPELL_GO (never a run's count). The running total is then the casts so far times that
  count, still asserted with `equals`, so a count too high or too low fails the scenario as a cast that did not go
  off does. Every item of one spell states the same count and source. On each use, the reviewer opens the cited
  lines and checks that they say what `source` claims (mentor D-57).
- `control_wait`: `true`. The uncast before phase waits the entry's `wait_ms` before its reading (timed no-cast
  control). Only with `cast_in_before` false, the default gate timing and no strike, swings, `setup_only_after`,
  `setup_in_before`, `target_casts_before` or `enemy_casts_in_before`; and, since the before phase has no trigger,
  without the after-phase-only acts: no `setup_wait_ms` with setup casts, no `enemy_casts`, `helper_casts` or
  `target_casts`. At load the waits from the ally fixture to each reading are compared (the treatment's less the
  option phase steps' own waits); any other difference, such as another option's waits after the trigger, is
  refused.
- `ratios`: a non-empty list of `{numerator, denominator, expected, tolerance, source}`, two distinct arm indices.
  Each arm reads as its after sum less its before sum, and the ratio `numerator / denominator` is judged
  `|ratio - expected| <= tolerance`; `expected` is above 0 and stated with its `source`. A denominator arm that did not
  move makes the ratio off, never ok. Each arm keeps its own absolute expectation.
- `arms`: a list of `{actors, metric, fields?, before_expected, expected, tolerance, source}`. Each arm reads `metric`
  on every unit of `actors` (the caster, the allies, the dummy when the scenario has it) with the arm's `fields`,
  right after the main before and after readings, and judges the sums: `|sum - expected| <= tolerance`. Every value
  is a finite number stated with its `source`; no default tolerance. The metric needs a `METRIC_EVIDENCE` row that is
  not a readback.

Heal and energize totals (`spell_heal_count`, `spell_heal_total`, `spell_effective_heal_total`,
`spell_energize_count`, `spell_energize_total`), and the spell damage, log and count reads (`spell_damage_count`,
`spell_damage_total`, `spell_log_count`, `spell_absorb_total`, `spell_resist_total`, `spell_go_count`,
`spell_cast_count`, `spell_proc_count`) count only the events the read unit itself (or its pet) cast; a
heal also takes `caster_entry` for a creature caster. Read on an ally they would count the ally's own casts, so an
arm or the main reading with one of them on a unit other than the caster is refused, unless a heal names
`caster_entry`. Read a heal the caster gives an ally on the caster with `fields.target` set to that ally, one arm per
ally.

Verdict: the main verdict, then alert when an arm or a ratio is off; a missing arm read makes it unmeasured, or keeps an
alert the main verdict already gives. Without arms the verdict is the plain one. One `tolerance` serves both phases, so
a random value whose band differs between phases (G-19) cannot be stated in one arm. The evidence class stays the main
metric's: an arm does not pass through the clause gates (`CONTRAST_PROOF`, `STATE_PROMISES`, `EVENT_PROMISES`), so a
ledger row an arm proves needs its arm checked against the clause by the class reviewer.

Named points: `check`, `phase_steps`, `fixtures`, `model`, `verdict`.

Example shape (Bless at an ally; every value comes from the entry's own source, never from this page):

```json
"target": "ally", "measure_actor": "ally", "cast_in_before": false, "disable_regeneration": true,
"metric": "health", "before_expected": "<ally health set below>", "expected": "<from the DBC>",
"wait_ms": "<from the DBC>",
"ally_arm": {"allies": 2, "ally_health": ["<value>", "<maximum>"], "control_wait": true, "arms": [
  {"actors": ["ally"], "metric": "aura", "fields": {"spell": 804247}, "before_expected": 0, "expected": 1,
   "tolerance": 0, "source": "Bless cast at the ally holds its aura there"}]}
```
