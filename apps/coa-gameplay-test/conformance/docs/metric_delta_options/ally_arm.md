# Ally arm (`metric_delta` `ally_arm`, ADR 1186, ADR 1199, ADR 1214, ADR 1215, ADR 1244, ADR 1281)

`ally_arm` is an object of these keys, at least one:

- `allies`: 1 to 9 (default 1). Grouped ally players `ally`, `ally2` .. `ally9` (the class's player fixture,
  regeneration off with `disable_regeneration`), grouped right after the base steps. `measure_actor`, `target` and
  `fields.target` may name them. The harness `group` step converts a full party to a raid
  (`CoAGameplayTest.cpp` `action == "group"`), and a raid member joins the first subgroup with fewer than five
  (`Group::AddMember`): from `ally5` on, the allies stand in raid subgroup 2, outside the caster's party (code
  reading only), where a party-scoped spell (`TARGET_CHECK_PARTY`, `IsInPartyWith`, `GetPartyMembers`) reads 0.
  Up to seven allies and the caster keep scenario schema 1 (cap 8 players, `run.py` `MAX_PLAYERS`); eight or nine
  allies switch the scenario to schema 2 (cap 25, `CoAGameplayTest.cpp` `MaximumPlayers`) and the contract says so
  (ADR 1281), so an entry of seven allies or fewer generates as before. With schema 1, a scenario that adds another
  player to seven allies, such as an enemy player, is refused at validation.
- `ally_class` (ADR 1209): a CoA class, 12 to 32, needing at least one ally. The allies are created with that class
  instead of the class under test (the scenario schema's per-player `class`, created by the existing character
  creation), for a spell that lands only on a power type the class under test lacks. The entry states the power type it
  needs with a precondition arm on the state metric `active_power` (`fields.power`), read on the ally, so a wrong class
  voids the trial.
- `reach_source`: text, required on the option when the main reading's `measure_actor` or `fields.target`, or the
  trigger's cast `target`, is `ally5` to `ally9`, and refused otherwise. It cites the code or data line that
  makes the spell reach raid subgroup 2 (for example a script filter by `IsInRaidWith`, or a DBC implicit target checked
  by `TARGET_CHECK_ALLY`), never a run's reading. The contract states it. On each use, the reviewer opens the cited
  lines and checks that the spell's whole target selection (DBC implicit targets and every script filter) reaches the
  raid, not only the party (mentor D-56).
- `ally_health`: `[value, maximum]`, set on every ally in both phases, ahead of the trigger.
- `ally_power` (ADR 1244, provisional): a non-empty list of `[power, value]`, a power index 0 to 6 once each and a
  value of at least 0, needing at least one ally. Each phase sets every ally's listed power to its value with the
  harness `set_power` step, right after `ally_health` and ahead of the trigger (the harness refuses a value above the
  maximum). Read the pool with a judged `power` arm on the ally, not a precondition, so a pool that did not move
  alerts.
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
- `ally_attacks` (ADR 1214, provisional): a non-empty list of `{spell, power, source}`. `ally` learns each spell
  (right after the group steps) and casts it at the dummy after the trigger, after the option's other after-trigger
  steps; in an uncast before phase (`cast_in_before` false or `trigger_only_after`) at the end of the phase steps, so
  both phases carry the attacks. Before each cast the ally's mana (power 0) is set to `power` and the spell's cooldown
  reset; after a 2000 ms settle an `assert` reads the ally's own `spell_go_count` of the spell at its running total,
  so the scenario fails when an attack did not go off. Only with the dummy in the scenario (`select_dummy` or a read
  of it), the default gate timing, no `setup_only_after` and no `control_wait`. An arm or the main reading may then
  read a caster-scoped metric (`spell_damage_total`, `spell_damage_count`, ...) on `ally` when its `fields.spell` is
  one of these attacks: the ally's own casts are the events meant. Every other caster-scoped read on an ally stays
  refused.
