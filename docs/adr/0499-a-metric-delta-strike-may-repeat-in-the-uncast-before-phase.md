# 0499. A metric_delta strike may repeat in the uncast before phase

- Status: accepted
- Date: 2026-11-13

## Context

Summoning Ritual 805038 says "you may cast Ritual Return to return to it", and Ritual Return 807098 says "Teleport back
to the position of your Scourge Transporter". A cast contrast needs the circle and the caster's move in both phases,
with Ritual Return cast only in the after phase. `metric_delta` runs its strike (the `dx` relocation, health fixture and
striker casts) only next to a trigger cast, so a before phase without the cast (`cast_in_before: false`) left the
caster unmoved and the before read showed no move (claims 259.1 and 404.0, parked).

## Options

1. Move the relocation out of the strike into a new phase field: it duplicates the strike's own placement.
2. A strike flag that repeats the strike in the uncast before phase, after its setup casts. Chosen.

## Decision

- `MetricDeltaStrike.in_before` (`strike.in_before`, default `false`). When it is true, the `between` path adds the
  strike steps to the before phase after `setup_in_before`'s setup casts, and the contract says so.
- It is refused with `cast_in_before: true`, another gate timing, `setup_only_after`, `attack_swings` or
  `after_trigger_ms`.

## Consequences

- An entry without the flag generates the same scenarios. Templar `generate --class 19`, `--stack` and Necromancer
  `--class 23` are byte-identical to bf83cf15b1.
- Tests: `MetricDeltaStrikeInBeforeTests` (test_behaviours.py).
