# 0585. A metric-delta aura fixture may set an effect amount

- Status: accepted
- Date: 2026-11-13
- Builds on: ADR 0582

## Context

Necromancer claims 26.1 (Flesh Symbiosis 301207 "Each Abomination ... active") and 94.1 (Army of the Dead 525600
"While only 1 Abomination is active") need two Abominations (3 Life Force each) at once. Life Force capacity is
`2 + SPELLMOD_MAX_AURA_STACKS on 805011` (`AscensionNecromancer.cpp:103-107`), and Summoning Adept 92123 Effect[2] is
that modifier (+1). The harness `set_aura` step already takes `effect` and `amount` (`AuraEffect::ChangeAmount`),
but `metric_delta` aura fixtures (`phase_auras`, `after_auras`) carry spell, stacks, unit and caster only; amounts
existed only in `hit_ratio` arms (`aura_amounts`), whose readings cannot be armor or an owned-creature count. Stacks
cannot stand in: `set_aura` refuses stacks above the aura's limit (1 for 92123).

## Options

1. A fifth element on `phase_auras` / `after_auras` (a `MetricDeltaSpec` change and a new parser shape).
2. A `metric_delta` option module `phase_aura_amounts` (ADR 0582) and a second named point in `cast_steps`.

## Decision

Option 2. `metric_delta_options/phase_aura_amounts.py` parses `[spell, effect, amount]` triples, refuses an effect
outside 0-2 and a spell that is neither a phase nor an after aura of the entry, and its `phase_steps(spec, value,
after)` returns, for every triple whose aura is set in that phase, the aura's own `set_aura` step with `effect` and
`amount` added. `metric_delta_options.option_phase_steps(spec, after)` is the named point: `cast_steps` calls it
right after the phase and after aura steps, so the amount follows its aura in the same phase.

## Consequences

- An entry without the option gets no new step: `generate --class 19`, `--stack` and the other Necromancer entries
  are unchanged.
- The pilot (c5 pilot2, two runs) read Life Force 805011 at 3 without and 6 with amount 4, two Abominations held at
  capacity 7, and the armor ratio with two Abominations 94 -> 150 (1.5957 for 1.6; the engine stores an integer
  armor).
- Only effects of auras the entry sets can be changed; an amount on a learned passive that the entry does not also set
  as a fixture needs its own decision.
