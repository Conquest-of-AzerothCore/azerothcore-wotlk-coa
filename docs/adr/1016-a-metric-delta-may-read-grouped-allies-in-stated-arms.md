# 1016. A metric delta may read grouped allies in stated arms

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

## Consequences

- No new metric, no core or harness edit. Finished classes regenerate byte-identical (Witch Hunter, class 15, checked
  by `diff -r` at base and head; the other finished classes by the source stage's snapshot guard).
- The reads on an ally rest on code reading until a class author runs the exploratory probe of the T2 report in game.
- An ally cast's percentage or per-level power cost is not set by the option: the caster's power at that point pays
  it, and the `spell_go_count` assertion fails the scenario when it cannot.
- A random arm value whose band differs between phases cannot be stated: one `tolerance` serves both phases.
