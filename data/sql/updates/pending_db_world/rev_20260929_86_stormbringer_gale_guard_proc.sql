-- #5277 Stormbringer skill not working (Gale Guard knockback)
--
-- Gale Guard (500923) tooltip: "enemies who damage you [are] struck with a gust of wind and knocked back...
-- Lasts for $d or 3 attacks." It carries a live SPELL_AURA_PROC_TRIGGER_SPELL (aura 42) effect
-- (EffectTriggerSpell 504872, the knockback), but Spell.dbc gives it ProcFlags 0 and no `spell_proc` row
-- exists, so SpellMgr::LoadSpellProcs skips it and the aura never fires: no knockback on any hit taken,
-- matching "does nothing at all when hit in melee." Spell.dbc's own ProcCharges is 0 (unlimited), so the
-- tooltip's "3 attacks" clause is encoded here via `Charges`. Chance stays 0 so the record's own DBC
-- ProcChance (100) is used, per rev_20260919_20_coa_proc_chance_parity.sql.
START TRANSACTION;

DELETE FROM `spell_proc` WHERE `SpellId` = 500923;
INSERT INTO `spell_proc`
    (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`,
     `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`,
     `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
    (500923, 0, 0, 0, 0, 0, 1048576, 0, 0, 0, 0, 0, 0, 0, 0, 3);

COMMIT;
