-- The user's in-game dressing of the Snowsong Valley watchtower ("Light's Warmth"), 2026-10-16: outfits, faces and hair
-- of Sister Sarah and the human and dwarf Exhausted Refugees, the refugees' and Soldier Rulven's poses, and the two
-- refugees added by the east fire removed again.
DELETE FROM `creature_display_preset` WHERE `entry` IN (164067, 164068, 164069, 164541);
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(164067,54,3,1,1,3,9,5,7,3,0,11960,0,0,9706,0,22147,7769,26447,15993,0,0),
(164068,49,1,0,1,3,8,4,1,7,0,0,0,0,5967,0,22147,0,26447,86103,0,0),
(164069,49,1,0,1,3,8,4,1,7,0,0,0,147821,5202,11159,54948,71206,0,0,0,0),
(164541,53,3,0,1,3,8,3,1,7,0,0,0,0,12251,0,22147,44845,26447,15993,0,0);
DELETE FROM `creature_equip_template` WHERE `CreatureID` IN (164067, 164068, 164069, 164541);
DELETE FROM `creature_addon` WHERE `guid` IN (9981398, 9981399, 9981400, 9981401, 9981402, 9981403, 9981404, 9981406, 9981407, 9981408, 9981409, 9981410, 9981411);
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(9981399,0,0,8,1,0,0,''),
(9981400,0,0,3,1,0,0,''),
(9981401,0,0,3,1,0,0,''),
(9981402,0,0,1,1,0,0,''),
(9981403,0,0,1,1,0,0,''),
(9981404,0,0,3,1,0,0,''),
(9981406,0,0,1,1,0,0,NULL),
(9981407,0,0,1,1,0,0,''),
(9981408,0,0,8,1,0,0,''),
(9981409,0,0,3,1,0,0,''),
(9981410,0,0,8,1,0,0,''),
(9981411,0,0,3,1,0,0,'');
DELETE FROM `creature_addon` WHERE `guid` IN (9965158, 9965159);
DELETE FROM `creature` WHERE `guid` IN (9965158, 9965159);
