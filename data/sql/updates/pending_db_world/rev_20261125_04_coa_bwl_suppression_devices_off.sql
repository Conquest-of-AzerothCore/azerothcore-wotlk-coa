-- Blackwing Lair: the Suppression Devices (179784) in the Suppression Room never apply Suppression Aura (22247).
-- The device cast it two ways: go_suppression_device every 5 seconds and its trap spell (Data3). Both are cleared;
-- the 38 spawns stay as scenery.
UPDATE `gameobject_template` SET `ScriptName` = '', `Data3` = 0 WHERE `entry` = 179784;
