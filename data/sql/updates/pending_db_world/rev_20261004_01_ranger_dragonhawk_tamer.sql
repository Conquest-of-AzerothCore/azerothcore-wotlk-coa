-- Dragonhawk Tamer 573056: one 15-second guardian for each successful Horn cast (#2174).
-- Family 27 mask (0,0,1) selects the four active Horns; CAST phase avoids party-target duplication.
DELETE FROM `spell_proc` WHERE `SpellId` = 573056;
INSERT INTO `spell_proc`
(`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`,
 `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`,
 `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES (573056, 0, 27, 0, 0, 1, 16384, 0, 1, 0, 0, 0, 0, 0, 0, 0);

-- Preserved CoA beta creature cache: 52393 Dragonhawk, Beast, display 17545, health/mana modifiers 1.
-- ascension-data snapshot 371f9d8db5a9d987f41be19b91fb87873d75654780243c9bd21c110852be0424.
-- The existing Ranger companion hook supplies owner-level weapon damage and attack power.
INSERT INTO `creature_template`
(`entry`, `name`, `minlevel`, `maxlevel`, `exp`, `faction`, `unit_class`, `type`, `BaseAttackTime`, `RangeAttackTime`)
VALUES (52393, 'Dragonhawk', 1, 1, 0, 35, 1, 1, 2000, 2000)
ON DUPLICATE KEY UPDATE `entry` = `entry`;
DELETE FROM `creature_template_model` WHERE `CreatureID` = 52393;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES (52393, 0, 17545, 1, 1);
