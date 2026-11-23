# 1246. A health-paid cost is checked, not set

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-23
- Decided by: mentor ruling D-9 (Felsworn conformance)

## Context

`conformance.py generate --class 14` stopped in `run.validate` with `step 34.power: value is too large` for the value
scenario of Immolation Aura 800207. Its Spell.dbc record has PowerType 4294967294 (-2, `POWER_HEALTH`) and ManaCost
10, and the generator wrote `{"action": "set_power", "power": 4294967294, "value": 10}`: every generator that pays a
cost before a cast copied the record's PowerType into a `set_power` step, and the harness accepts only power types 0
to 6.

The server pays a health cost with `ModifyHealth(-cost)` and refuses the cast with `SPELL_FAILED_CASTER_AURASTATE`
when the caster's health is equal to or below it (`Spell.cpp`, `CheckPower` and `TakePower`). There is no health
pool to fill: the cast needs only enough health.

Options:

1. Skip the cost step for health and let the cast run on whatever health the caster has.
2. Rewrite health `set_power` steps at the manifest writer, for every generator at once.
3. One helper that the cost-paying sites call: for health it checks the caster's health, for any other type it writes
   the same `set_power` step as before.

Option 1 leaves a refused cast unexplained. Option 2 cannot tell a cost-paying step from a step with an explicit
value (a starved arm, a phase power), where a health check would change the meaning.

## Decision

Option 3. `values.pay_power_steps(power_type, cost, actor)` returns, for `HEALTH_POWER` (4294967294), one assertion
`{"action": "assert", "label": "SETUP: <actor> health pays the <cost> health cost", "actor": <actor>,
"metric": "health", "min": cost + 1}`; for every other power type, the unchanged
`{"action": "set_power", "actor", "power", "value"}` step. Every site that pays a record's ManaCost calls it: the value
scenario (`values.py`), the behaviour kinds (`behaviours.py`), hit scenarios (`hits.py`) and expiry entries
(`expiry.py`). The `SETUP:` label is no expectation label, so it adds no judged reading; a refused cast stays void as
before.

Sites that write an explicit value (`spec.cast_power`, `arm.level`, `phase_power`, `feed_power`, a class file's
`set_power` rotation, the reference mana of `hits.py`) are unchanged: a health type there still fails validation, and
only a class-file entry can reach it.

## Consequences

- Felsworn value scenarios of Immolation Aura (800207 and its ranks) generate, and the cast is checked to be
  affordable instead of failing validation.
- Non-health steps are byte-identical, so the generated scenarios and snapshot digests of the finished classes do not
  move.
- A percentage health cost (Blood of Mannoroth 802075, ManaCost 0, ManaCostPercentage 20) writes no cost step, as for
  other power types with a zero ManaCost.
