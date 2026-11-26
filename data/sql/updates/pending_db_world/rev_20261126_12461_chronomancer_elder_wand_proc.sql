-- Elder Wand (560129): "Your Wand attacks now have a $h% chance to increase the damage of Artificer's
-- Wand against the target by $560128s1% for $560128d, stacking $560128u times." (#12461)
--
-- rev_20260919_60_chronomancer_elder_wand_proc.sql masked SpellFamilyMask2 to 512 (Artificer's Wand
-- 561064) with AttributesMask = 0. Across Spell.dbc (SpellFamilyName = 28, DmgClass = 3) and live
-- Ascension combat logs, two additional Chronomancer wand attacks also proc Elder Wand (560128):
-- Crystal Cannon (704481 -> periodic-triggered 560134, SpellFamilyFlags[2] = 4096, without
-- SPELL_ATTR3_NOT_A_PROC so it also requires PROC_ATTR_TRIGGERED_CAN_PROC = 2, matching
-- rev_20261031_98_chronomancer_resonance_crystal_cannon.sql) and Shatter Echo (804503/807950-807953/
-- 572417, SpellFamilyFlags[2] = 20). Combined SpellFamilyMask2 = 512 | 4096 | 20 = 4628;
-- Singularity Core (804437, SpellFamilyFlags[0] = 1024) stays excluded, and Chance remains 30.
UPDATE `spell_proc`
SET `SpellFamilyMask2` = 4628,
    `AttributesMask` = `AttributesMask` | 2
WHERE `SpellId` = 560129;
