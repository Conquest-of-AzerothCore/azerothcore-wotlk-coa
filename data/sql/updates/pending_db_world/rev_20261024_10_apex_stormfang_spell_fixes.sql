-- Apex Bounty: The Stormfang -- correct the two invalid playtest spells.
--
-- 100619 Forked Lightning is a cone in front of the caster, not a chain.
-- 9005 Pounce requires the caster to be prowling and can fail from SmartAI.
--
-- Use the custom Chain Lightning 102946 (3-target arc) and custom Rake 100331
-- (no prowl prerequisite) instead.

START TRANSACTION;

UPDATE `smart_scripts`
   SET `action_param1` = 102946
 WHERE `entryorguid` IN (9916201, 9916202)
   AND `source_type` = 0
   AND `action_type` = 11
   AND `action_param1` = 100619;

UPDATE `smart_scripts`
   SET `action_param1` = 100331
 WHERE `entryorguid` = 9916201
   AND `source_type` = 0
   AND `action_type` = 11
   AND `action_param1` = 9005;

COMMIT;
