-- Fix-o-Tron 5000 (item 97330, summon 92981): the summon spell and item survived, the creature it
-- summons (80879) did not, so the companion never appeared. Display 90773 (gnomebot2) is in the
-- server's own DBCs. Like Lil' Bangalash, it is a plain non-combat companion.

DELETE FROM `creature_template` WHERE `entry` = 80879;
INSERT INTO `creature_template`
(`entry`, `name`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`,
 `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`,
 `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`,
 `type`, `type_flags`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`,
 `RegenHealth`, `flags_extra`)
VALUES
(80879, 'Fix-o-Tron 5000', 1, 1, 0, 35, 0, 1, 1.14286,
 20, 0, 0, 1, 2000, 2000,
 1, 1, 1, 0, 0, 0, 0,
 12, 0, 1, 1, 1, 1,
 1, 0);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 80879;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(80879, 0, 90773, 1, 1);

DELETE FROM `creature_model_info` WHERE `DisplayID` = 90773;
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`) VALUES
(90773, 0.389, 1.5, 2);
