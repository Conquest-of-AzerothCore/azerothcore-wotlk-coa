-- mod-cfbg (azerothcore/mod-cfbg 78771c6): Alterac Valley bounty hunters serve both teams of a mixed battleground,
-- and the .cfbg commands let players pick their battleground race or inspect their cross-faction state.
UPDATE `creature_template` SET `faction` = 1216 WHERE `entry` IN (14187, 22528, 31924, 37240, 14188, 22699, 31963, 37281);
UPDATE `creature_template` SET `faction` = 1214 WHERE `entry` IN (14185, 22712, 32049, 37370, 14186, 22569, 32053, 37374);

DELETE FROM `command` WHERE `name` IN ('cfbg', 'cfbg race', 'cfbg debug');
INSERT INTO `command` (`name`, `security`, `help`) VALUES
('cfbg', 0, 'Crossfaction battleground module commands.'),
('cfbg race', 0, 'Morphs your character to the selected race once you join a battleground.\nBy default, the following races are available: human, dwarf, gnome, draenei ("broken ones"), orc, bloodelf, troll, tauren.'),
('cfbg debug', 1, 'Syntax: .cfbg debug [$playername]\nDumps the target/self player''s CFBG state: enable flags, fake/native/forget flags, native vs current race/team/display, preferred race setting, and the stored FakePlayer record when faked. Console requires $playername.');
