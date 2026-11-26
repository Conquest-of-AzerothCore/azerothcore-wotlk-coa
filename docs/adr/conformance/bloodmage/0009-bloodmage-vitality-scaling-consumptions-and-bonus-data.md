# 0009. Bloodmage vitality consumptions, Torture leech, stat scaling, raid groups, and bonus data

- Status: accepted (Bloodmage fix-wave Lot 1, incl. owner ruling Q-bm-3 / O-10, 2026-11-26; provisional number)
- Date: 2026-11-26

## Context

Batch 2–4 Bloodmage conformance sweeps and live combat-log audits (`ev1.md`–`ev4.md`) surfaced a cluster of clear
vitality, scaling, raid-buff exclusivity, and `spell_bonus_data` defects:

1. **Sovereignty `806049` / `504272` consumption (`S-6b`, `ev3.md`)**: `504272` has `ProcCharges = 0`, so
   `Player::RemoveSpellMods` (`Player.cpp:10902`) never consumed it on Bloodbolt cast (`806049 cost next` alerted `0` vs
   `85`). Live logs proved `504272` is removed at `0.0 ms` on Bloodbolt `SPELL_CAST_SUCCESS` (`78/86` in `log 149`,
   `709/748` in `log 150`, `13/17` in `log 88`).
2. **Torture `504071` / `804934` Vampiric Feast leech (`S-19`, `ev4.md`)**: `504071` `Effect[0]` (`+50%` on `804934`)
   was ignored because `804934` intentionally sets `SPELL_ATTR3_IGNORE_CASTER_MODIFIERS` so Transgression's `20%`
   damage-derived leech does not double-dip damage/SP modifiers (`504071 vampiric_feast_leech` measured `0.50` vs
   expected `0.75`).
3. **Bloodthorns `802313` / `572116` SP scaling without double-dip (`Q-bm-3`, `O-10`)**: Owner ruled `sp_only_edit_text`
   (`+0.035` Shadow SP, no `0.5 s` ICD). However, `SpellAuraEffects.cpp:627` runs `SpellDamageBonusDone` when applying
   `SPELL_AURA_DAMAGE_SHIELD` AND `Unit::DealDamageShieldDamage` (`Unit.cpp:2367`) calls `SpellDamageBonusDone` a second
   time on hit, which would double-dip `+0.035 * SP` to `+0.070 * SP` (`92` vs expected `57` at `1000` SP on `501667`).
4. **Missing stat terms in `bloodmage_vitality_scaling::ModifySpellEffectBaseValue` (`ev3.md`, `ev4.md`)**:
   - `704119` Blood Rituals: tooltip `${$704119m1+$704119ppl1+$BH*0.07+$STA*0.085}` lacked `+$STA*0.085`.
   - `520315` Heartbreak ally heal: tooltip `${$m3+0+$BH*.3+$spi*1}` lacked `+$spi*1` (live heals `926..2268` vs `423`).
   - `560589` Enraging Wounds: tooltip `${$560589m1*$<scalingbp>+$STA*0.3}` lacked `+$STA*0.3`.
   - `536277` Shadow Strength: tooltip `${$536277m1+$536277ppl1+$STA*.25+$AGI*.25+$AP*.1}` lacked `+$STA*0.25+$AGI*0.25`.
5. **Missing raid-buff `spell_group` exclusivity (`ev3.md`)**: `582766` Fleshbending (`+5%` raid crit, replaced `42`
   times with `0` overlap by `500264` in live `log 88`) was absent from `spell_group 2000181`, and `685029` Blood-Cursed
   Weapons (`+5%` raid haste) was absent from `spell_group 2000182`.
6. **Missing `spell_bonus_data` coefficients (`spec-core.md` §11.B, `ev3.md`, `ev4.md`)**: `704119`, `504291`, `504101`,
   `680744`, `524180`, `704120`, `681082`, `681310`, `520315`, `802313`, `572116`, `536277`, `800775`, `803392`,
   `800786`, and `520312` had `EffectBonusMultiplier = 0` and no `spell_bonus_data` rows (verified zero conflicts in
   `data/sql/updates/pending_db_world/`).

