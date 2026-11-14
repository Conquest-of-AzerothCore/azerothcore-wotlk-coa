-- Sylindra Starweave (449169), Dolanaar's traveling riding trainer, teaches Novice Riding like Garion Hunter (97921)
-- in Goldshire, so she also offers and takes back the Alliance Path to Ascension: Novice Rider quests that Garion
-- does: Human 4420430, Dwarf 4420432, Night Elf 4420433, Gnome 4420436 and Draenei 4420439.
DELETE FROM `creature_queststarter` WHERE `id` = 449169
    AND `quest` IN (4420430, 4420432, 4420433, 4420436, 4420439);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES
(449169, 4420430),
(449169, 4420432),
(449169, 4420433),
(449169, 4420436),
(449169, 4420439);
DELETE FROM `creature_questender` WHERE `id` = 449169
    AND `quest` IN (4420430, 4420432, 4420433, 4420436, 4420439);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES
(449169, 4420430),
(449169, 4420432),
(449169, 4420433),
(449169, 4420436),
(449169, 4420439);
