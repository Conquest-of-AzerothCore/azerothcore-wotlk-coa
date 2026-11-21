# 0049. `self_stack_bonus` class-file field for repeat-cast `hit_mean` scenarios

- Status: accepted
- Date: 2026-11-09

## Context

570233 (Templar "Righteous Lunge", rank of 801443) carried an open `hit_mean` `alert` since round 5: after a
tool fix for an unrelated swapped-order bug, a residual deviation (+5.2% to +10.1% depending on the round)
remained between the measured mean and the unstacked weapon model. Round 8's `server-findings-hit-means.md`
attributed this to Righteous Lunge's own documented self-stacking Oath bonus (the tooltip shows `$804904s2` =
5%, and `AscensionTemplarAbilities.cpp:157/163` grants a stack of the Oath chain buff 804904/704576 after every
cast of a `Family(info, 2, 1)` ability, 801443 included) but left it open "without proof", since the item's
budget covered only a one-off manual isolated-cast scenario, not a generic fix.

Round 9 reproduced this independently at the current base (`07fb6f4ff1`): a scenario trimmed to a single cast
(0 pre-existing stacks) measured a mean of 373.0 against the unstacked model's 372.0 (gameplay stamp
`20261109-203303`), while the normal 3-cast scenario measured 391.0 (1173/3) against the same 372.0 unstacked
model (stamp `20261109-203047`) — matching `372.0 x (1 + 0.05 x (3-1)/2) = 390.6` to within 0.1%. This confirms
the server behaviour is correct (the tooltip's own documented stacking is exactly what is measured); the
`hit_mean` *check* is what assumes independent, identically distributed casts, an assumption Righteous Lunge's
own self-buffing tooltip breaks.

## Considered options

1. Leave it open as a proven-but-unfixed defect. Rejected: it is not a defect — the measured number matches the
   tooltip-documented mechanism exactly once isolated — so filing it as a server finding would misreport working
   behaviour as broken.
2. Widen 570233's tolerance band to swallow the deviation. Rejected outright by the task rules: a tolerance
   widened without proof the deviation is expected turns a real check into one that cannot fail; even with
   proof in hand here, a wider band would still mask an actual future regression in Righteous Lunge's weapon
   damage (a different, uncorrelated residual) by the same margin.
3. Reduce this rank's scenario to 1 cast (the isolated proof) so no stacking occurs. Rejected: `casts_needed`
   sizes repeat casts to keep the 99% interval of the mean within `MEAN_HALF_WIDTH`, a class-agnostic precision
   guarantee every other weapon-kind check relies on; permanently measuring with 1 cast would widen this one
   rank's interval far past that bound for no reason connected to the actual gap.
4. Hardcode Righteous Lunge's spell/aura ids inside `hits.py`. Rejected: `hits.py` is class-agnostic tool code
   (AGENTS.md); a single Templar data point does not justify a Templar-specific branch in shared code.
5. Add a new, additive, opt-in `self_stack_bonus` class-file field (`[{"rank", "percent_per_stack"}]`), consulted
   by `hit_parts` (generate time) and `measured_hit_model` (compare time) to scale the modelled hit's mean by the
   average stack multiplier across the scenario's actual cast count, with multiplier 1.0 (no change) for every
   rank that omits it. Chosen.

## Decision

- `hits.py` gains `self_stack_multiplier(class_file, rank_id, performed) -> float`, reading an optional
  `self_stack_bonus` list from the class file; returns `1.0` when no entry matches `rank_id` (including every
  class file that does not define the field at all).
- `hit_parts` applies the multiplier per part (`replace(model, mean=model.mean * self_stack_multiplier(...))`,
  using that part's own `performed` cast count) before building its `record`/`Expectation`, so a scenario split
  into several parts (a different cast count per part) gets the right multiplier per part rather than one shared
  across all of them.
- `measured_hit_model` (the `HitModelSource` `compare.py`'s `judge_hit` calls with the real measured caster
  stats) applies the same multiplier, read from the stored `expectation.model['part_casts']`, so the compare-time
  expected mean matches the generate-time one exactly.
- `scaffold.py`'s `EMPTY_LIST_FIELDS` gains `self_stack_bonus`, so a newly scaffolded class file carries an empty
  list like every other optional per-spell override.
- `classes/templar.json` gains one entry: `{"rank": 570233, "percent_per_stack": 5.0, "reason": "..."}`, citing
  the tooltip token, the granting code, and this round's isolated-cast proof.
- `test_hits.py` gains `SelfStackMultiplierTest`, unit-testing `self_stack_multiplier` directly and
  independently of any class file or gameplay run: multiplier `1.0` with no `self_stack_bonus` field at all,
  `1.0` for a rank the field lists but doesn't match, `1.0` for a single cast regardless of percent, the exact
  linear formula for a 3-cast example, and a seeded-defect case (a wrong `percent_per_stack` produces a
  different multiplier than the correct one) proving the test can fail.

## Consequences

- 570233's `hit_mean` moves from a 3+ round open `alert` to `ok` (verified this round, build+gameplay stamp
  `20261109-203047`/`...-203303`; see `round9/mechanics-report.md`), with no loss of check power: the scenario
  still measures the real weapon-damage formula and will still alert on an actual regression in the roll, armor
  mitigation, or the Oath bonus's own percentage. `self_stack_multiplier` itself is now covered by a unit test,
  so a future regression in the formula (an off-by-one in `performed - 1`, a sign flip, a wrong `performed`)
  fails `test_hits.py` directly rather than relying only on the one live gameplay data point.
- Any future class rank whose own tooltip documents an identical "stacks from a previous cast of itself" bonus
  can use `self_stack_bonus` directly, with no new class-specific code in `hits.py`; a rank without this pattern
  is completely unaffected (multiplier 1.0).
- The model assumes stacks accrue linearly from 0 and do not carry across scenario parts (each part starts a
  fresh character) and do not decay mid-part (confirmed for Righteous Lunge's 15 s chain aura against this
  item's cast spacing, not re-derived generically); a rank whose stacking decays within a single part's cast
  spacing, or whose bonus is non-linear in stack count, would need a different model and is not covered by this
  field as written — flagged, not yet a problem.
