# 1025. A hit-ratio arm can wait a lead time and set auras after the required step

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21
- Builds on: ADR 0760 (crit_rate treatment share)

## Context

Several Witch Doctor buffs exist only some time after a real cast: Soul Marionette's transform 807044 about 8000 ms
after the cast, the Lesser Shadow Avatar 706544 after the 15000 ms Shadow Avatar, and ten Voodoo Hunger stacks 5000 ms
into Shadowstalker. A `hit_ratio` or `crit_rate` arm makes its `casts` before every trial and then waits only the
cast wait, so the observed cast came too early, and a `set_aura` of the buff would make the fixture the claim's
subject (guide 3.4). A cast with a `CasterAuraSpell` also gets a one-stack required-aura step right before it, which
replaces the five Spirit stacks an arm sets for Spirit Eclipse 811117 and Frenzied Spirits 560748.

The cycle 10 proposal also named `trial_casts`. The arm `casts` already run before every trial in both kinds, so no
new field is needed for that part.

## Decision

Two optional arm fields of `hit_ratio` and `crit_rate` (`behaviours.py`, `HitArm`):

- `casts_wait_ms` (0 to 30000, only with arm `casts`): a wait after the arm's casts and before the observed cast of
  every trial. The trial limit counts it.
- `auras_after_required` (`[spell, stacks]` of distinct spells): set right after the required-aura step of every cast
  of the trial that has one (arm casts and the observed cast), before that cast. An arm whose casts have no
  `CasterAuraSpell` is refused.

Both are refused before a swing. The contract names each field it uses.

## Consequences

- No existing entry sets them: generated scenarios of classes 19 (also `--stack`) and 23 are byte-identical
  (`diff -r`, 2026-11-21).
- Witch Doctor entries: 560748 `crit_damage_spirits`, 704497 `wrath_transform`, `juju_transform`,
  `wrath_transform_crit` and `juju_transform_crit`, 705894 `eclipse_spirits`, 705942 `arrow_hunger`, 706543
  `lesser_damage` (clauses 110, 146, 147, 195, 227 and 247).
- Seeded tests in `test_behaviours.py` (`HitRatioArmLeadTests`): the lead wait per trial, the crit_rate lead, the
  order of the required step and the later auras, unchanged entries without the fields, and the refusals.
