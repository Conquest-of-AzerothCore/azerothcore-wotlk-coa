-- Shadowhound (#7445): hounds saved while the template used DarkHound keep that display on load; give them the
-- mastiff display 35355 the template now uses.
UPDATE `character_pet` SET `modelid` = 35355 WHERE `entry` = 50124 AND `modelid` = 16049;
