-- Warcraft Reborn keeps the stock-class Draenei racials (1128875, 1128878, per-class 1128880 and 11595xx rows) in
-- skill 11760, while skill 760 only carries Hero and custom-class rows, so stock-class Draenei get 11760 at creation.
DELETE FROM `playercreateinfo_skills` WHERE `raceMask` = 1024 AND `classMask` = 1535 AND `skill` = 11760;
INSERT INTO `playercreateinfo_skills` (`raceMask`, `classMask`, `skill`, `rank`, `comment`) VALUES
(1024, 1535, 11760, 0, 'Draenei - Racial (Warcraft Reborn stock classes)');
