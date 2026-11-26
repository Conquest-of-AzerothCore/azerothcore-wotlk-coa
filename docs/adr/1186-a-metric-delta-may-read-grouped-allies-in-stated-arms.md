# 1186. A metric delta may read grouped allies in stated arms

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-22
- Builds on: ADR 0582

## Context

Six Sun Cleric claims state what an ally receives: Bless 804247 "Bless yourself and an ally", Pious 300943 and
680656 "grant allies Replenishment", Mercy 504848 "an ally and up to 5 nearby allies", Holy Form 805301 "healing your
ally affected by Bless" and Heat Wave 534267 "heals up to 5 of the target's lowest health nearby allies". A
`metric_delta` scenario has one player, so `measure_actor: "ally"` failed `run.py validate` ("unknown actor"), a
caster read cannot stand beside an ally read in one scenario, and an uncast before phase reads at once, so a periodic
effect has no control read at the treatment's time. The harness already reads `health`, `power` and `aura` on any
player fixture, and other kinds (`party_stat_ratio`, `hit_ratio`, `internal_cooldown_gate`) already add grouped ally
players (code reading only for the reads on an ally in a `metric_delta` scenario; no run yet). Its heal and energize
totals (`CoAGameplayTest.cpp` `spell_heal_*`, `spell_energize_*`) count only the events the read unit itself, its
pet or (for a heal) a `caster_entry` creature cast, so on an ally they count the ally's casts, not the caster's.
Its `cast` step is fire-and-forget: nothing records that a cast at the ally went off.

## Options

1. Core fields in `MetricDeltaSpec` and `metric_delta_scenario` (an ally list, a second read, a control wait).
2. One opt-in option module, `ally_arm`, through the named points of ADR 0582.

## Decision

Option 2 (mentor D-48, controller design approval). `metric_delta_options/ally_arm.py`, `ORDER` 24:

- `allies` (1 to 5): grouped ally players `ally`, `ally2` .. `ally5` with the class's player fixture, regeneration off
  when the entry sets `disable_regeneration`, grouped right after the base steps. `measure_actor`, `target` and
  `fields.target` may then name them.
- `ally_health` `[value, maximum]` and `ally_casts` (spells the caster casts at `ally`, each followed by 2000 ms for
  the global cooldown) in both phases, through `phase_steps`, ahead of the trigger.
- An ally cast is proved, not assumed: the spell must be in the entry's `learn` and cast nowhere else in the scenario
  (not the trigger, not a setup cast), its cast time must fit the settle (at most 1500 ms), and `attack_swings` (no
  cast phase) is refused. Each cast gets the setup-cast preparation (flat power cost, required caster aura,
  reagents), and an `assert` on the caster's `spell_go_count` of the spell at its running total follows each settle,
  so a cast that did not go off fails the scenario and a missing fixture never passes a "does not" or 0 expectation.
- `control_wait`: the uncast before phase waits the entry's `wait_ms` before its reading, so the control is read at
  the treatment's time. Only with `cast_in_before` false and the default gate timing, and without the after-phase-only
  acts (`setup_wait_ms` with setup casts, enemy, helper and target casts). At load the waits from the ally fixture to
  each reading are compared and any difference, such as another option's waits after the trigger, is refused.
- Heal and energize totals, and the spell damage, log, go, cast and proc counts, on a unit other than the caster are
  refused (unless a heal names `caster_entry`; re-review N-1): a heal
  the caster gives an ally is read on the caster with `fields.target` naming that ally. The harness read is not
  changed.
- `arms`: extra reads, each summed over its `actors`, placed right after the main before and after readings. Every
  arm states `before_expected`, `expected`, `tolerance` and its `source`; an arm without one is refused at load, and
  there is no default tolerance (a random value such as a heal takes the G-19 band from its data). The arm's metric
  needs a `METRIC_EVIDENCE` row that is not a readback.
- Verdict: the main verdict is judged as before; an arm off its expectation turns it to alert, a missing arm read to
  unmeasured unless the main verdict already alerts. The evidence class stays the main metric's; an arm does not pass
  through the clause gates, so a class reviewer checks an arm that proves a ledger row. Without arms the verdict is
  the plain one.

## Amendment (mentor D-56, D-57)

