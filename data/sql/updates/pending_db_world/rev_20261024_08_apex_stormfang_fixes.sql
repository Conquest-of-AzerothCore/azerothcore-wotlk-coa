-- Apex Bounty: The Stormfang -- first playtest fixes
--
-- 1. The Stormfang is scaled to 3.0 in creature_template_model.
-- 2. Storm Conduits use the native Lightning Elemental display 67388 so the
--    target portrait is a creature model rather than the custom display's
--    placeholder art.
-- 3. Chain Lightning uses the custom Forked Lightning spell 100619 (visual 944)
--    instead of 102946 (visual 36), which reads as a caster-centred fork.
-- 4. Repeated Stormcall now summons a fresh pair of Storm Conduits.
-- 5. Forked Lightning and Storm Bolt are added as recurring casts in all phases.
--
-- The original 07 update still creates the creature, spawn, text and base SAI.

START TRANSACTION;

UPDATE `creature_template_model`
   SET `DisplayScale` = 3.0
 WHERE `CreatureID` = 9916201;

UPDATE `creature_template_model`
   SET `CreatureDisplayID` = 67388,
       `DisplayScale` = 1.0
 WHERE `CreatureID` = 9916202;

UPDATE `smart_scripts`
   SET `action_param1` = 100619
 WHERE `entryorguid` = 9916201
   AND `source_type` = 0
   AND `action_type` = 11
   AND `action_param1` = 102946;

DELETE FROM `smart_scripts`
 WHERE `entryorguid` = 9916201
   AND `source_type` = 0
   AND `id` IN (15,16,42,43,45,46,57,58,59,60);

INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,
 `event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`event_param6`,
 `action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,
 `target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,
 `target_x`,`target_y`,`target_z`,`target_o`,`comment`)
VALUES
-- Phase 1: extra cast variety
(9916201,0,15,0,0,1,100,0,12000,12000,12000,12000,0,0,11,100619,0,0,0,0,0,5,40,1,0,0,0,0,0,0,'Stormfang - Forked Lightning'),
(9916201,0,16,0,0,1,100,0,15000,15000,15000,15000,0,0,11,102934,0,0,0,0,0,5,40,1,0,0,0,0,0,0,'Stormfang - Storm Bolt'),

-- Phase 2: recurring Stormcall summons and extra casts
(9916201,0,42,0,0,2,100,0,45000,45000,45000,45000,0,0,12,9916202,1,120000,1,1,0,1,0,0,0,0,0,0,0,0,'Stormfang - Stormcall conduit 1'),
(9916201,0,43,0,0,2,100,0,45000,45000,45000,45000,0,0,12,9916202,1,120000,1,1,0,1,0,0,0,0,0,0,0,0,'Stormfang - Stormcall conduit 2'),
(9916201,0,45,0,0,2,100,0,9000,9000,9000,9000,0,0,11,100619,0,0,0,0,0,5,40,1,0,0,0,0,0,0,'Stormfang - Forked Lightning'),
(9916201,0,46,0,0,2,100,0,13000,13000,13000,13000,0,0,11,102934,0,0,0,0,0,5,40,1,0,0,0,0,0,0,'Stormfang - Storm Bolt'),

-- Phase 3: recurring Stormcall summons and extra casts
(9916201,0,57,0,0,4,100,0,45000,45000,45000,45000,0,0,12,9916202,1,120000,1,1,0,1,0,0,0,0,0,0,0,0,'Stormfang - Stormcall conduit 1'),
(9916201,0,58,0,0,4,100,0,45000,45000,45000,45000,0,0,12,9916202,1,120000,1,1,0,1,0,0,0,0,0,0,0,0,'Stormfang - Stormcall conduit 2'),
(9916201,0,59,0,0,4,100,0,6000,6000,6000,6000,0,0,11,100619,0,0,0,0,0,5,40,1,0,0,0,0,0,0,'Stormfang - Forked Lightning'),
(9916201,0,60,0,0,4,100,0,9000,9000,9000,9000,0,0,11,102934,0,0,0,0,0,5,40,1,0,0,0,0,0,0,'Stormfang - Storm Bolt');

COMMIT;
