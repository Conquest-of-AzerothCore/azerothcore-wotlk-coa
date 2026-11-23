# 0080. `ally_heal_breadth` behaviour check for proc-triggered AoE heals landing on allies

- Status: accepted
- Date: 2026-11-10

## Context

The multi-target-aoe workstream's remaining clauses include two Templar passives whose tooltip claims a
proc-triggered heal reaches more than one ally: Libram of Grace 801463 ("causing your damaging abilities to
restore ... health to you and nearby allies") and Chakra of Light 803159 ("Oath Breakers now heal allies around
the target"). Both are already in `templar.json`'s `triggers` section with a `spell_cast_count` verdict proving
the passive casts its heal spell (804150 "Grace" for 801463, 803160 for 803159) once per trigger, but neither
verdict reads who the heal actually lands on: `trigger_scenario`'s generic flow measures a cast count on the
caster, not a target breadth.

`coa-dbc-viewer` reads (this session) confirm both heal spells apply via `EffectImplicitTargetA[0] = 22`
(`TARGET_SRC_CASTER`) combined with `EffectImplicitTargetB[0]` 31/30 (`TARGET_UNIT_DEST_AREA_ALLY` /
`TARGET_UNIT_SRC_AREA_ALLY`), both at `EffectRadiusIndex[0] = 18` (`SpellRadius.dbc` 15.0 yd): a stock,
no-CoA-code AoE-ally heal around the caster's own position. `CoAGameplayTest.cpp`'s existing `spell_heal_count`
metric, read with `actor = CASTER` and `target = <a specific ally id>`, already answers "did the caster's heal
of spell X land on this specific unit" (the same `actor = CASTER, target = <id>` convention `hit_measurement`'s
`spell_damage_count` branch already uses for enemy dummies in `target_count_scenario`); the only missing piece
is a fixture shape with several *player* allies (not creature dummies) near the caster, triggered by a
*separate* damaging/Oath-Breaker ability cast at a dummy, while the before/after-passive-learn discipline
isolates the breadth from the caster's own baseline (the caster is never one of the measured allies).

## Considered options

1. Extend `trigger_scenario` (`triggers.py`) itself to optionally add ally fixtures and read per-ally heal
   counts. Rejected: that function's `TRIGGER_CHECK`/`trigger_count` verdict is built around a statistical
   rate (trials vs. events, Wilson-interval tolerant), tuned for proc-chance measurement; repurposing its model
   for a deterministic per-ally hit/no-hit count would either misuse that verdict's fields or need a parallel
   model under the same function, no simpler than a dedicated builder.
2. Add a manual, per-clause `behaviour_*` kind, matching the pattern `fixed_count` (round 10 step 1) and
   `party_stat_ratio` (round 10 step 2) already established in this workstream for check shapes the generic
   engines do not cover, but reusing the existing `BEHAVIOUR_COUNT` check and its `behaviour_count_verdict`
   verbatim (no new verdict function) since the before/after-delta/per-label-hit semantics already match
   exactly what a gated proc-breadth check needs. Chosen.
3. Reuse `party_stat_ratio`'s before/after-ratio judging. Rejected: a ratio needs a non-zero baseline value to
   divide by; a heal LANDING on an ally is a count of discrete events (0 or more), not a continuous stat with a
   baseline, so there is nothing to take a ratio of.

## Decision

- `behaviours.py` gains `ally_heal_breadth`/`AllyHealBreadthSpec(spell, name, quote, expected, heal_spell,
  trigger_spell, radius_reason, near_distance=3.0, repeats=5)`: builds `expected` grouped, non-caster ally
  player fixtures (`nearby_ally_id(0..expected-1)`) near the caster, a single enemy dummy for the
  proc-triggering cast, learns and repeatedly casts `trigger_spell` at the dummy before `spell` (the clause
  owner) is learned (measuring `spell_heal_count` of `heal_spell` on each ally, expected all-zero), then learns
  `spell` and repeats the casts (measuring again, expected a hit on every ally). The model it emits is the
  existing `count`/`BEHAVIOUR_COUNT` shape verbatim (`{'kind': 'count', 'dummy_labels': [(before, after), ...],
  'expected': ..., 'quote': ...}`), judged by the unmodified `behaviour_count_verdict` — no `compare.py` change.
- `passives.py`'s `BEHAVIOUR_LABELS` (used when a passive scan links an effect to a `behaviours.json` entry
  instead of classifying it directly) gains `'ally_heal_breadth'` mapped to the same `behaviour_count` label
  format as `'count'`, since both kinds produce that exact Expectation label.
- Wired for two Templar clauses: 801463 (trigger 807268 "Argent Blade", the same generic damaging-ability
  fixture spell this batch's own Unbroken Creed/Heaven's Finest/Scarlet Champion trigger entries already use,
  heal spell 804150, 2 allies), 803159 (trigger 572027 "a dominating Oath Breaker", the same fixture its own
  existing `triggers.json` entry already casts, heal spell 803160, 2 allies).
- No change to the generic `passives.py` classification engine, to `compare.py`'s judging, or to any server
  code.

## Consequences

- A future proc-triggered AoE heal clause ("heal nearby allies", "heal allies around the target") whose heal
  spell is already known (from an existing `triggers.json`/`procs.json` entry or a direct DBC read) can reuse
  this kind directly from the class file, supplying only `heal_spell`/`trigger_spell`/`expected`, with no new
  Python or C++.
- A clause where the ability casting the heal is itself the ability being proved (no separate gating passive,
  e.g. 801465 Silverhand Incantation's heal half, whose `SPELL_EFFECT_CHARGE` moves the caster to the enemy
  target before the heal's `TARGET_SRC_CASTER` origin applies) needs the allies positioned near that *target*,
  not near the caster's starting position, and has no "before" phase to measure (the ability cannot be cast
  before it is learned) — a related but distinct fixture shape, left to a later step of this workstream.
- This decision's two clauses are proven by Python unit tests (structural fixtures, dispatch, before/after
  ordering, and a seeded-wrong judge case) and by the `source` stage, but **not yet by a gameplay run**: both
  attempts in this session (`coa-verify --ram --stages gameplay`) failed before either worldserver reached this
  scenario, because the shared in-RAM test MySQL container's `/var/lib/mysql` tmpfs (12G) was already at 93%
  (868M free) from six other worktrees' long-lived `coa_test_<hash>_world` cache copies, leaving no room to
  create this worktree's own world database copy (`ERROR 3675/1114 ... disk is full`, confirmed with
  `docker exec coa-test-mysql df -h /var/lib/mysql` across four repeated attempts ~10 minutes apart with no
  change). This is a shared-infrastructure capacity exhaustion from concurrently running sibling sessions, not
  a defect in this change; the two clauses stay in the workstream's remaining list until a gameplay run can
  confirm them.
