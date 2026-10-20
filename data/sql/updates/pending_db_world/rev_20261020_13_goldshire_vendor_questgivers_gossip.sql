-- Tharynn Bouden, Sergeant De Vries and Dawn Brightstar were made quest givers without the gossip flag. Without it the
-- server opens the quest window directly whenever a quest is available, so their shops could not be reached. With the
-- flag they show the quest and "I want to browse your goods" together.
UPDATE `creature_template` SET `npcflag` = `npcflag` | 1 WHERE `entry` IN (66, 955, 958);
