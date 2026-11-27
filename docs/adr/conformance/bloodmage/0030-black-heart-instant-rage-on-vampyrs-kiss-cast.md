# 0030. Owner ruling Q-bm-6: Black Heart grants 20% maximum Rage instantly on Vampyr's Kiss cast

- Status: accepted (owner ruling Bloodmage Q-bm-6 / O-10, 2026-11-26)
- Date: 2026-11-26

## Context

From server `Spell.dbc` (`/srv/coa/server-data/dbc`, `Description[enUS]`):
- Black Heart `680731`: "Your |cffffffffVampyr's Kiss|r now regenerates $681031s1% of your maximum Rage." (`$681031s1 = 20%`, from `681031` `Effect[0] = 137 SPELL_EFFECT_ENERGIZE_PCT`, `BasePoints = 19, DieSides = 1`, `MiscValue = 1 POWER_RAGE`, `TargetA = 1`).
- Vampyr's Kiss `504281` (Rank 7; rank chain `504275..504281` in `rev_20260831_01_local_spell_progression.sql`): "Curse an enemy, causing them to bleed for $o1 Shadow damage over $d$?s680731[ and instantly regenerate $805912s1% of your maximum Rage][]."

Previously, `bloodmage_kiss_periodic::OnPeriodicDamageResult` (`src/server/coa/AscensionBloodmageSecondary.cpp`) granted `player->ModifyPower(POWER_RAGE, int32(player->GetMaxPower(POWER_RAGE)) / 5)` on every replicated periodic tick instead of on cast. Conformance checks `680731 rage_on_cast` (`bloodmage.json [382]`) and `504281 black_heart_instant_rage` (`bloodmage.json [1006]`) alerted with `0` Rage at `1000 ms` after cast, while `black_heart_periodic_rage` (`[1007]`) confirmed `200` internal Rage arrived at the `5000 ms` periodic tick.

Archived live Ascension combat logs (`ev1.md`) confirmed `152/152` `681031 SPELL_ENERGIZE` events fired 1:1 on `Vampyr's Kiss` `SPELL_CAST_SUCCESS` (`0-7 ms` delta, never on the `633` periodic ticks), energizing `20%` max Rage across all August logs (`146/146`). The owner ruled (`Q-bm-6` / `O-10`, 2026-11-26): `fix_20_instant_edit_text` — switch server behavior to instant `20%` max Rage (`681031`) on cast of `Vampyr's Kiss` and align `504281`'s client text (`$805912s1` -> `$681031s1`) in the MPQ batch.

## Options

- Remove the periodic `ModifyPower` branch from `bloodmage_kiss_periodic::OnPeriodicDamageResult` and cast `SPELL_BLACK_HEART_ENERGIZE` (`681031`) inside `bloodmage_secondary_casts::OnSpellCast` before the `SPELL_NIGHT_HUNTER` early return whenever `!spell->IsTriggered() && RankOf(info->Id, SPELL_VAMPYRS_KISS) && player->HasAura(SPELL_BLACK_HEART)`. Chosen: uses the authentic DBC spell `681031`, emits proper `SPELL_ENERGIZE` combat-log events, and covers all 7 ranks (`504275..504281`) via `spell_ranks`.
- Call `ModifyPower` directly in `OnSpellCast`. Rejected: bypasses `681031` (`SPELL_EFFECT_ENERGIZE_PCT`) and omits `SPELL_ENERGIZE` spell events.

## Decision

In `src/server/coa/AscensionBloodmageSecondary.cpp`:
- Add `SPELL_BLACK_HEART_ENERGIZE = 681031` to `BloodmageSecondarySpells`.
- Delete the `SPELL_BLACK_HEART` Rage grant from `bloodmage_kiss_periodic::OnPeriodicDamageResult`.
- In `bloodmage_secondary_casts::OnSpellCast`, before the `SPELL_NIGHT_HUNTER` check, cast `SPELL_BLACK_HEART_ENERGIZE` on `player` when `!spell->IsTriggered() && RankOf(info->Id, SPELL_VAMPYRS_KISS) && player->HasAura(SPELL_BLACK_HEART)`.

No SQL, DBC, shared engine, or other-class files are changed.

## Consequences

- Casting any rank of Vampyr's Kiss (`504275..504281`) with Black Heart (`680731`) learned immediately energizes `20%` of maximum Rage (`200` internal Rage at `1000` max) via `681031`; replicated periodic ticks no longer grant Rage.
- Verification targets (executed in the coordinator's merged fix-wave build per `O-8`): `680731 rage_on_cast` (`[382]`), `504281 black_heart_instant_rage` (`[1006]`), and aligned `504281 black_heart_periodic_rage` (`[1007]`).
