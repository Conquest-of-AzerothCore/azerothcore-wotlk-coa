-- Bloodtooth Neck never procced (#11815, #12236, #13157, #13313): its equip dummies carry Spell.dbc ProcFlags 0 and
-- the world had no spell_proc row, so SpellMgr::LoadSpellProcs skipped them and Aura::GetProcEffectMask never
-- rolled. Tooltip: "Your ranged or melee attacks" (base) and "Ranged and Melee attacks ... (25sec. internal
-- cooldown)" (tiers). Flags 340 (melee and ranged auto attacks and abilities) as the merged T1 Shaman 3-piece row
-- for "Attacks". Chance from each record: 10 base, 7 tiers (the tier tooltip text reads 10%; the PR author ruled
-- for the record). Chance stays 0 so the loader uses each record's own ProcChance.
DELETE FROM `spell_proc` WHERE `SpellId` IN (303045, 312841, 316841, 320841);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
  `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
  `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(303045, 0, 0, 0, 0, 0, 340, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(312841, 0, 0, 0, 0, 0, 340, 1, 2, 0, 0, 0, 0, 0, 25000, 0),
(316841, 0, 0, 0, 0, 0, 340, 1, 2, 0, 0, 0, 0, 0, 25000, 0),
(320841, 0, 0, 0, 0, 0, 340, 1, 2, 0, 0, 0, 0, 0, 25000, 0);
