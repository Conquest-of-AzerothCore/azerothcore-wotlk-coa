CREATE TABLE IF NOT EXISTS `coa_mythic_wing_credit` (
    `encounter` INT UNSIGNED NOT NULL,
    `creature` INT UNSIGNED NOT NULL,
    `comment` VARCHAR(255) NOT NULL DEFAULT '',
    PRIMARY KEY (`encounter`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELETE FROM `coa_mythic_wing_credit` WHERE `encounter` IN (162, 1162, 2162);
INSERT INTO `coa_mythic_wing_credit` (`encounter`, `creature`, `comment`) VALUES
    (162, 643, 'Deadmines - Sneed, not Sneed''s Shredder'),
    (1162, 643, 'Deadmines - Sneed, not Sneed''s Shredder'),
    (2162, 643, 'Deadmines - Sneed, not Sneed''s Shredder');

DELETE FROM `coa_mythic_forces` WHERE `entry` = 642;
INSERT INTO `coa_mythic_forces` (`entry`, `forces`, `comment`) VALUES
    (642, 0, 'Sneed''s Shredder - Sneed gives the boss credit');

DELETE FROM `coa_dungeon_mark_bosses` WHERE `entry` IN (642, 643);
INSERT INTO `coa_dungeon_mark_bosses` (`entry`) VALUES (643);

UPDATE `instance_encounters` SET `creditEntry` = 643 WHERE `entry` = 1162 AND `creditType` = 0;
