UPDATE `gameobject_template` SET `Data1` = 0 WHERE `entry` IN (174744, 174745) AND `type` = 1 AND `Data1` = 799;

-- Clients that saw the braziers before kept lock 799 in their gameobject cache and still asked for the torch.
-- A new cache version makes every client clear its cache at the next login.
UPDATE `version` SET `cache_id` = `cache_id` + 1;
