-- The Wondrous Wisdomball's greeting, and the menu it opens with.
--
-- The frame's text area is drawn from an npc_text row, and the ball had none: its window used to
-- open with the greeting empty and only the paging line under it. This restores the companion's
-- own greeting as Ascension wrote it, in both voices (the client picks by the character's
-- gender), with the paragraph breaks it used. The quest names beside it are not rows of anything
-- - the module builds them into the menu's quest half at run time, which is what makes the client
-- draw its own "!" and "?" markers and colour each title by level.
--
-- The gossip_menu row is the ball's own menu id, so a menu this small is also described in the
-- database: the script sends this text id itself, and this is the row it names.

DELETE FROM `npc_text` WHERE `ID` = 790250;
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `lang0`, `Probability0`) VALUES
(790250,
 'Greetings Hero!$B$BCall upon me in the dark depths of a dungeon and I shall commune across great distances to connect you with those seeking a Hero to carry out quests within the dungeon.',
 'Greetings Hero!$B$BCall upon me in the dark depths of a dungeon and I shall commune across great distances to connect you with those seeking a Hero to carry out quests within the dungeon.',
 0, 1);

REPLACE INTO `gossip_menu` (`MenuID`, `TextID`) VALUES (790250, 790250);

UPDATE `creature_template` SET `gossip_menu_id` = 790250 WHERE `entry` = 79025;
