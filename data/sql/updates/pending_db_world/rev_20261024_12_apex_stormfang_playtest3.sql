-- Apex Bounty: The Stormfang -- playtest corrections #3
--
-- 1. Chain Lightning: 421 uses SpellVisual 36 -> cast kit 321, which attaches
--    "Lightning Cast Hand" (293) to the hand. The wolf has no usable hand
--    anchor, so the effect appears above the model. Native Chain Lightning
--    59220 uses SpellVisual 7523 -> cast kit 6541, which attaches the same
--    lightning model as a BreathEffect (mouth). This fixes the origin without
--    a client DLL/DBC patch.
--
-- 2. Lightning Bolt: 100621 is a stub with Effect 2 and no base damage. Native
--    Lightning Bolt 8246 uses SpellVisual 857 -> cast kit 893 -> BreathEffect
--    293, so the bolt also originates at the mouth.
--
-- 3. Storm Bolt stun: 102934 requires a thrown weapon when cast normally. The
--    SmartAI ADD_AURA action applies its stun aura directly to a random
--    hostile target, matching the requested Storm Bolt behaviour without the
--    weapon requirement.
--
-- 4. Rake: 100331 is a stub (effects 31/160, no bleed). Native Rake 9904 is
--    cast on the tank, then Mortal Strike's healing-reduction aura and Faerie
--    Fire's armor-reduction aura are applied to the same victim with ADD_AURA.
--    This avoids the weapon requirements on Mortal Strike/Sunder Armor while
--    still giving the tank the heal cut and armor shred.

START TRANSACTION;

-- Chain Lightning, including the Storm Conduits.
UPDATE `smart_scripts`
   SET `action_param1` = 59220,
       `comment` = 'Stormfang - Chain Lightning (mouth visual)'
 WHERE `entryorguid` IN (9916201, 9916202)
   AND `source_type` = 0
   AND `action_type` = 11
   AND `action_param1` = 421;

-- Lightning Bolt: real damage and a mouth-anchored visual.
UPDATE `smart_scripts`
   SET `action_param1` = 8246,
       `comment` = CONCAT(SUBSTRING_INDEX(`comment`, ' - ', 1), ' - Lightning Bolt (mouth visual)')
 WHERE `entryorguid` = 9916201
   AND `source_type` = 0
   AND `action_type` = 11
   AND `action_param1` = 100621;

-- Rake is a tank-targeted bleeds, not a random-target pounce.
UPDATE `smart_scripts`
   SET `action_param1` = 9904,
       `target_type` = 2,
       `target_param1` = 0,
       `target_param2` = 0,
       `comment` = 'Stormfang - Rake (tank)'
 WHERE `entryorguid` = 9916201
   AND `source_type` = 0
   AND `action_type` = 11
   AND `action_param1` = 100331;

-- Remove any previous copies of the new aura rows.
DELETE FROM `smart_scripts`
 WHERE `entryorguid` = 9916201
   AND `source_type` = 0
   AND `id` IN (17, 18, 19, 47, 48, 49, 61, 62, 63);

-- Phase 1: Rake happens every 8 s; keep the heal cut and armor shred on the
-- same cadence. Storm Bolt stun follows the 15 s Lightning Bolt timer.
INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,
 `event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`event_param6`,
 `action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,
 `target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,
 `target_x`,`target_y`,`target_z`,`target_o`,`comment`)
VALUES
(9916201,0,17,0,0,1,100,0,8000,8000,8000,8000,0,0,75,12294,0,0,0,0,0,2,0,0,0,0,0,0,0,0,'Stormfang - Rake: Mortal Strike healing cut'),
(9916201,0,18,0,0,1,100,0,8000,8000,8000,8000,0,0,75,770,0,0,0,0,0,2,0,0,0,0,0,0,0,0,'Stormfang - Rake: Faerie Fire armor shred'),
(9916201,0,19,0,0,1,100,0,15000,15000,15000,15000,0,0,75,102934,0,0,0,0,0,5,40,1,0,0,0,0,0,0,'Stormfang - Storm Bolt stun');

-- Phase 2: Rake every 6 s, Lightning Bolt/Storm Bolt every 13 s.
INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,
 `event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`event_param6`,
 `action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,
 `target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,
 `target_x`,`target_y`,`target_z`,`target_o`,`comment`)
VALUES
(9916201,0,47,0,0,2,100,0,6000,6000,6000,6000,0,0,75,12294,0,0,0,0,0,2,0,0,0,0,0,0,0,0,'Stormfang - Rake: Mortal Strike healing cut'),
(9916201,0,48,0,0,2,100,0,6000,6000,6000,6000,0,0,75,770,0,0,0,0,0,2,0,0,0,0,0,0,0,0,'Stormfang - Rake: Faerie Fire armor shred'),
(9916201,0,49,0,0,2,100,0,13000,13000,13000,13000,0,0,75,102934,0,0,0,0,0,5,40,1,0,0,0,0,0,0,'Stormfang - Storm Bolt stun');

-- Phase 3: Rake every 4 s, Lightning Bolt/Storm Bolt every 9 s.
INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,
 `event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`event_param6`,
 `action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,
 `target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,
 `target_x`,`target_y`,`target_z`,`target_o`,`comment`)
VALUES
(9916201,0,61,0,0,4,100,0,4000,4000,4000,4000,0,0,75,12294,0,0,0,0,0,2,0,0,0,0,0,0,0,0,'Stormfang - Rake: Mortal Strike healing cut'),
(9916201,0,62,0,0,4,100,0,4000,4000,4000,4000,0,0,75,770,0,0,0,0,0,2,0,0,0,0,0,0,0,0,'Stormfang - Rake: Faerie Fire armor shred'),
(9916201,0,63,0,0,4,100,0,9000,9000,9000,9000,0,0,75,102934,0,0,0,0,0,5,40,1,0,0,0,0,0,0,'Stormfang - Storm Bolt stun');

COMMIT;
