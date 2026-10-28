-- Apex Bounty: The Stormfang
-- First pass of the Stormfang open-world encounter.
--
-- Custom base spells are used where they exist; the only native fallbacks are
-- Howl of Terror (5484) and Pounce (9005).
--
-- This slice creates the creature, its Hinterlands spawn, yells and SmartAI.
-- Quest contracts, bounty tracks, carcasses and hides are intentionally left
-- for the next Apex update.

START TRANSACTION;

-- ---------------------------------------------------------------------------
-- Creature templates
-- ---------------------------------------------------------------------------

DELETE FROM `creature_template` WHERE `entry` IN (9916201, 9916202);
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
-- The Stormfang: level 60 elite worg, custom Lightning Worg display 68899.
(9916201,0,0,0,0,0,'The Stormfang','Apex Bounty',NULL,0,60,60,2,16,0,
 1,1.14286,1,1,20,3,0,1.2,2000,2000,1,1,1,
 0,0,0,1,1,0,0,0,0,0,0,0,0,'SmartAI',1,1,12,1,1,1,0,0,1,0,0,'',0),
-- Storm Conduit: summoned lightning elemental add. Custom display 409947.
(9916202,0,0,0,0,0,'Storm Conduit','Apex Bounty',NULL,0,60,60,2,16,0,
 1,1.14286,1,1,20,1,0,1,2000,2000,1,1,1,
 0,0,0,0,4,0,0,0,0,0,0,0,0,'SmartAI',0,1,1,1,1,1,0,0,1,0,0,'',0);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (9916201, 9916202);
INSERT INTO `creature_template_model`
(`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`)
VALUES
(9916201,0,68899,1.0,1,0),
(9916202,0,409947,0.8,1,0);

-- ---------------------------------------------------------------------------
-- Hinterlands spawn: The Overlook, near the wild owlbeast/wolf line.
-- ---------------------------------------------------------------------------

DELETE FROM `creature` WHERE `guid` = 9916503;
INSERT INTO `creature`
(`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,
 `position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,
 `currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,
 `ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`)
VALUES
(9916503,9916201,0,47,0,1,1,0,
 -155.771,-2879.57,117.037,0,3600,6,
 0,1,0,1,0,0,0,
 '',0,0,'Apex Bounty: The Stormfang, The Overlook, Hinterlands');

-- ---------------------------------------------------------------------------
-- Creature text
-- ---------------------------------------------------------------------------

DELETE FROM `creature_text` WHERE `CreatureID` IN (9916201, 9916202);
INSERT INTO `creature_text`
(`CreatureID`,`GroupID`,`ID`,`Text`,`Type`,`Language`,`Probability`,`Emote`,`Duration`,`Sound`,`BroadcastTextId`,`TextRange`,`comment`)
VALUES
(9916201,0,0,'The storm answers the scent of blood.',14,0,100,0,0,0,0,0,'Stormfang aggro'),
(9916201,1,0,'You cannot outrun the thunder.',14,0,100,0,0,0,0,0,'Stormfang phase 2'),
(9916201,2,0,'Overcharge! The hunt ends here.',14,0,100,0,0,0,0,0,'Stormfang phase 3'),
(9916201,3,0,'The storm... fades...',14,0,100,0,0,0,0,0,'Stormfang death'),
(9916201,4,0,'Feel the storm in your bones!',14,0,100,0,0,0,0,0,'Stormfang Thunder Howl');

-- ---------------------------------------------------------------------------
-- SmartAI -- The Stormfang
--
-- Phase masks: 1 = phase 1, 2 = phase 2, 4 = phase 3.
-- Event 0 = update in combat (initial min/max, repeat min/max).
-- Event 2 = health percent. Event 4 = aggro. Event 6 = death. Event 25 = reset.
-- Action 1 = talk, 10 = random emote, 11 = cast, 12 = summon, 22 = set phase.
-- Target 1 = self, 2 = victim, 5 = random hostile, 6 = random hostile not top.
-- ---------------------------------------------------------------------------

DELETE FROM `smart_scripts` WHERE `entryorguid` IN (9916201, 9916202) AND `source_type` = 0;
INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,
 `event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`event_param6`,
 `action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,
 `target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,
 `target_x`,`target_y`,`target_z`,`target_o`,`comment`)
