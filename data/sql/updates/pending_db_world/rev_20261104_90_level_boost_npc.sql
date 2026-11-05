INSERT INTO `creature_template`
 (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`exp`,`faction`,`npcflag`,
  `speed_walk`,`speed_run`,`rank`,`unit_class`,`unit_flags`,`type`,`type_flags`,
  `AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`,`flags_extra`,`ScriptName`)
VALUES
 (9990500,'Test Realm Mentor','Level Boost',60,60,0,35,1,
  1,1.14286,1,1,2,7,0,
  '',0,1.5625,1,1,1,2,'npc_coa_level_boost')
ON DUPLICATE KEY UPDATE
 `name` = VALUES(`name`), `subname` = VALUES(`subname`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`),
 `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`),
 `speed_run` = VALUES(`speed_run`), `rank` = VALUES(`rank`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`),
 `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`),
 `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`),
 `RegenHealth` = VALUES(`RegenHealth`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 9990500;
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`)
VALUES (9990500,0,12923,1,1);

DELETE FROM `npc_text` WHERE `ID` IN (9990500, 9990501);
INSERT INTO `npc_text` (`ID`,`text0_0`,`text0_1`,`Probability0`) VALUES
 (9990500,'This realm is for testing, $n. I can raise you to the highest level we test at, so you can get straight to it.','This realm is for testing, $n. I can raise you to the highest level we test at, so you can get straight to it.',1),
 (9990501,'I have nothing to offer you on this realm, $n.','I have nothing to offer you on this realm, $n.',1);