## Options

- Implement all Bloodmage vitality/scaling/consumption/double-dip guards cleanly in
  `src/server/coa/AscensionBloodmageVitality.cpp` and add all idempotent `spell_group` and `spell_bonus_data` rows in
  `data/sql/updates/pending_db_world/rev_20261127_01_bloodmage_core_and_bonuses.sql`. Chosen: keeps `Unit.cpp` and
  `SpellAuraEffects.cpp` untouched (`Q-bm-17`), avoids `SPELL_AURA_DAMAGE_SHIELD` SP double-dipping via
  `UNITHOOK_ON_AFTER_AURA_EFFECT_CALCULATE_AMOUNT` restoring `effect->GetOldAmount()` (which also preserves
  `bloodmage-bloodthorns-damage-4151.json` `aura_amount == 10`), and aligns all 16 missing coefficients in one idempotent
  SQL migration.
- Strip `SPELL_ATTR3_IGNORE_CASTER_MODIFIERS` from `804934` for Torture or edit `SpellAuraEffects.cpp:627` for
  Bloodthorns. Rejected: stripping `IGNORE_CASTER_MODIFIERS` breaks `804934`'s base damage-derived leech scaling, and
  editing `SpellAuraEffects.cpp` affects every damage shield across all classes.

## Decision

1. In `bloodmage_vitality_casts::OnSpellCast` (`src/server/coa/AscensionBloodmageVitality.cpp`), before the
   `PooledVitality` early return, remove `504272` Sovereignty whenever `GetEmpowerment(info->Id) == Bloodbolt`.
2. In `bloodmage_vitality_scaling::ModifyHealReceived`, when `spellInfo->Id == 804934 && first == second && first` and
   the Bloodmage carries `504071` Torture `EFFECT_0`, call `AddPct(heal, torture->GetAmount())`.
3. In `bloodmage_vitality_scaling::OnAfterAuraEffectCalculateAmount`, for `SPELL_AURA_DAMAGE_SHIELD` on family-26
   Bloodthorns (`802313` chain via `GetFirstSpellInChain`) and Greater Bloodthorns (`572116`), restore
   `amount = effect->GetOldAmount()` so `Unit::DealDamageShieldDamage` applies `+0.035 * SP` exactly once.
4. In `bloodmage_vitality_scaling::ModifySpellEffectBaseValue`, add cumulative stat scaling for `704119` (`+0.085*STA`),
   `520315` (`+1.0*SPI`), `560589` (`+0.3*STA`), and `536277` (`+0.25*STA + 0.25*AGI`).
5. In `data/sql/updates/pending_db_world/rev_20261127_01_bloodmage_core_and_bonuses.sql`, add idempotent `DELETE`/`INSERT`
   rows for `spell_group` (`(2000181, 582766)`, `(2000182, 685029)`) and all 16 `spell_bonus_data` entries (`704119`,
   `504291`, `504101`, `680744`, `524180`, `704120`, `681082`, `681310`, `520315`, `802313`, `572116`, `536277`,
   `800775`, `803392`, `800786`, `520312`).

## Consequences

- Sovereignty consumes cleanly on every cast Bloodbolt; Torture raises Vampiric Feast leech from `0.50` to `0.75`;
  Bloodthorns and Greater Bloodthorns scale once at `+0.035 * SP` while keeping base `aura_amount` intact; Fleshbending
  and Blood-Cursed Weapons enforce raid-buff exclusivity; and all 16 Bloodmage abilities receive their tooltip SP/BH/AP
  and stat scaling.
- Post-fix build and runtime verification across all touched conformance entries and `bloodmage-bloodthorns-damage-4151.json`
  run after the fix-wave merge build (`O-8`).
