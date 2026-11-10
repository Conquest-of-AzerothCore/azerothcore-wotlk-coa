# 0066. A `magnitude_ratio` trigger kind measures a proc's magnitude against its own trigger hit

- Status: accepted
- Date: 2026-11-09

## Context

`round10/proc-chains` found a repeated shape among the Templar's triggered-spell clauses: a tooltip of the form
"now deals/heals X% of the damage dealt", where one landed hit casts a second, distinct spell whose own amount
is a fixed fraction of that specific hit's (variable, crit-dependent) damage — Deliverance 704116 ("Critically
striking with Vindication or Righteous Lunge now deals $s1% additional Physical damage") and Uther's Legacy
706385 ("Your Condemn now heals you for $s1% of the damage dealt"). Both auras use the same CoA-scripted
`EffectApplyAuraName` 354 (`SPELL_AURA_ASCENSION_PROC_PERCENT_EVENT`), confirming the mechanism reads a
percentage of the triggering event's own amount, not a flat `EffectBasePoints`.

The existing `triggers.py` entries for both auras already prove the "fires at all" half with a plain
`trigger_count` check (`704116 trigger_count`, `706385 trigger_count`, both previously `ok`). Neither proves the
magnitude half: `trigger_count` only sums occurrences, and the existing `effect_value` check on each copy
spell's own `EffectBasePoints` token only cross-checks the tooltip's displayed number against the DBC, never
against a measured in-game hit. No existing kind (`cooldown_delta`, `duration_delta`) reads two spells' own
damage/heal totals and compares them.

## Considered options

1. Leave the magnitude half `unmodelled`, alongside the already-`ok` `trigger_count` entry. Rejected: the
   mechanism is reachable, deterministic given a hit's damage, and the fraction is a real, checkable DBC number
   (`$s1`); "the harness cannot" is not an accepted outcome for a buildable scenario (AGENTS.md, this workstream's
   own charge).
2. A per-trial before/after read of a shared accumulator, mirroring `cooldown_trigger_scenario`'s before/after
   pair. Rejected: there is no single accumulator to read before and after one trigger cast the way a cooldown
   or a duration can be — the quantity of interest is two different spells' own damage, and C++ already exposes
   `spell_damage_total`/`spell_heal_total` as *cumulative* sums filtered by spell id, so a per-trial read would
   have to subtract consecutive cumulative reads for no benefit over reading the grand totals once at the end.
3. Read the trigger spell's own damage total and the triggered spell's own damage/heal total, each summed over
   many repeated casts, and take the ratio of the two sums once per part, summed again across parts. Chosen: no
   new C++ metric is needed (`spell_damage_total`/`spell_heal_total`/`spell_damage_count` already exist,
   `CoAGameplayTest.cpp:4513,4582`); because the server computes the triggered amount as a deterministic,
   per-event function of that same hit's own damage (only the integer truncation varies), the ratio of sums
   converges on the tooltip fraction far faster than any per-hit statistic would, so the existing
   `TRIGGER_TRIALS` sample floor (sized for `trigger_count`'s own false-negative risk, unrelated to this
   convergence) is already more than enough trials for a tight tolerance band.

## Decision

- `triggers.py` gains `MAGNITUDE_RATIO_KIND = 'magnitude_ratio'` and `MAGNITUDE_CHECK = 'trigger_magnitude_ratio'`.
  `checked_entry` branches to a new `checked_magnitude_entry` for `entry.get('kind') == MAGNITUDE_RATIO_KIND`
  before touching the standard shape's required fields; the standard and `cooldown_delta`/`duration_delta`
  branches are otherwise untouched. `checked_magnitude_entry` requires `trigger['action'] == 'cast'`, a target in
  the usual `TRIGGER_TARGETS`, `trigger_metric` one of `{'spell_damage_total'}`, `observe_metric` one of
  `{'spell_damage_total', 'spell_heal_total'}` and a positive `expected_ratio`.
- `attempt_interval` needs no new branch: the fallback computation it already runs for every cast-action, kind-
  less entry (`cast_interval` of the trigger spell) is exactly what this kind needs too, since it casts only the
  trigger spell in a loop and never an extra observed-rank cast the way `cooldown_delta`/`duration_delta` do.
- A new `magnitude_ratio_scenario(class_file, entry, part)` reuses `trigger_plan` unchanged (so scheduling and
  part-splitting match every other kind) but drops the baseline part entirely: the trigger spell deals its own
  damage/heal regardless of whether the passive is learned, so a zero-passive control proves nothing about the
  *ratio*, only about presence, which the sibling `trigger_count` entry on the same aura already covers. It
  learns the trigger spell and the passive together, repeats the trigger cast across the part's attempts, then
  reads four cumulative totals once at the end: the trigger spell's `trigger_metric` total, its
  `spell_damage_count` (the trial count), the triggered spell's `observe_metric` total, and the aura's own
  presence. `conformance.py`'s `add_trigger` dispatches to this function instead of `trigger_scenario` when
  `entry.get('kind')` is this kind; it is otherwise unchanged.
- `compare.py` gains `judge_trigger_magnitude`, dispatched (by `expectation.check`) alongside `judge_trigger`
  from the same `trigger_parts` grouping. It sums each part's four totals, then takes `ratio = observe_total /
  trigger_total` once over the grand sums: the ratio must fall within `max(0.01, 5% of expected_ratio)` of
  `expected_ratio` (the owner's own "within 5% on numbers" standard; `MAGNITUDE_RATIO_TOLERANCE`/
  `MAGNITUDE_RATIO_FLOOR`) or the whole check is an `alert`. Fewer than `TRIGGER_TRIALS` summed trigger-spell
  hits is `insufficient_trials`; no usable part at all (the passive never learned anywhere, or every run
  unmeasured) is `unmeasured`.
- A class-file entry sharing an `aura` with the existing `trigger_count` entry for the same clause disambiguates
  its generated scenario key with the existing optional `effect` field (unchanged mechanism from ADR 0033); the
  plain entry keeps no `effect` field so its own key is unchanged.

## Consequences

- Deliverance 704116 and Uther's Legacy 706385 each gain a `trigger_magnitude_ratio` check proving the
  proportionality their tooltips literally claim, alongside their existing (unchanged) `trigger_count` checks.
- `test_triggers.py` gains direct unit coverage of `checked_magnitude_entry`, `magnitude_ratio_scenario`'s
  generated steps, and a `compare.py` suite (`MagnitudeTriggerCompareTest`) proving the in-tolerance, far-from-
  tolerance (a seeded wrong value), absent-passive, insufficient-trials and multi-part-summation properties.
- This kind only covers a ratio against the *same actor's* own cumulative damage/heal totals, which is enough
  while nothing else casts the trigger or triggered spell concurrently in the scenario. A clause whose ratio
  must be isolated per-hit (e.g. mixed trigger sources landing in the same window) would need a genuinely
  per-event metric, a different, unbuilt shape.
- Sacred Defense 705306 ("strike back for X% of the damage dealt") and Retribution 707391 ("strike 2 additional
  times for X% of the damage dealt") are not covered by this ADR's two entries: the first's only available
  `taken_hit` striker fixture deals too little damage for the ratio to clear integer-truncation noise (a
  pre-existing, documented fixture limit, not a defect in this kind), and the second's trigger is a melee
  `attack`, not a `cast`, which `checked_magnitude_entry` does not yet accept; either is a follow-up using this
  same kind once its own fixture gap is closed.
