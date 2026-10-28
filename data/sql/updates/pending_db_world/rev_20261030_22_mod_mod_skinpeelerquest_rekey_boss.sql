START TRANSACTION;

UPDATE `creature_template` SET `entry` = 9916212 WHERE `entry` = 9916210;
UPDATE `creature_template_model` SET `CreatureID` = 9916212 WHERE `CreatureID` = 9916210;
UPDATE `smart_scripts` SET `entryorguid` = 9916212 WHERE `entryorguid` = 9916210;
UPDATE `creature` SET `id` = 9916212 WHERE `id` = 9916210;

UPDATE `creature_template`
SET `name` = 'Stormfang',
    `subname` = 'the Crackling Fury',
    `rank` = 1
WHERE `entry` = 9916212;

COMMIT;
