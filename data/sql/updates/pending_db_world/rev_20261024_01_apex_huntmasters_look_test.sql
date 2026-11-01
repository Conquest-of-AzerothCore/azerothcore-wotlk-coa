-- Apex Huntmaster look test: the two questgivers for the Skin-Peeler 9000 contract.
--
-- Both are mirror-image NPCs (docs/coa/npc-restoration.md): the base model is the plain
-- character display for the race/gender, and creature_display_preset supplies the paper-doll
-- the client asks for with CMSG_GET_MIRRORIMAGE_DATA. The module sets UNIT_FLAG2_MIRROR_IMAGE
-- itself for every entry that has a preset; type_flags 134217728 keeps the template in line.
--
-- Alliance: dwarf male, display 53, race 3, class 3 (Hunter), Beaststalker mail + Wolf Rider cloak.
-- Horde:    troll male, display 1478, race 8, class 3 (Hunter), Zandalar Predator / Blood Tiger /
--           Zulian cloak, no helm so the tusks and topknot show.
--
-- This is a look-test spawn only: no quests, gossip text or vendor list yet.

START TRANSACTION;

DELETE FROM `creature_template` WHERE `entry` IN (9916111, 9916112);
INSERT INTO `creature_template`
(`entry`,`difficulty_entry_1`,`difficulty_entry_2`,`difficulty_entry_3`,`KillCredit1`,`KillCredit2`,
 `name`,`subname`,`IconName`,`gossip_menu_id`,`minlevel`,`maxlevel`,`exp`,`faction`,`npcflag`,
 `speed_walk`,`speed_run`,`speed_swim`,`speed_flight`,`detection_range`,`rank`,`dmgschool`,
 `DamageModifier`,`BaseAttackTime`,`RangeAttackTime`,`BaseVariance`,`RangeVariance`,`unit_class`,
 `unit_flags`,`unit_flags2`,`dynamicflags`,`family`,`type`,`type_flags`,`lootid`,`pickpocketloot`,
 `skinloot`,`PetSpellDataId`,`VehicleId`,`mingold`,`maxgold`,`AIName`,`MovementType`,`HoverHeight`,
 `HealthModifier`,`ManaModifier`,`ArmorModifier`,`ExperienceModifier`,`RacialLeader`,`movementId`,
 `RegenHealth`,`CreatureImmunitiesId`,`flags_extra`,`ScriptName`,`VerifiedBuild`)
VALUES
(9916111,0,0,0,0,0,'Huntmaster Halda Bronzebraid','Apex Huntmaster',NULL,0,60,60,2,35,3,
 1,1.14286,1,1,20,0,0,1,2000,2000,1,1,1,0,2048,0,0,7,134217728,0,0,0,0,0,0,0,'',0,1,1,1,1,1,0,0,1,0,0,'',0),
(9916112,0,0,0,0,0,'Huntmaster Zul''khar','Apex Huntmaster',NULL,0,60,60,2,35,3,
 1,1.14286,1,1,20,0,0,1,2000,2000,1,1,1,0,2048,0,0,7,134217728,0,0,0,0,0,0,0,'',0,1,1,1,1,1,0,0,1,0,0,'',0);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (9916111, 9916112);
INSERT INTO `creature_template_model`
(`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`)
VALUES
(9916111,0,53,1,1,0),
(9916112,0,1478,1,1,0);

DELETE FROM `creature_display_preset` WHERE `entry` IN (9916111, 9916112);
INSERT INTO `creature_display_preset`
(`entry`,`display_id`,`race`,`gender`,`class`,`skin`,`face`,`hair`,`haircolor`,`facialhair`,`guild_id`,
 `item_head`,`item_shoulders`,`item_body`,`item_chest`,`item_waist`,`item_legs`,`item_feet`,`item_wrists`,`item_hands`,`item_back`,`item_tabard`)
VALUES
(9916111,53,   3,0,3,1,2,3,5,4,0, 31410,31409,0,31402,31404,31403,31408,31405,31406,27974,0),
(9916112,1478, 8,0,3,1,2,3,0,0,0,     0,32270,0,25682,32272,17153,27969,28806,27970,32371,0);

DELETE FROM `creature` WHERE `guid` IN (9916501, 9916502);
INSERT INTO `creature`
(`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,
 `position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,
 `currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,
 `ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`)
VALUES
(9916501,9916111,0,1519,10226,1,1,0, -8815.5,674.0,95.425,3.14,300,0,0,1,0,0,0,0,0,'',0,0,
 'Apex Huntmaster: Halda Bronzebraid, Stormwind Dwarven District'),
(9916502,9916112,1,1637,10229,1,1,0, 1633.5,-4433.0,15.76,3.14,300,0,0,1,0,0,0,0,0,'',0,0,
 'Apex Huntmaster: Zul''khar, Orgrimmar Valley of Honor');

COMMIT;
