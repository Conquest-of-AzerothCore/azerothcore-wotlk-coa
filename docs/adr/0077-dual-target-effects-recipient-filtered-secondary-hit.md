# 0077. A `dual_target_effects` secondary, recipient-filtered `hit_mean` check

- Status: accepted
- Date: 2026-11-10

## Context

Temple Guardian's tooltip (803792) states "healing you and them for `${$m2+0+$AP*0.805+$sph*0.85}`". `hit_kind`
already groups both of 803792's `SPELL_EFFECT_HEAL` effects (effect 1, `TARGET_UNIT_TARGET_ALLY`, "them"; effect
2, `TARGET_UNIT_CASTER`, "you") into one `heal` kind with `hits_per_cast = 2` (`docs/hit-scenarios.md`'s existing
Temple Guardian paragraph, `matching_sibling`/`SHARED_TOKEN_KINDS`), so the existing, unfiltered `803792 hit_mean`
check already requires two heal events per cast to clear `minimum_hits` and reach `ok` rather than
`insufficient_trials`. This proves two heal events occur, but the unfiltered `spell_heal_total`/`_count`
measurement (`receiver = {}` in `hit_measurements` when `ally` is true) does not read who received either one: two
heals both landing on the ally (a hypothetical bug duplicating the ally's heal and never reaching the caster)
would still clear `minimum_hits = 2 x casts` and judge `ok`. The clause's "you" half — the caster's own received
heal — is therefore proven only by count, not by recipient.

## Considered options

1. Leave the existing combined `hit_mean` check as the clause's only proof. Rejected: it cannot fail the specific
   scenario above (both heals to the ally, none to the caster), so it does not prove the "you" half as the clause
   literally states it; the owner's "no excuses" rule treats each clause's parts as needing their own proof.
2. Change `hit_measurements`'s default (unfiltered) heal measurement to always filter by a single named recipient
   for every `ally`-targeted heal scenario. Rejected: this would require picking one recipient and silently stop
   counting the other's heal events, breaking the existing `hits_per_cast = 2` combined proof (and its own
   seeded-wrong-value unit tests) for every caller, not just 803792.
3. Add an opt-in, class-file-driven `dual_target_effects` list read by `hit_parts`: for a named rank, add one
   extra `target`-filtered `spell_heal_total`/`spell_heal_count` measurement (same `critical: False` convention
   as the existing pair) for a named `secondary_actor`, and one extra `hit_mean` expectation at
   `secondary_effect` whose `minimum_hits` is `casts` (one event per cast, since this measurement only ever sees
   one of the two combined events) rather than `casts x hits_per_cast`. The existing combined expectation, its
   label and its `minimum_hits` are untouched, so every other `hit_parts` caller is unaffected. Chosen.

## Decision

- `hits.py` gains `dual_target_entry(class_file, rank_id)`, `secondary_heal_labels(label, effect)` and
  `secondary_heal_measurements(hit_spell, labels, actor)`. `hit_parts` looks up `dual_target_entry` for a
  `heal`-kind, non-hostile rank, validates `secondary_effect` is one of `hit.indexes`, and per scenario part adds
  the secondary measurement steps and a second `Expectation` (`check='hit_mean'`, `effect_index=secondary_effect`,
  same `displayed`/`rule` as the combined one, `model['minimum_hits'] = casts`).
- `judge_hit` (`compare.py`) is unchanged: it recomputes the expected mean from `expectation.rank_id` via
  `measured_hit_model`/`rank_hit`, which does not depend on which effect index asked for it, so the secondary
  expectation is judged against the same formula value as the combined one — by the identity of the recipient
  instead of only the combined count.
- `classes/templar.json` gets one `dual_target_effects` entry for 803792 (`primary_effect: 1`,
  `secondary_effect: 2`, `secondary_actor: "caster"`), citing the DBC fields and the `hit_kind`/`hits_per_cast`
  mechanism in `reason`. `scaffold.py`'s `EMPTY_LIST_FIELDS` gets the new key so a freshly scaffolded class file
  defaults it to `[]`.

## Consequences

- Any other dual-recipient `heal`-kind rank (Templar's own or another class's) gets the recipient-specific proof
  with a four-field class-file entry and no new tool code.
- A future regression that routes the second heal event to the wrong recipient (or drops it) now alerts
  specifically on the secondary expectation (`insufficient_trials`, as its own seeded-wrong-value unit test in
  `test_hits.py` exercises directly), instead of passing silently behind the combined count.
