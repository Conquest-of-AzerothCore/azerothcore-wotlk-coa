# 0035. Vampiric Fang removes Wretched from Essence Harvester

- Status: accepted (Bloodmage conformance fix wave S-20 / O-11, 2026-11-26)
- Date: 2026-11-26

## Context

From server `Spell.dbc` (`/srv/coa/server-data/dbc`, `Description[enUS]`):
- Essence Harvester `806421` -> Wretched `504284` (confirmed matching 2026-09-01 client archive `q742IyqxrV0.csv` `t=13:32`): "Generates $/10;504283s1 Rage and 1 stack of |cffffffffThirst|r every $t1 sec for $d. |cffffffffVampiric Fang|r removes this effect."

In `src/server/coa/AscensionBloodmageSecondary.cpp` (`bloodmage_secondary_casts::OnSpellHitResult`), the `IsVampiricFang(id)` block removed `SPELL_BLOOD_THIRST` (`706613`), `SPELL_INSATIABLE` (`706621`), and `SPELL_INSATIABLE_STACK` (`706663`), but omitted `504284` (`Wretched`). Conformance check `806421 vampiric_fang_removes_wretched` (`bloodmage.json [783]`) alerted because `504284` remained active after casting Vampiric Fang (`553272`).

## Options

- Add `SPELL_WRETCHED = 504284` to `BloodmageSecondarySpells` and call `player->RemoveAurasDueToSpell(SPELL_WRETCHED);` inside the existing `IsVampiricFang(id)` hit block in `bloodmage_secondary_casts::OnSpellHitResult`. Chosen: mirrors the existing `SPELL_BLOOD_THIRST` and `SPELL_INSATIABLE` cleanup and covers all 8 Vampiric Fang ranks (`804726, 504093..504097, 553271, 553272`).
- Add a separate `spell_proc` entry on `504284` with `Charges = 1` for Vampiric Fang. Rejected: unnecessary SQL overhead when Vampiric Fang already clears its related buffs in `OnSpellHitResult`.

## Decision

In `src/server/coa/AscensionBloodmageSecondary.cpp`, add `SPELL_WRETCHED = 504284` and call `player->RemoveAurasDueToSpell(SPELL_WRETCHED);` inside the `IsVampiricFang(id)` block of `bloodmage_secondary_casts::OnSpellHitResult`. No SQL, DBC, shared engine, or other-class files are changed.

## Consequences

- Landing any rank of Vampiric Fang removes Wretched (`504284`) from the Bloodmage alongside Thirst and Insatiable.
- Verification targets (executed in the coordinator's merged fix-wave build per `O-8`): `806421 vampiric_fang_removes_wretched` (`[783]`) and sibling `806421` Wretched checks (`[774]`, `[779..782]`).
