# 0034. Bloodsores consumption on Sanguine Rupture and Bloodmoon Blast with Blood Lord retention

- Status: accepted (Bloodmage conformance fix wave S-6a / O-11, 2026-11-26)
- Date: 2026-11-26

## Context

From server `Spell.dbc` (`/srv/coa/server-data/dbc`, `Description[enUS]`):
- Bloodsores `805591` -> debuff Bloodsore `805592`: "Increases the damage of your next |cffffffffSanguine Rupture|r and |cffffffffBloodmoon Blast|r against the target by $s1% for $d, stacking $u times." (`Effect[0]` aura `271 SPELL_AURA_MOD_DAMAGE_FROM_CASTER`, `+10%/stack`, `StackAmount = 5`, `DurationIndex = 31` = `8000 ms`, `EffectSpellClassMask = [0, 2105344, 0]` covering `800775` Sanguine Rupture damage and all 10 Bloodmoon Blast ranks `SpellFamilyFlags[1] & 0x2000`, `ProcFlags = 0`, `ProcCharges = 0`).
- Blood Lord `704636` (Rank 1) / `707866` (Rank 2): "Grants your |cFFFFFFFFBloodsore|r a $s1% chance to provide its benefits without being consumed." (`Effect[0]` aura `107`, `BasePoints = -16, DieSides = 1` -> `-15` for R1; `BasePoints = -31, DieSides = 1` -> `-30` for R2).

Because `805592` has `ProcFlags = 0` and `ProcCharges = 0` in `Spell.dbc` and no consumption handler existed, `805592` remained active on the target after Bloodmoon Blast and Sanguine Rupture hits. Conformance checks `805591 consume_on_blast` (`[372]`) and `704636`/`707866 bloodsore_control_consume` (`[457]`, `[458]`) alerted (`1` vs expected `0`). Archived live Ascension combat logs (`ev3.md`) confirmed `805592` is removed in full at `0 ms` on `800775` / Bloodmoon Blast hits (`148/148` = `100%` without Blood Lord; `239/273` = `87.55%` consumed with ~15% retention under Blood Lord R1).

## Options

- Consume `805592` in `bloodmage_secondary_casts::OnSpellHitResult` (`src/server/coa/AscensionBloodmageSecondary.cpp`) before the `spell->IsTriggered()` early return (since `800775` Sanguine Rupture damage is triggered by `572907`), checking `miss == SPELL_MISS_NONE && target && info->SpellFamilyName == 26 && (info->Id == 800775 || (info->SpellFamilyFlags[1] & 0x2000))` and rolling `std::abs(amount)` from `707866` (30%) or `704636` (15%) to decide whether to retain `805592`. Chosen: `Spell.cpp:3069` invokes `OnSpellHitResult` after `DoSpellHitOnUnit` has already applied `805592`'s `+10%/stack` damage bonus, handles both triggered `800775` and direct Bloodmoon Blast ranks per target hit, and requires no SQL or shared engine changes.
- Add a `spell_proc` row on `805592` with `Charges = 1`. Rejected: cannot naturally gate non-consumption on Blood Lord's `15%/30%` passive `SPELLMOD_CHANCE_OF_SUCCESS` without a separate AuraScript, and multi-stack removal is cleaner directly in `OnSpellHitResult`.

## Decision

In `src/server/coa/AscensionBloodmageSecondary.cpp`:
- Add `SPELL_BLOODSORES_DEBUFF = 805592`, `SPELL_BLOOD_LORD_R1 = 704636`, `SPELL_BLOOD_LORD_R2 = 707866`, and `SPELL_SANGUINE_RUPTURE_DAMAGE = 800775` to `BloodmageSecondarySpells`.
- In `bloodmage_secondary_casts::OnSpellHitResult`, before `if (spell->IsTriggered()) return;`, when `miss == SPELL_MISS_NONE && target && info->SpellFamilyName == 26 && (info->Id == SPELL_SANGUINE_RUPTURE_DAMAGE || (info->SpellFamilyFlags[1] & 0x2000))`, look up `target->GetAura(SPELL_BLOODSORES_DEBUFF, player->GetGUID())` and remove it unless Blood Lord (`707866` then `704636`) rolls `std::abs(lord->GetAmount())`.

No SQL, DBC, shared engine, or other-class files are changed.

## Consequences

- Hitting a Bloodsore-afflicted enemy with Sanguine Rupture (`800775`) or any Bloodmoon Blast rank (`500125, 501607..501614, 572332`) applies the full stacked `+10%/stack` damage bonus and then removes `805592` unless Blood Lord Rank 1 (`15%`) or Rank 2 (`30%`) retains it.
- Verification targets (executed in the coordinator's merged fix-wave build per `O-8`): `805591 consume_on_blast` (`[372]`), `805591 sanguine_rupture` (`[370]`), `805591 bloodmoon_blast` (`[371]`), and `704636`/`707866 bloodsore_control_consume` (`[457]`, `[458]`).
