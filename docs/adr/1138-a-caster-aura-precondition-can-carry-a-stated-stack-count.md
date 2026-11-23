# 1138. A caster-aura precondition can carry a stated stack count

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21
- Builds on: ADR 1025 (auras_after_required)

## Context

A cast whose CasterAuraSpell is set by the precondition fixture gets one stack. Frenzied Spirits 560748 heals for 2%
of damage per Spirit consumed; one stack cannot tell "per Spirit" from a flat 2%.

## Decision

The option `required_aura_stacks` `{spell, stacks}` sets that precondition fixture to the stated stacks; the spell
must be the CasterAuraSpell of the trigger or a setup cast (the hit_ratio `auras_after_required` precedent, ADR 1025).

## Consequences

Opt-in only; generated scenarios of classes 19 (with and without `--stack`) and 23 are byte-identical.
