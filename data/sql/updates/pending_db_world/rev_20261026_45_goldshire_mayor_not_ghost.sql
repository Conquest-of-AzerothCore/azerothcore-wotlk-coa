-- Harvend Thorm (Mayor of Goldshire, 162807) and a Goldshire Farmer (162822) looked like ghosts (#8745): the
-- portrait fix rev_20261009_50 moved them to display 10478, the translucent Ghostly Citizen (alpha 128).
-- 26602 has the same model and the same CreatureDisplayInfoExtra (7465) at full opacity, so the portrait,
-- the preset customization bytes and the outfit stay as they are. The preset rows follow the display, since
-- the preset manager keys on (entry, display_id).
UPDATE `creature_template_model` SET `CreatureDisplayID` = 26602 WHERE `CreatureID` IN (162807, 162822) AND `Idx` = 0 AND `CreatureDisplayID` = 10478;
UPDATE `creature_display_preset` SET `display_id` = 26602 WHERE `entry` IN (162807, 162822) AND `display_id` = 10478;
