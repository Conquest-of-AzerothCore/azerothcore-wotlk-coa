-- The Missing Diplomat (1447): Dashel Stonefist (4961) must surrender at 0-15%
-- health (quest credit, evade, friendly faction, surrender text via timed list
-- 496101). Beating him down within ~2s of accepting the quest drops that
-- install silently: SmartScript::SetScript9 refuses a new timed list while the
-- quest-accept list 496100 is still running unless the caller sets allowOverride,
-- and row id 2 neither sets it nor paces its refires, so overkill kills the only
-- surrender path and the fight never ends (#7949, gamebreaking).
-- Fix the trigger, keep the lists untouched: repeat cooldown 15s (past 496101's
-- ~6s runtime, so refires can never thrash a running list) and allowOverride so
-- installation is forced whenever he is low and engaged. The evade ends the
-- cycle, so no repeated installs once he surrenders.
-- Only row id 2 of the (4961, 0) block changes; every other value below matches
-- the live rows byte for byte.
DELETE FROM `smart_scripts` WHERE `entryorguid` = 4961 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(4961,0,0,0,105,0,25,0,6000,21000,6000,21000,0,5,11,12555,0,0,0,0,0,7,0,0,0,0,0,0,0,0,'Dashel Stonefist - Target Casting - Cast ''Pummel'''),
(4961,0,1,3,19,0,100,512,1447,0,0,0,0,0,80,496100,2,0,0,0,0,1,0,0,0,0,0,0,0,0,'Dashel Stonefist - On Quest ''The Missing Diplomat'' Taken - Run Script'),
(4961,0,2,0,2,0,100,512,0,15,15000,15000,0,0,80,496101,2,1,0,0,0,1,0,0,0,0,0,0,0,0,'Dashel Stonefist - Between 0-15% Health - Run Script'),
(4961,0,3,0,61,0,100,512,0,0,0,0,0,0,42,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Dashel Stonefist - On Quest Accept - Set invincibility HP'),
(4961,0,4,0,2,0,100,512,0,15,0,0,0,0,2,84,0,0,0,0,0,11,4969,50,1,0,0,0,0,0,'Dashel Stonefist - Between 0-15% Health - Set minions friendly'),
(4961,0,5,0,2,0,100,512,0,15,0,0,0,0,41,10000,0,0,0,0,0,11,4969,50,1,0,0,0,0,0,'Dashel Stonefist - Between 0-15% Health - Despawn minions in 10s');
