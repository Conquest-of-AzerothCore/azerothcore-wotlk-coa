-- Rock Barrier (#5037): stacks never decrement and no Geode is launched.
--
-- Description[enUS]: "Raise rocks from beneath you, increasing your Armor by ${$m1+$STA*3}, scaling with
-- your Stamina. Lasts for $n attacks or $d. Expending a charge of Rock Barrier launches a Geode at the
-- enemy." EFFECT_2 is SPELL_AURA_PROC_TRIGGER_SPELL (EffectTriggerSpell 804002, the Geode) with DBC
-- ProcCharges 10 and ProcChance 100. No `spell_proc` row existed for 503630 in
-- data/sql/base/db_world/spell_proc.sql or any pending update, so SpellMgr::LoadSpellProcs never populated
-- mSpellProcMap for it and the charge-consuming proc could never fire, matching the report ("stack count
-- stays the same and geodes are not launched"). ProcFlags is 0x100000 = 1048576 (PROC_FLAG_TAKEN_DAMAGE,
-- SpellMgr.h:142), the same flag used for the "attacks" wording on Borrowed Time's own reactive shield
-- (rev_20260919_62_chronomancer_borrowed_time_proc.sql); SchoolMask stays 0 since the tooltip does not
-- restrict the triggering school. Chance and Charges stay 0 so LoadSpellProcs falls back to the DBC
-- record's own ProcChance (100) and ProcCharges (10).
DELETE FROM `spell_proc` WHERE `SpellId` = 503630;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(503630, 0, 0, 0, 0, 0, 1048576, 0, 0, 0, 0, 0, 0, 0, 0, 0);
