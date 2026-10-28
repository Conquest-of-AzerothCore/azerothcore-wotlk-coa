-- Mythic+ values the client does not hold.

-- Enemy forces per creature. Without a row, a creature placed in the database
-- counts 1 (elite 2, see MythicPlus.DefaultForces.*); summons count only here.
CREATE TABLE IF NOT EXISTS `coa_mythic_forces` (
    `entry`   INT UNSIGNED NOT NULL,
    `forces`  INT UNSIGNED NOT NULL DEFAULT 1,
    `comment` VARCHAR(255) NOT NULL DEFAULT '',
    PRIMARY KEY (`entry`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- What one cache holds, by keystone level. A timed run gives 1 to 3 caches.
-- Empty on purpose: the "Mythical Cache" items exist but have no loot rows.
CREATE TABLE IF NOT EXISTS `coa_mythic_reward` (
    `level_min` INT UNSIGNED NOT NULL,
    `level_max` INT UNSIGNED NOT NULL,
    `item`      INT UNSIGNED NOT NULL,
    `count`     INT UNSIGNED NOT NULL DEFAULT 1,
    `comment`   VARCHAR(255) NOT NULL DEFAULT '',
    PRIMARY KEY (`level_min`, `level_max`, `item`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Patrol paths of the Mythic Champions (keys +14 and up): a champion walks from
-- point A to point B and back. Set in game with .mythic setchampionpos 1 / 2.
CREATE TABLE IF NOT EXISTS `coa_mythic_champion_path` (
    `id`  INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `map` SMALLINT UNSIGNED NOT NULL,
    `a_x` FLOAT NOT NULL,
    `a_y` FLOAT NOT NULL,
    `a_z` FLOAT NOT NULL,
    `a_o` FLOAT NOT NULL DEFAULT 0,
    `b_x` FLOAT NOT NULL,
    `b_y` FLOAT NOT NULL,
    `b_z` FLOAT NOT NULL,
    `comment` VARCHAR(255) NOT NULL DEFAULT '',
    PRIMARY KEY (`id`),
    KEY `map` (`map`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
