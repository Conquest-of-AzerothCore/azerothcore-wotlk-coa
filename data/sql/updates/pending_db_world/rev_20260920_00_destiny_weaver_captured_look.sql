-- Destiny Weaver: Galric Olim's captured look, and the model the other fifteen are drawn with.
--
-- Two corrections to the sixteen preset rows written by rev_20260919_04_destiny_weaver_presets.sql.
--
-- 1. `display_id` held the Weaver's own custom display - 449292 to 449299, one per pair. Those
--    ids are not in the client's CreatureDisplayInfo.dbc (84,488 rows, and nothing between
--    449200 and 449900), so every Weaver was asking the client to draw a model it does not
--    have. Captured live traffic settles what the server sent instead: a 68-byte
--    SMSG_MIRRORIMAGE_DATA body for entry 449347, captured 2026-09-01, carries display 49,
--    and across the 208 player-model rows in that capture the field is the plain character
--    display for the unit's race and gender - 49/50 human, 51/52 orc, 53/54 dwarf, 55/56
--    night elf, 57/58 undead, 1563/1564 gnome, 1478/1479 troll, 6894/6895 goblin, 15476/15475
--    blood elf, 16125/16126 draenei (male/female). Those are the CreatureDisplayInfo rows
--    whose CreatureModelData points at Character\<Race>\<Gender>\ and whose ExtendedDisplayInfoID
--    is 0: the plain player display, not an NPC wearing the same model.
--
-- 2. Galric Olim's appearance is no longer a stand-in. The captured body for 449347 is
--    reproduced here field for field: race 1, gender 0, class 1, skin 4, face 2, hair 6,
--    haircolour 8, facial hair 4, body/chest/legs/feet/wrists 126792/66195/66200/142624/142619,
--    head/shoulders/waist/hands/back/tabard empty.
--
-- The other fifteen rows keep the dressed-character look they were given in rev_20260919_04
-- (a real display of the same race and gender, not the Weaver's own); only the model each is
-- drawn with is corrected, so they render as the right race instead of not at all.

UPDATE `creature_display_preset` SET `display_id` = 1478 WHERE `entry` IN (449340, 449350);
UPDATE `creature_display_preset` SET `display_id` = 53 WHERE `entry` IN (449342, 449352);
UPDATE `creature_display_preset` SET `display_id` = 57 WHERE `entry` IN (449343, 449353);
UPDATE `creature_display_preset` SET `display_id` = 16125 WHERE `entry` IN (449344, 449354);
UPDATE `creature_display_preset` SET `display_id` = 56 WHERE `entry` IN (449345, 449355);
UPDATE `creature_display_preset` SET `display_id` = 15475 WHERE `entry` IN (449341, 449351);
UPDATE `creature_display_preset` SET `display_id` = 51 WHERE `entry` IN (449346, 449356);
UPDATE `creature_display_preset` SET `display_id` = 49 WHERE `entry` IN (449347, 449357);

-- Galric Olim (449347), captured 2026-09-01.
UPDATE `creature_display_preset` SET `class` = 1, `skin` = 4, `face` = 2, `hair` = 6, `haircolor` = 8, `facialhair` = 4 WHERE `entry` = 449347;
UPDATE `creature_display_preset` SET `item_body` = 126792, `item_chest` = 66195, `item_legs` = 66200, `item_feet` = 142624, `item_wrists` = 142619 WHERE `entry` = 449347;
UPDATE `creature_display_preset` SET `item_head` = 0, `item_shoulders` = 0, `item_waist` = 0, `item_hands` = 0, `item_back` = 0, `item_tabard` = 0 WHERE `entry` = 449347;
