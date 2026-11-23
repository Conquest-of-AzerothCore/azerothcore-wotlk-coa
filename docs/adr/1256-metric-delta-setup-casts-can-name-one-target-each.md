# 1256. Metric delta setup casts can name one target each

- Status: accepted (number provisional, assigned at merge)
- Date: 2026-11-23
- Decided by: controller go (Felsworn endgame tool group B-2, owner delegation O-12)

## Context

Demonic Embrace 520257 restores Energy when Inner Demon is cast "with at least 6 Felfury". The below-six arm needs a
real Felfury count under six before the Inner Demon cast: the harness sets the Inner Demon caster-aura requirement
800058 to one stack right before the setup casts, so an aura fixture cannot hold five stacks, and the count must be
built by casts: Burning Hatred at the caster (six), Sargeron Smite at the dummy (minus two), Bane of Fire at the dummy
(plus one). `setup_target` names one target for every setup cast.

## Options

- Per-cast targets inside `setup_casts` (`[spell, target]` pairs): changes the parsing of a field every class uses.
- Extra casts appended through the existing `setup_cast_steps` option point: duplicates the power, cooldown, aura
  and reagent steps of a setup cast.
- An option that names one target per setup cast, read at one new option point where the setup cast step is built.

## Decision

The `metric_delta` option `setup_cast_targets` is a list of scenario units (`caster`, `dummy`, `enemy`, `corpse`),
one per setup cast. The setup cast step reads the target through the new option point `setup_cast_target(spec,
value, index)` (`option_setup_cast_target` in `metric_delta_options/__init__.py`), falling back to `setup_target`,
then to the entry's target. It is refused with `setup_target`, `gate_cast` or `attack_swings`, or when its length
differs from `setup_casts`. Python only, opt-in, default off.

## Consequences

- Test: `SetupCastTargetsTests` (metric_delta_options/test_setup_cast_targets.py); the swapped-list case is the
  seeded mutant the step check catches.
- Only entries that set the option change; finished-class scenario digests are unchanged.
- Documented in `apps/coa-gameplay-test/conformance/docs/metric_delta_options/setup_cast_targets.md`.