- `ally_strikes` (ADR 1215, provisional): `true`, on an entry with a `strike` that has `after_trigger_ms`, no
  `owned_entry` and no `dx`. After the trigger and the caster's strikes (at the start of the phase steps in an uncast
  before phase), each ally is set to the strike's `health` (or to N when written `ally_strikes: {"health": N}`, which
  changes the allies only, N at most `max_health`) of `max_health` and struck `count` times by the striker's
  spell, `wait_ms` apart. Around each ally's strikes the caster reads the striker's `spell_go_count` of the spell
  (`caster: striker`); a count that did not grow by `count`, or a missing read, makes the verdict `unmeasured` (the
  trial is void), before any other judgement. Not with `control_wait`. The harness creature cast takes any unit id as
  its target (`CoAGameplayTest.cpp` creature `cast`, code reading only).
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
  move makes the ratio off, never ok. Each arm keeps its own absolute expectation. `denominator` may instead be a
  list of two or more arm indices (without the numerator) whose deltas are summed; each listed arm is a ratio-only
  arm. An optional `floor_count` names an arm that counts the events whose amounts are truncated to an integer one by
  one (a ratio-only arm gives its count, another arm its delta): the low end of the band widens by that count over the
  denominator, one unit per event, the high end does not move; `tolerance` must stay below 10% of `expected`, and a
  widened low end at or below 90% of `expected` makes the ratio unmeasured, never ok (ADR 1198).
- `allies: 0` (from 0 to 9, default 1) adds no ally player and no group step, for arms on the caster or the dummy
  only; it needs arms and refuses `ally_health` and `ally_casts`.
- `arms`: a list of `{actors, metric, fields?, before_expected, expected, tolerance, source, reach_source?,
  precondition?}`. Each
  arm reads `metric` on every unit of `actors` (the caster, the allies, the dummy when the scenario has it) with the
  arm's `fields`, right after the main before and after readings, and judges the sums:
  `|sum - expected| <= tolerance`. Every value is a finite number stated with its `source`; no default tolerance. The
  metric needs a `METRIC_EVIDENCE` row that is not a readback. An arm whose `actors` or `fields.target` name `ally5`
  to `ally9` states its own `reach_source`, as the option's main reading does, with the same review duty; on
  any other arm it is refused. A ratio reads two arms, so a ratio over such an arm rests on that arm's
  `reach_source`.
- A ratio-only arm `{actors, metric, count_metric, fields?, source, reach_source?}` omits `before_expected`,
  `expected` and `tolerance` together, for totals no data states (a heal or damage amount). It reads `count_metric`
  with the same fields beside `metric`, is judged only through the ratios that name it (an arm no ratio names is
  refused), and any ratio over it is unmeasured unless its count moved, or when its denominator did not move.
- `precondition: true` on an arm (ADR 1199, mentor D-169): the arm states a premise of the trial, never behaviour.
  Its metric must be a state metric; `combat_reach` (`METRIC_EVIDENCE` row `state` declared by this option, the
  harness `GetCombatReach()` read) is accepted only on such an arm. A precondition arm is never ratio-only, and no
  ratio names it as numerator, in a denominator or list, or as `floor_count` (ADR 1198, ADR 1199). Any other value
  than `true` is refused; the key is written to the model and the contract only when set.

Heal and energize totals (`spell_heal_count`, `spell_heal_total`, `spell_effective_heal_total`,
`spell_energize_count`, `spell_energize_total`), and the spell damage, log and count reads (`spell_damage_count`,
`spell_damage_total`, `spell_log_count`, `spell_absorb_total`, `spell_resist_total`, `spell_go_count`,
`spell_cast_count`, `spell_proc_count`) count only the events the read unit itself (or its pet) cast; a
heal also takes `caster_entry` for a creature caster. Read on an ally they would count the ally's own casts, so an
arm or the main reading with one of them on a unit other than the caster is refused, unless a heal names
`caster_entry`. Read a heal the caster gives an ally on the caster with `fields.target` set to that ally, one arm per
ally.

Verdict: first the precondition arms: one off or unread makes the verdict unmeasured (the trial is void, not
judged), whatever the main verdict and the other arms say; held, they leave the status as is. Then the main verdict,
then alert when an arm or a ratio is off; a missing arm read makes it unmeasured, or keeps an
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
