# 0719. A cooldown reset rate trigger can have its caster auras set

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-15

## Context

Wicked Intent 504645 (Witch Hunter): "Damage dealt by Desecrate now has a 15% chance to reset the cooldown of Noctis
Blade". Desecrate costs 40 Rage (`cast_power`, ADR 0703) and needs the caster aura 803166 (its CasterAuraSpell,
AscensionWitchHunterCompletion.cpp), which the cast itself removes (AscensionWitchHunterAbilities.cpp). The kind could
refill power but not set a caster aura before each cast (c11-bk stop on claim 68.0). Mentor decision D-160 (c12 tool
batch item 9).

## Options

- An `attempt_auras` field on the kind, as procs and triggers have.
- A permanent fixture aura: the cast removes it.

## Decision

`kinds/cooldown_reset_rate.py` `attempt_auras`: `[{"spell", "stacks", "source"}]`, a `set_aura` on the caster after
the power refill and before every trigger cast, control and treatment alike, named in the contract.

## Consequences

- Templar 19 and Necromancer 23 regenerate byte-identical (no entry states the field).
- Witch Hunter 68.0 needs 8461 trials of a 1.5 s global cooldown, past one case: proven with `pool_cases` (ADR 0720).