Three Sun Cleric claims hit the option's limits. Bless 804247 cast at an ally makes the script cast Bless on the
caster too (`AscensionSunClericAuras.cpp` `Cast(player,player,Bless)` when the target is not the caster), so the
caster sees two 804247 SPELL_GO per ally cast and the one-per-cast assertion failed 707517 although the cast went off.
Mercy 504848 ("an ally and up to 5 nearby allies") and Heat Wave 534267 ("up to 5 of the target's lowest health
nearby allies") need at least seven grouped players to read a cap of five. Heat Wave's copy heals 75% of a rolled
heal, which one arm's absolute band cannot state.

- `ally_casts` items may be `{spell, spell_go_per_cast, source}`: an integer of at least 2 and the code or data line
  that casts the extra SPELL_GO, never an observed count. The landed assertion stays `equals` at the casts so far
  times that count, so a wrong count fails the scenario in either direction and cannot pass a 0 or "does not"
  expectation. The plain spell id keeps one per cast. On each use, the reviewer opens the cited lines and checks that
  they say what `source` claims. The harness `spell_go_count` has no target filter, so a target-scoped count would
  need a harness edit; this does not.
- `allies` goes to 7 (`ally6`, `ally7`): with the caster, the schema 1 cap of 8 players (`run.py` `MAX_PLAYERS`,
  `CoAGameplayTest.cpp` `MaximumPlayers`); schema 2 would take 25 but changes the scenario's schema and timeout cap,
  so it is left out. The harness converts the group to a raid when the party is full, so from `ally5` on the allies
  stand in raid subgroup 2 (code reading only).
- `ratios`: `{numerator, denominator, expected > 0, tolerance, source}` over two arm indices, judged on the arms'
  after-less-before deltas. A denominator that did not move is off. The arms keep their absolute expectations, and
  without `ratios` the model and the verdict are unchanged.
- Not built: a per-ally health for the lowest-health order of Heat Wave (`ally_health` sets one value on every ally).
- The amendment leaves the finished classes byte-identical: `generate --class 19`, `19 --stack`, `23` and `15`
  at base 80dc5ff714 and at head, compared by `diff -r`.

## Amendment (mentor D-56, review I-1)

From `ally5` on, the allies stand in raid subgroup 2 (`CoAGameplayTest.cpp` `action == "group"`, `Group::AddMember`),
and a spell whose targets are checked by `TARGET_CHECK_PARTY` needs `IsInPartyWith`
(`WorldObjectSpellTargetCheck::operator()`), the same subgroup in a raid. Such a spell reads 0 on `ally5`..`ally7`, so
a cap of five or a 0 ("does not affect") read there would hold on a party-scoped implementation for the wrong cause.

- Options considered: a review duty in the docs only; refusing any read on `ally5`..`ally7`, which would also refuse
  the raid-wide Mercy and Heat Wave reads the amendment above built `allies: 7` for; requiring a stated
  `reach_source` on each such read. The option cannot see a script's target filter, so it cannot prove the reach by
  itself.
- Decision: the main reading and the trigger's cast target (through the option's `reach_source`) and each arm
  (through its own `reach_source`) whose units, `actors` or `measure_actor`, the cast `target` and `fields.target`,
  include `ally5`, `ally6` or `ally7` must state the
  code or data line that makes the spell reach raid subgroup 2, or it is refused at load; a `reach_source` on a read
  without such a unit is refused too. A ratio reads two arms and rests on theirs. The contract states each
  `reach_source`; the model does not carry it, so the verdict is unchanged.
- Per-use review duty: the reviewer opens the cited lines and checks that the spell's whole target selection (DBC
  implicit targets and every script filter) reaches the raid, not only the party (`TARGET_CHECK_PARTY`,
  `IsInPartyWith`, `GetPartyMembers`).
- Finished classes stay byte-identical: no finished class uses `ally_arm`.

## Consequences

- No new metric, no core or harness edit. Finished classes regenerate byte-identical (Witch Hunter, class 15, checked
  by `diff -r` at base and head; the other finished classes by the source stage's snapshot guard).
- The reads on an ally rest on code reading until a class author runs the exploratory probe of the T2 report in game.
- An ally cast's percentage or per-level power cost is not set by the option: the caster's power at that point pays
  it, and the `spell_go_count` assertion fails the scenario when it cannot.
- A random arm value whose band differs between phases cannot be stated: one `tolerance` serves both phases.
