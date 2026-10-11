-- Witch Doctor Zum'rah (Zul'Farrak): Healing Wave has a 10 s cooldown and each of his heals restores
-- 7.5 % of the target's health (it healed 0.5-1 %); coa_dungeon_creature_heal is read by
-- CoADungeonSpellDamage.cpp.
UPDATE `smart_scripts` SET `event_param3` = 10000, `event_param4` = 10000
WHERE `entryorguid` = 7271 AND `source_type` = 0 AND `id` = 4;

CREATE TABLE IF NOT EXISTS `coa_dungeon_creature_heal` (
    `entry`    INT UNSIGNED NOT NULL,
    `heal_pct` FLOAT NOT NULL DEFAULT 0,
    `comment`  VARCHAR(255) NOT NULL DEFAULT '',
    PRIMARY KEY (`entry`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
DELETE FROM `coa_dungeon_creature_heal` WHERE `entry` = 7271;
INSERT INTO `coa_dungeon_creature_heal` (`entry`, `heal_pct`, `comment`) VALUES
(7271, 0.075, 'Witch Doctor Zum''rah: each heal restores 7.5 % of the target''s health');
