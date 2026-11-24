# 1226. Hit-ratio arm casts may name their target and power

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-22

## Context

A `hit_ratio` arm's `casts` were always made by the caster at the dummy. Sun Cleric Sacred Vessel 680648 ("increases
your critical strike chance and healing by $681254s1%") is fed by Illumination 500143 consuming Angelic Presence
800722; Illumination is an ally-target heal (Spell.dbc EffectImplicitTargetA 21), so cast at the dummy it consumed
nothing and the first design read a ratio of 0.99988. Blessing of Triumph 804250 ("$680911s3% increased damage") is cast
at a blessed ally while the ally deals the observed damage (`caster: ally`), and the percentage mana costs of Bless
804247 and 804250 would drain the caster across the trials. Mentor D-199, D-214.

## Options

- A new kind for each claim: duplicates the hit-ratio sampling and judge.
- Setting the fed aura with `set_aura`: forbidden as a fixture of the claim.
- An opt-in item form of the existing arm casts, routed through the existing `hit_ratio_cast(target, power)`.

## Decision

An arm `casts` item may be `{spell, target?, power?}`. `target` is `caster`, `dummy`, or `ally` when the ally is the
scenario's caster or target; `power` sets the cast's power right before it. Bare ids keep the old steps; `crit_rate`
refuses targeted items. The contract names each targeted cast.

## Consequences

- Opt-in: no existing entry writes an item, so the finished classes regenerate byte-identical.
- Seeded tests: bare ids and plain items give the same steps, a routed cast goes to its target with its power, the ally
  is accepted only with the ally in the scenario, malformed items are refused (mutant: a route ignored would cast at the
  dummy and fail the target test).
