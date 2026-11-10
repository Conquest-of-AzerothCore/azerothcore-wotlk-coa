-- Unexpected Results (254107): the Young Forest Bear and the Prowler carry the Enchanted Mineral credit, but
-- rev_20260930_98_northshire_baseline_restore replaced their templates with an empty AIName, so the script never ran
UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` IN (118, 822);
