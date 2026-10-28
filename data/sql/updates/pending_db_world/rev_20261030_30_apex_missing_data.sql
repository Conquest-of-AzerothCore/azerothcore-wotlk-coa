-- The two Nytharos summons exist in the module templates but carried no ScriptName, which is
-- why the server logged them as unassigned and the summons never appeared. The rest is the
-- data correction set that only ever existed in the working database.
START TRANSACTION;

UPDATE `creature_template` SET `ScriptName` = 'NytharosTornadoScript' WHERE `entry` = 9916216;
UPDATE `creature_template` SET `ScriptName` = 'NytharosShellScript'   WHERE `entry` = 9916217;
UPDATE `creature_template` SET `AIName` = '' WHERE `entry` = 9916222;
UPDATE `creature_template` SET `unit_class` = 1 WHERE `entry` = 9916211;

UPDATE `item_template` SET `Material` = 1, `SheatheType` = 3 WHERE `entry` = 190191;
UPDATE `item_template` SET `SoundOverrideSubclass` = 0 WHERE `entry` IN (1009302, 1009303, 1009304);

DELETE FROM `creature_questitem` WHERE `CreatureEntry` IN (9916212, 9916213, 9916214);
DELETE FROM `creature_loot_template` WHERE `Entry` IN (9916212, 9916213, 9916214);
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (9916201, 9916202, 9916212);

COMMIT;
