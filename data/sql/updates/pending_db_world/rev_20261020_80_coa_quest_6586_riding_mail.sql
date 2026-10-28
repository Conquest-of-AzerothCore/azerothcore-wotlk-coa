-- Draenei start in Shadowglen and Blood Elves in Deathknell (rev_20261003_30), and a Classic account cannot enter
-- Outland map 530, so the Exodar and Eversong riding mails sent them on quests they cannot finish (#6586).
-- Mail Draenei the Night Elf pamphlet from Jartsam in Darnassus and Blood Elves the Undead pamphlet from
-- Velma Warnam in Brill.
DELETE FROM `mail_level_reward` WHERE `level` = 20 AND `raceMask` IN (512, 1024);
INSERT INTO `mail_level_reward` (`level`, `raceMask`, `mailTemplateId`, `senderEntry`) VALUES
(20, 512, 233, 4773),
(20, 1024, 225, 4753);
