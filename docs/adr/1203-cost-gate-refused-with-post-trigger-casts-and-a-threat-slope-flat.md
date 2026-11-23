# 1203. Cost gate `refused_with`, `post_trigger_casts` and a threat slope flat

- Status: proposed (provisional number; 1030 is taken on the class branch, renumbered at merge, guide 14.4)
- Date: 2026-11-22
- Related: [ADR 0581](0581-behaviour-kinds-are-modules-discovered-at-run-time.md) (kind modules),
  [ADR 0582](0582-metric-delta-options-are-modules.md) (option modules),
  [ADR 1197](1197-opt-in-fixture-fields-a-cooldown-tick-cut-kind-and-ground-effect-reach-reads.md) (opt-in fields).
- Decided by: mentor D-176 (Sun Cleric round 11 chunk d8, notes 1, 3 and 4).

## Context

Three Sun Cleric claims could not be written: a cooldown reset that the tooltip limits to a phase ("while in
Sunrise"), a refreshed charge count read by consuming the charges, and a threat reduction on a spell with no spell
power term whose expected threat per damage cannot be derived from the DBC.

## Options

- Change the defaults of the kinds. Rejected: finished classes would regenerate differently.
- Opt-in fields, each absent by default, so every existing scenario regenerates byte-identical.

## Decision

- `cost_gate` `refused_with` (only with `resets`): the `with` arm expects the refusal code of the resource, as the
  `without` arm does. An entry with the other phase's aura in `cast_auras` states "no reset outside the phase". An
  accepted recast is an alert and a finding, never a changed expectation. The `with` arm also reads `cast_failure`
  of the entry's spell before the attempt (label `... with after_cast`, expected 0): without it, an after cast
  refused for any reason (a missing checker aura, its own cooldown) would produce the expected refusal and an `ok`
  (review I-1 of d8).
- `metric_delta` option `post_trigger_casts` (`{"spell", "count", "gap_ms", "health_pct"}`, named point
  `after_trigger_steps`): casts `spell` on the caster `count` times after the trigger of each phase that casts it.
  Refused with a `strike`.
- `threat_slope` fields `flat` (added to the flat part: Spell.cpp:5733-5737 adds the SpellLevel of the spell cast
  when it has no threat entry), `learn` (spells learned before the cast, the talent) and `label_suffix` (so a talent
  entry and its control entry do not share labels). The control entry reads 1.0; a control off 1.0 means the flat is
  wrong and voids the trial.
- `threat_slope` fields `settle_ms` (added to the read wait, for a spell whose damage lands after its cast) and
  `unlanded` (needs `settle_ms`: spells whose damage on the dummy must still be 0 after the threat read; a count above
  0 makes the trial `unmeasured`, since that hit's threat and damage would enter the slope). Sun Down 572752 deals its
  damage through 572753 when its 2000 ms aura expires and then lays the ground aura 572754, whose first Solar Flare
  807175 tick comes 3000 ms later: `settle_ms` 2500 reads between the two, `unlanded` [807175] proves it.

## Consequences

- Sun Cleric d8: `refused_with` found the Solar Concord reset accepted in the other phase (a finding);
  `threat_slope` read Sunflare 800231 at 0.8000 with the talent and 1.0 for the control (flat 1);
  `post_trigger_casts` was exercised once and its consumption entries were withdrawn (the control did not tell the
  refresh apart), so no counted entry uses it yet.
- Finished-class guards (`generate` for classes 15, 19, 19 `--stack`, 23, byte-identical before and after) are the
  controller's check before merge.
