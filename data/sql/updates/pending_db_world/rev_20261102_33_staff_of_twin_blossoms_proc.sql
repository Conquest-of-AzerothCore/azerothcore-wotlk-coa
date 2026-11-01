-- Staff of Twin Blossoms never procced (#10712): its equip spells Blossoming growth Dummy proc 202827 (item 515201) and
-- 312770 (upgraded item 1379194) carry DBC ProcFlags 0 and the world had no spell_proc rows, so the auras never
-- registered a proc handler. The tooltips promise a chance on direct damage and healing spells: grant the landed
-- done-spell masks of every damage class, positive and negative (87312), damage and heal spells at the hit phase,
-- with the DBC ProcChance of 10. Periodic ticks are not proc events (the tooltips say direct). Only the upgraded
-- tooltip names an internal cooldown (40 sec).
DELETE FROM `spell_proc` WHERE `SpellId` IN (202827, 312770);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(202827, 0, 0, 0, 0, 0, 87312, 3, 2, 0, 0, 0, 0, 10, 0, 0),
(312770, 0, 0, 0, 0, 0, 87312, 3, 2, 0, 0, 0, 0, 10, 40000, 0);
