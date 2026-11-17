# 0723. A detection read can count as a promised state

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Witch Hunter claim 155.0 ("Enemies affected by Witchblood Fever can be seen while stealthed.", 680513) is a
visibility state of the caster towards a debuffed enemy. The only read of it, `can_detect` (`Unit::CanSeeOrDetect` of
the measuring unit for a target, ADR 0197), sat in the `READBACK` row of `coverage.METRIC_EVIDENCE`, so any
`metric_delta` on it counted as data whatever its contrast. A readback names a value the server stores (a modifier, a
cooldown); `can_detect` is instead the result of the visibility rules on live units, like `can_attack` or `alive`.
Mentor decision D-185 (c13 tool batch item 2, design G3 in the c12 gap designs).

## Options

- Move `can_detect` to the `STATE` row with a `STATE_PROMISES` row, so that a learned or own-cast contrast counts as
  behaviour only when the claim words name the state.
- A kind-module row for `can_detect`: refused by `KIND_ROW_OVERRIDES`, which keeps base rows closed.
- Keep the readback and count 155.0 through the client-visible set (`nearby_creature_at_client`, ADR 0222): that read
  needs the caster to step aside and back, which a `metric_delta` around a real cast does not do.

## Decision

The first option: `can_detect` is a `STATE` metric, promised by `seen|detect\w*|stealth\w*`. As for every state, a
`metric_delta` counts as behaviour only under a learned or own-cast contrast with the promise in the claim words; a
condition contrast or a verdict without a contrast (the `detection` kind's predicate entries carry none) stays data.

## Consequences

- Templar 19 and Necromancer 23 regenerate byte-identical (`snapshots.py check`): generation reads the row only through
  `metric_delta_contrast`, and neither class has a `metric_delta` on `can_detect`.
- The archived Necromancer final15 pair re-audits byte-identical (no `can_detect` verdict). The Templar's only
  `can_detect` labels are the `detection` predicate labels of 300513, whose verdicts carry no contrast, so they stay
  data; that claim counts through its client-visible labels, unchanged.
- Seeded test: a learned-contrast `can_detect` verdict is behaviour under "can be seen while stealthed", data under a
  claim without the promised words or without a contrast, and unproven when it alerts.
- Witch Hunter: `680513 behaviour_metric_delta witchblood_seen` (a stealthed dummy, Stealth Dummy 2144558 as a
  fixture, read 0 without the talent and 1 after a real Tonic and Witchblood Fever with it), with
  `witchblood_stealth_held` reading the stealth still on the dummy at that moment.
