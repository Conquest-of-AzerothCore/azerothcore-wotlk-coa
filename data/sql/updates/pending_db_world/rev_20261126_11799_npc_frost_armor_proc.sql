-- NPC Frost Armor (12544, cast out of combat by Razormane Geomancer 3269 at Thorn Hill and 121 other NPCs)
-- lacked a spell_proc row, so SpellMgr::LoadSpellProcs generated SpellTypeMask = PROC_SPELL_TYPE_MASK_ALL (7).
-- Non-damaging melee spells without SPELL_ATTR3_SUPPRESS_CASTER_PROCS (Ranger Blackjack 520568, Rogue Sap 6770)
-- procced Chilled (6136), stripping stealth (#11799). Match player Frost Armor (-168), Ice Armor (-7302), and
-- Molten Armor (-30482): SpellTypeMask = 1 (PROC_SPELL_TYPE_DAMAGE), HitMask = 1027 (NORMAL|CRITICAL|ABSORB),
-- AttributesMask = 2 (PROC_ATTR_TRIGGERED_CAN_PROC).
DELETE FROM `spell_proc` WHERE `SpellId` = 12544;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
  `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
  `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(12544, 0, 0, 0, 0, 0, 0, 1, 0, 1027, 2, 0, 0, 0, 0, 0);
