-- Dungeon fixes: Fierce Blow, Tomb Fiend, Landslide.

-- Fierce Blow (975011) in the bosses' SmartAI kits went out at 200 % weapon damage and triggered,
-- so it ignored a running cast. Boss melee damage is restored now, so it goes back to the spell's own
-- 100 %, and it is cast untriggered: the core makes it an on-next-swing strike (SpellInfoCorrections),
-- which takes the place of a melee hit.
UPDATE `smart_scripts` SET `action_param2` = 0, `action_param3` = 100
WHERE `action_type` = 218 AND `action_param1` = 975011;

-- Tomb Fiend (Razorfen Downs) is a normal creature but had an elite's health (HealthModifier 4,
-- from rev_20260919_21). Back to the stock 1.1.
UPDATE `creature_template` SET `HealthModifier` = 1.1 WHERE `entry` = 7349;

-- Damage multiplier for single creatures in dungeons: melee, spells and periodic damage, every
-- difficulty (CoADungeonSpellDamage.cpp).
CREATE TABLE IF NOT EXISTS `coa_dungeon_creature_damage` (
    `entry`      INT UNSIGNED NOT NULL,
    `multiplier` FLOAT NOT NULL DEFAULT 1,
    `comment`    VARCHAR(255) NOT NULL DEFAULT '',
    PRIMARY KEY (`entry`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Landslide (Maraudon) hit far too hard: Fierce Blow for about 8k, boulders for about 5k.
DELETE FROM `coa_dungeon_creature_damage` WHERE `entry` = 12203;
INSERT INTO `coa_dungeon_creature_damage` (`entry`, `multiplier`, `comment`) VALUES
(12203, 0.6, 'Landslide: all damage -40 %');
