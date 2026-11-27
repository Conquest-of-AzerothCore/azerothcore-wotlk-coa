# 1323. `peaceful_resurrect` supports `SPELL_EFFECT_RESURRECT` (effect 18) percentage expectations without >100% clamping

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-26
- Rulings: Bloodmage Bucket 2 tool plan (`bm-tb1`, Vampyr Bite `803585` Effect 18 design reference)

## Context

`behaviours.py` previously defined `RESURRECT_EFFECTS = frozenset({113})`, accepting only `SPELL_EFFECT_RESURRECT_NEW`
(113, flat health in `EffectBasePoints + EffectDieSides` and flat mana in `EffectMiscValue`), even though `values.py`
already defined `RESURRECT_EFFECTS = frozenset({18, 113})`.

Bloodmage's *Vampyr Bite* (`803585` / rank 1 `801563`) uses `SPELL_EFFECT_RESURRECT` (effect 18), whose server handler
(`Spell::EffectResurrect`, `SpellEffects.cpp:5735-5736`) computes `CountPctFromMaxHealth(damage)` and
`CalculatePct(GetMaxPower(POWER_MANA), damage)` from `EffectBasePoints + EffectDieSides` as a percentage, while
`Player::ResurectUsingRequestData` (`Player.cpp:13912-13920`) caps the restored values at `GetMaxHealth()` and
`GetMaxPower(POWER_MANA)`. Silently clamping expectations above `100%` in the conformance tool would hide broken DBC
percentages (such as `803585`'s `820%`, which alerts truthfully against `100%` restored HP/mana).

## Options

- Clamp percentage expectations to `min(100, pct)`: rejected, because an oversized DBC percentage (`820%`) would
  false-pass when the server caps the restored pool at `100%`.
- Support effect 18 in `behaviours.py` (`RESURRECT_EFFECTS = frozenset({18, 113})`) and `kinds/peaceful_resurrect.py`
  by reading `ALLY`'s `max_health` and `max_power` (power 0) after resurrection and computing the exact unclamped
  `CalculatePct(maximum, pct)` expectation (`float32` arithmetic matching `Util.h:52-55`), plus optional `ally_class`
  (`12..32`) for testing mana restoration when the caster class has no mana pool. Chosen.

## Decision

Extend `apps/coa-gameplay-test/conformance/behaviours.py` and
`apps/coa-gameplay-test/conformance/kinds/peaceful_resurrect.py`
([doc](../../apps/coa-gameplay-test/conformance/docs/kinds/peaceful_resurrect.md)):

- Update `RESURRECT_EFFECTS = frozenset({18, 113})` in `behaviours.py`, and guard `cast_combat_scenario` so
  `resurrect_amounts=True` rejects non-`113` effects (including effect 18) with `ValueError` instead of misreading
  percentage points as flat health/mana.
- In `peaceful_resurrect.py`, detect `Effect == 18` (`SPELL_EFFECT_RESURRECT`) vs `Effect == 113`
  (`SPELL_EFFECT_RESURRECT_NEW`).
- For effect 18, measure `max_health_peaceful` and `max_power_peaceful` (power 0) on `ALLY` after resurrection and
  judge `health` / `mana` claims against unclamped `CalculatePct(maximum, BasePoints + DieSides)`. If `maximum <= 0`,
  return `unmeasured` so a zero-mana ally cannot vacuously pass a mana percentage claim.
- Add optional `ally_class: int | None = None` (validated `12..32`, CoA classes only) on `PeacefulResurrectSpec`.
- For effect 113 with `ally_class` omitted, generated scenarios, models, and verdicts remain byte-identical.

## Consequences

- Zero C++ changes and zero snapshot diff on finished classes (including Witch Doctor `803624`).
- Enables truthful conformance testing of effect-18 peaceful resurrections (including alerting on `803585`'s `820%`
  mismatch while passing valid `<= 100%` percentages such as rank 1 `801563`'s `70%`).
- Unit tests in `kinds/test_peaceful_resurrect.py` verify `Effect 18` scenario generation, `820%` unclamped alert,
  `70%` pass, zero-max `unmeasured`, missing measurement handling, and `ally_class` validation.
