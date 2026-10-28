-- rev_20261002_22 deleted the SmartAI scripts that served only the cut Deathknell class quests, but left their
-- creatures and objects set to SmartAI, so the server logged "SmartAI enabled but no SmartAI entries" for each at
-- startup. The three trainers keep their spawns and match Deathknell's other class trainers, which have no AI
-- script; the other five have no spawns left.
UPDATE `creature_template` SET `AIName` = '' WHERE `entry` IN (50275, 50327, 502930, 685034, 9300253, 9300256)
    AND `AIName` = 'SmartAI';
UPDATE `gameobject_template` SET `AIName` = '' WHERE `entry` IN (9301250, 9301251) AND `AIName` = 'SmartGameObjectAI';
