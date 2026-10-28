-- Apex Bounty: The Stormfang -- conduit chain visual consistency.
-- The boss uses custom Forked Lightning 100619 for its caster-based chain;
-- the summoned Storm Conduits should use the same visual source.

START TRANSACTION;

UPDATE `smart_scripts`
   SET `action_param1` = 100619
 WHERE `entryorguid` = 9916202
   AND `source_type` = 0
   AND `action_type` = 11
   AND `action_param1` = 102946;

COMMIT;