VALUES
-- Aggro
(9916201,0,1,0,4,0,100,0,0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Stormfang - aggro yell'),
(9916201,0,2,0,4,0,100,0,0,0,0,0,0,0,22,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Stormfang - enter phase 1'),

-- Phase 1 timers
(9916201,0,10,0,0,1,100,0,5000,5000,12000,12000,0,0,11,102946,0,0,0,0,0,5,40,1,0,0,0,0,0,0,'Stormfang - Chain Lightning'),
(9916201,0,11,0,0,1,100,0,8000,8000,15000,15000,0,0,11,9005,0,0,0,0,0,6,40,1,0,0,0,0,0,0,'Stormfang - Static Pounce (native Pounce fallback)'),
(9916201,0,12,0,0,1,100,0,10000,10000,20000,20000,0,0,11,100623,0,0,0,0,0,5,40,1,0,0,0,0,0,0,'Stormfang - Static Charge overload'),

-- Phase 1: 80% Thunder Howl
(9916201,0,13,0,2,1,100,0,0,80,0,0,0,0,11,5484,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Stormfang - Thunder Howl (native fallback)'),
(9916201,0,14,0,2,1,100,0,0,80,0,0,0,0,10,15,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Stormfang - Thunder Howl roar'),

-- Phase 2 transition at 65%
(9916201,0,20,0,2,1,100,0,0,65,0,0,0,0,1,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Stormfang - phase 2 yell'),
(9916201,0,21,0,2,1,100,0,0,65,0,0,0,0,11,100381,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Stormfang - Stormcall'),
(9916201,0,22,0,2,1,100,0,0,65,0,0,0,0,12,9916202,1,120000,1,1,0,1,0,0,0,0,0,0,0,0,'Stormfang - Storm Conduit 1'),
(9916201,0,23,0,2,1,100,0,0,65,0,0,0,0,12,9916202,1,120000,1,1,0,1,0,0,0,0,0,0,0,0,'Stormfang - Storm Conduit 2'),
(9916201,0,24,0,2,1,100,0,0,65,0,0,0,0,22,2,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Stormfang - enter phase 2'),

-- Phase 2 timers
(9916201,0,30,0,0,2,100,0,5000,5000,11000,11000,0,0,11,102946,0,0,0,0,0,5,40,1,0,0,0,0,0,0,'Stormfang - Chain Lightning'),
(9916201,0,31,0,0,2,100,0,6000,6000,14000,14000,0,0,11,9005,0,0,0,0,0,6,40,1,0,0,0,0,0,0,'Stormfang - Static Pounce'),
(9916201,0,32,0,0,2,100,0,8000,8000,20000,20000,0,0,11,100376,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Stormfang - Static Charge'),
(9916201,0,33,0,0,2,100,0,7000,7000,10000,10000,0,0,11,100377,0,0,0,0,0,2,0,0,0,0,0,0,0,0,'Stormfang - Thunderclap'),
(9916201,0,34,0,0,2,100,0,45000,45000,45000,45000,0,0,11,100381,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Stormfang - repeated Stormcall'),

-- Phase 2: 55% Thunder Howl
(9916201,0,35,0,2,2,100,0,55,55,0,0,0,0,11,5484,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Stormfang - Thunder Howl'),
(9916201,0,36,0,2,2,100,0,55,55,0,0,0,0,10,15,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Stormfang - Thunder Howl roar'),

-- Phase 2: 50% Overcharge
(9916201,0,37,0,2,2,100,0,50,50,0,0,0,0,11,100376,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Stormfang - Overcharge shield'),
(9916201,0,38,0,2,2,100,0,50,50,0,0,0,0,11,100377,0,0,0,0,0,2,0,0,0,0,0,0,0,0,'Stormfang - Overcharge Thunderclap'),

-- Phase 3 transition at 30%
(9916201,0,39,0,2,2,100,0,30,30,0,0,0,0,1,2,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Stormfang - phase 3 yell'),
(9916201,0,40,0,2,2,100,0,30,30,0,0,0,0,11,100376,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Stormfang - final Overcharge'),
(9916201,0,41,0,2,2,100,0,30,30,0,0,0,0,22,4,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Stormfang - enter phase 3'),

-- Phase 3 timers
(9916201,0,50,0,0,4,100,0,3000,3000,8000,8000,0,0,11,102946,0,0,0,0,0,5,40,1,0,0,0,0,0,0,'Stormfang - Chain Lightning'),
(9916201,0,51,0,0,4,100,0,4000,4000,10000,10000,0,0,11,9005,0,0,0,0,0,6,40,1,0,0,0,0,0,0,'Stormfang - Static Pounce'),
(9916201,0,52,0,0,4,100,0,5000,5000,9000,9000,0,0,11,100377,0,0,0,0,0,2,0,0,0,0,0,0,0,0,'Stormfang - Thunderclap'),
(9916201,0,53,0,0,4,100,0,8000,8000,15000,15000,0,0,11,100376,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Stormfang - Static Charge'),
(9916201,0,54,0,0,4,100,0,45000,45000,45000,45000,0,0,11,100381,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Stormfang - repeated Stormcall'),

-- Phase 3: 30% Thunder Howl
(9916201,0,55,0,2,4,100,0,30,30,0,0,0,0,11,5484,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Stormfang - Thunder Howl'),
(9916201,0,56,0,2,4,100,0,30,30,0,0,0,0,10,15,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Stormfang - Thunder Howl roar'),

-- Eight-minute soft enrage
(9916201,0,60,0,0,7,100,0,480000,480000,0,0,0,0,11,100376,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Stormfang - soft enrage'),

-- Death / reset
(9916201,0,70,0,6,0,100,0,0,0,0,0,0,0,1,3,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Stormfang - death yell'),
(9916201,0,71,0,25,0,100,0,0,0,0,0,0,0,22,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Stormfang - reset phase'),

-- Storm Conduit
(9916202,0,1,0,0,0,100,0,1000,1000,8000,8000,0,0,11,102946,0,0,0,0,0,5,40,1,0,0,0,0,0,0,'Storm Conduit - Chain Lightning'),
(9916202,0,2,0,0,0,100,0,5000,5000,15000,15000,0,0,11,100376,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Storm Conduit - Lightning Shield');

COMMIT;
