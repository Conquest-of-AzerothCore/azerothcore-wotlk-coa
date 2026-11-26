# 1322. `block_charge_strikes` supports `require_block: false` for non-shield charge-consuming auras

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-26
- Rulings: Bloodmage Bucket 2 tool plan (`bm-tb1`, No Mercy `704660` on Thick Pelt `556233`)

## Context

In Bloodmage (class 20), *No Mercy* (`704660`) adds `+1` charge (`SPELL_AURA_ADD_FLAT_MODIFIER`, `SPELLMOD_CHARGES`)
to *Thick Pelt* (`556233`, `ProcCharges = 1`, `ProcFlags = 0x2a8` physical hits taken). Bloodmage cannot equip shields
(no Shield proficiency `9116`), and *Thick Pelt* consumes its charges on ordinary landed physical strikes (not blocked
strikes), with default `spell_proc` `AttributesMask = 0` requiring untriggered strikes.

Existing `kinds/block_charge_strikes.py` (ADR 1195) unconditionally learned `BLOCK_SPELL (107)`, equipped a `shield`,
forced `block: 100`, and asserted `spell_damage_count` with `blocked: True`.

## Options

- Create a separate kind duplicating the per-strike control/treatment charge-counting loop: rejected, because the
  mechanics (strike-by-strike aura presence and landed-hit verification against `ProcCharges` and `ProcCharges + extra`)
  are identical once shield/block forcing is parameterized.
- Add optional `require_block: bool = True`, `striker_untriggered: bool = False`, and `striker_auras: tuple[int, ...] = ()`
  to `BlockChargeSpec` in `kinds/block_charge_strikes.py`. Chosen.

## Decision

Extend `apps/coa-gameplay-test/conformance/kinds/block_charge_strikes.py` ([doc](../../apps/coa-gameplay-test/conformance/docs/kinds/block_charge_strikes.md)):

- Add optional `require_block: bool = True`, `striker_untriggered: bool = False`, and `striker_auras: tuple[int, ...] = ()`
  to `BlockChargeSpec`.
- When `require_block` is `False`, forbid `shield`, skip learning `BLOCK_SPELL (107)` and equipping a shield, set
  `set_combat_avoidance` to `dodge: 0, parry: 0, block: 0`, skip `set_power` when `cast_power == 0`, measure
  `spell_damage_count` without `blocked: True`, and report `hits` in contract and verdict wording.
- When `striker_untriggered` is `True`, pass `'triggered': False` on the striker's cast steps; when `striker_auras` is
  non-empty, set each listed fixture aura on `STRIKER` before the control arm (e.g., `803393` +100% hit chance so melee
  strikes never miss).
- When `require_block` is `True` (default) and optional striker fields are omitted, generated scenarios, models, and
  verdicts are byte-identical.

## Consequences

- Opt-in only; zero C++ changes and zero snapshot diff on finished classes.
- Proves Bloodmage No Mercy `704660` extending Thick Pelt `556233` from 1 hit to 2 hits without needing shield
  proficiency.
- Unit tests in `kinds/test_block_charge_strikes.py` verify scenario steps, `ok`/mutant/`unmeasured` verdicts, and
  option validation.
