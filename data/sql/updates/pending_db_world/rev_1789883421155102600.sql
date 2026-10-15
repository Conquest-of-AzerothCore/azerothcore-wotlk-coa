--
-- Bash (#613): successful melee auto-attacks trigger the authored weapon-damage and one-second stun helper.
-- Tilling the Earth's native chance modifier remains responsible for its talent bonus (#611).
DELETE FROM `spell_proc` WHERE `SpellId` = 680964;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(680964, 0, 0, 0, 0, 0, 4, 0, 0, 3, 0, 0, 0, 30, 0, 0);
