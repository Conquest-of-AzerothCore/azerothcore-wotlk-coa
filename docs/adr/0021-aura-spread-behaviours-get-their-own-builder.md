# 0021. A prose-stated aura spread (Holy Tempest) gets its own `behaviours.py` builder

- Status: accepted
- Date: 2026-11-07

## Context

Round 2 picked up Holy Tempest 301339, the remaining Templar item from `design.md` ruling P3-R5 /
`track-b-brief.md` Task B5 ("Track B, not attempted"). Its tooltip reads "Damage dealt by Righteous Tempest now
spreads Condemn on affected enemies to a nearby enemy" - a count claim of 1, the same shape `TargetCountSpec`
already judges for Scarlet Judicator (525024) and Justice (712437).

`TargetCountSpec`'s `aura` metric (`behaviours.py:85-91`, `hit_measurement`) always reads the *cast* spell's own
aura on the dummy: `measurement(label, dummy_id(index), 'aura', spell=spec.target_rank, caster=CASTER)`. Holy
Tempest's claim needs a different shape: the spell cast at the primary dummy is Righteous Tempest (807274), but the
aura that must appear on the nearby dummy is Condemn (567539) - a pre-existing, independent debuff that has to be
seeded onto the primary dummy *before* Righteous Tempest's damage can copy it there. `target_count_scenario` also
has no step that applies a precondition spell before the measured cast, and its post-cast wait
(`facts.cast_time_ms + CAST_MARGIN_MS`) assumes an instant readout, not a multi-tick periodic buff that must run to
completion (`Records.duration_ms(target_rank)`) before the copy can be observed.

## Considered options

1. Add optional `seed_spell`/`aura_spell` fields to `TargetCountSpec`, defaulting to reproduce today's behaviour
   (`aura_spell` defaults to `target_rank`, `seed_spell` defaults to `None` -> no seed step). Touches less code;
   keeps one dataclass and one builder for every `count`-shaped entry.
2. Add a new, additive `AuraSpreadSpec` dataclass and `aura_spread_scenario` builder, dispatched by its own
   `entry['kind']` tag, reusing `behaviour_entry`, `dummy_fixture`/`dummy_id` and the existing `BEHAVIOUR_COUNT`
   `Expectation`/judge unchanged. Chosen.

## Decision

- `behaviours.py` gains `AuraSpreadSpec` (`spell`, `name`, `quote`, `expected`, `seed_spell`, `aura_spell`,
  `target_rank`, `radius`, `radius_reason`, `repeats`), `aura_spread_scenario(class_file, spec)` and
  `aura_spread_spec(entry)`, dispatched from `behaviour_scenario` on `entry['kind'] == 'spread'`.
- `aura_spread_scenario` calls `behaviour_entry(records, spec.spell, spec.name, 'count', spec.quote, spec.expected)`
  internally with `kind='count'`: the judging vocabulary stays the shared `behaviour_count` check (same
  `Expectation.model` shape as `target_count_scenario`'s, `{'kind': 'count', 'dummy_labels': ..., 'expected': ...}`),
  so `compare.behaviour_count_verdict` needs no change. Only the class-file `kind` tag (`"spread"`) is new, and it
  exists solely to pick the scenario builder.
- The builder learns both `seed_spell` and `target_rank` once per scenario before the first cast: at the reference
  character's level, the exact-level-gated top rank of a talent chain (807274 requires level 60; so does 567539)
  is not granted automatically the way some other `behaviours` entries' active ranks are, and the regression
  scenario this check is modelled on (`apps/coa-gameplay-test/scenarios/templar-10163-holy-tempest-condemn-spread.json`)
  explicitly learns its ranks for the same reason.
- `TargetCountSpec`/`target_count_scenario` are untouched: no existing entry's meaning changes.

## Consequences

- Holy Tempest 301339 gets a `behaviour_count` verdict (`ok`, measured 1 of 1, in the scenario run this round) with
  no change to the judge or to the 525024/712437 entries.
- A second `count`-shaped dataclass now exists alongside `TargetCountSpec`; a future "spread-like" passive picks
  whichever of the two fits its shape, or extends `AuraSpreadSpec` if the difference is additive.
- While building this scenario, the same `knows_spell` gap that option 1's rejected alternative would have
  inherited unmodified was found to likely also affect `target_count_scenario`'s own 525024/712437 entries (their
  `target_rank` is never explicitly learned either, and both read a flat 0 in the stored phase-3 run); this ADR
  does not fix that, since 525024/712437 are outside this round's scope, but the finding is carried in
  `round2/holy-tempest-report.md` for a future round.
