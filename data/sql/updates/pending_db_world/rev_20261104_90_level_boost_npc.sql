-- Level boost NPC for test realms: script npc_coa_level_boost (src/server/coa/CoALevelBoostNpc.cpp).
-- Its gossip only offers the boost when the realm sets CoA.LevelBoostNpc.Enable = 1; nothing spawns it.
DELETE FROM `creature_template` WHERE `entry` = 9990500;
INSERT INTO `creature_template`
 (`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`exp`,`faction`,`npcflag`,
  `speed_walk`,`speed_run`,`rank`,`unit_class`,`unit_flags`,`type`,`type_flags`,
  `AIName`,`MovementType`,`HealthModifier`,`ManaModifier`,`ArmorModifier`,`RegenHealth`,`flags_extra`,`ScriptName`)
VALUES
 (9990500,'Test Realm Mentor','Level Boost',60,60,0,35,1,
  1,1.14286,1,1,2,7,0,
  '',0,1.5625,1,1,1,2,'npc_coa_level_boost');

DELETE FROM `creature_template_model` WHERE `CreatureID` = 9990500;
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`)
VALUES (9990500,0,12923,1,1);

DELETE FROM `npc_text` WHERE `ID` IN (9990500, 9990501);
INSERT INTO `npc_text` (`ID`,`text0_0`,`text0_1`,`Probability0`) VALUES
 (9990500,'This realm is for testing, $n. I can raise you to the highest level we test at, so you can get straight to it.',
          'This realm is for testing, $n. I can raise you to the highest level we test at, so you can get straight to it.',1),
 (9990501,'I have nothing to offer you on this realm, $n.',
          'I have nothing to offer you on this realm, $n.',1);
