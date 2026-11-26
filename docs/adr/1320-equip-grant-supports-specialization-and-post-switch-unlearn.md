# 1320. `equip_grant` accepts `specialization` and `unlearn_after_specialization` for specialization-taught weapon grants

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-26
- Rulings: Bloodmage Bucket 2 tool plan (`bm-tb1`, Eternal Curse `92114` Dual Wield grant)

## Context

In Bloodmage (class 20), *Eternal Curse* (`92114`) is an auto-learned level-10 specialization passive for the Eternal
specialization (`specialization: 99`, `AscensionTaughtAbilityData.h:32-33`: teaches *Eternal Curse* `800157` and
*Dual Wield* `674`; `AscensionCompat.cpp:1132-1141` sets `player->SetCanDualWield(player->HasSpell(674))`).

Existing `kinds/equip_grant.py` (ADR 1198) only ran `unlearn spec.spell` before testing the refused off-hand equip and
then `learn spec.spell` before testing the accepted off-hand equip, with no specialization switch or post-switch
cleanup. Without switching to specialization 99, learning `92114` does not satisfy `specializationId == entry.SpecId`
in `SynchronizeTaughtAbilities` (`AscensionCompat.cpp:1116`), so `674` is never taught and dual wield is never granted;
conversely, switching to specialization 99 auto-learns `92114`, `800157`, and `674`, which must be unlearned before
the refused off-hand control arm.

## Options

- Re-test dual wield with `metric_delta` `knows_spell` on `674`: rejected, because `knows_spell` is a state check and
  does not prove the equip handler itself refuses the off-hand weapon without the grant and accepts it with the grant.
- Extend `EquipGrantSpec` in `kinds/equip_grant.py` with optional `specialization` and `unlearn_after_specialization`
  mirroring `metric_delta_options/specialization.py` and `metric_delta_options/unlearn_after_specialization.py`. Chosen.

## Decision

Extend `apps/coa-gameplay-test/conformance/kinds/equip_grant.py` ([doc](../../apps/coa-gameplay-test/conformance/docs/kinds/equip_grant.md)):

- Add optional `specialization: int | None = None` (`1..0xFFFF`) and `unlearn_after_specialization: tuple[int, ...] = ()`
  (non-empty distinct positive spell IDs, requiring `specialization` when provided) to `EquipGrantSpec` and
  `equip_grant_spec`.
- In `equip_grant_scenario`, when `spec.specialization is not None`, prepend
  `{'action': 'money', 'actor': CASTER, 'copper': 1000000}` and
  `{'action': 'specialization', 'actor': CASTER, 'id': spec.specialization}` before the `unlearned` arm, then unlearn
  each spell in `spec.unlearn_after_specialization` (or `spec.spell` when omitted) before testing the refused off-hand
  equip and post-learn accepted off-hand equip.
- When both fields are omitted, generated steps, contract, model, and expectations are byte-identical.

## Consequences

- Opt-in only; zero C++ changes and zero snapshot diff on finished classes.
- Proves Bloodmage Eternal Curse `92114` dual-wield grant directly through the server's equip handler (`equip_grant`).
- Unit tests in `kinds/test_equip_grant.py` verify step order, default identity, verdict behaviour, and validation
  refusals.
