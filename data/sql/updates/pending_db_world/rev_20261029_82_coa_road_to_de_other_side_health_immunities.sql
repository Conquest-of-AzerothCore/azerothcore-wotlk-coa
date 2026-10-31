-- Road to De Other Side (map 937): what was agreed after #8715 and never reached main (its last commits came after the
-- merge): boss crowd-control immunities and health true to Ascension's logs.

-- The three bosses take the crowd-control immunities of the other rank 3 dungeon bosses (charm, fear, polymorph, root,
-- silence, sleep, stun and the rest of set -273, as Mograine, Whitemane or Ironaya).
UPDATE `creature_template` SET `CreatureImmunitiesId` = -273 WHERE `entry` IN (162711, 162715, 162716);

-- Road to De Other Side (map 937): health true to Ascension's logs. Mythic is the 2026-08-05 Mythic log, Heroic is
-- Mythic / 1.3 and Normal at level 60 Heroic / 2.33 (Destiny Weaver scales it down with the character), as in Vaults
-- of the Inquisition. The 2026-08-24 Normal log is not a level 60 run. Every creature, summons included, takes the
-- dungeon multiplier of 2.5 (CoA.CreatureScaling).

UPDATE `creature_template` SET `HealthModifier` = 37.954 WHERE `entry` = 162711; -- Muzah, the Shadow Hunter, about 289.6k
UPDATE `creature_template` SET `HealthModifier` = 46.76 WHERE `entry` = 162715; -- Drak'math the Sinister King, about 285.5k
UPDATE `creature_template` SET `HealthModifier` = 38.572 WHERE `entry` = 162716; -- Chimeric Embryo, about 294.3k
UPDATE `creature_template` SET `HealthModifier` = 3.748 WHERE `entry` = 162743; -- Spider, about 28.6k
UPDATE `creature_template` SET `HealthModifier` = 8.441 WHERE `entry` = 162765; -- Interstitial Wanderer, about 64.4k
UPDATE `creature_template` SET `HealthModifier` = 2.38 WHERE `entry` = 162766; -- Bat of the Other Side, about 18.2k
UPDATE `creature_template` SET `HealthModifier` = 2.38 WHERE `entry` = 162767; -- Bat of the Other Side, about 18.2k
UPDATE `creature_template` SET `HealthModifier` = 8.442 WHERE `entry` = 162769; -- Deathweaver Matriarch, about 64.4k
UPDATE `creature_template` SET `HealthModifier` = 3.16 WHERE `entry` = 162770; -- Spider of the Other Side, about 24.1k
UPDATE `creature_template` SET `HealthModifier` = 24.036 WHERE `entry` = 162773; -- Gutdevourer, about 183.4k
UPDATE `creature_template` SET `HealthModifier` = 8.44 WHERE `entry` = 162775; -- Gutdevourer, about 64.4k
UPDATE `creature_template` SET `HealthModifier` = 8.44 WHERE `entry` = 162776; -- Interstitial Wanderer, about 64.4k
UPDATE `creature_template` SET `HealthModifier` = 30.041 WHERE `entry` = 162780; -- Risen Cultist, about 183.4k
UPDATE `creature_template` SET `HealthModifier` = 10.55 WHERE `entry` = 162782; -- Hisser of the Other Side, about 64.4k
UPDATE `creature_template` SET `HealthModifier` = 10.548 WHERE `entry` = 162783; -- Interstitial Wanderer, about 64.4k
UPDATE `creature_template` SET `HealthModifier` = 3.16 WHERE `entry` = 162784; -- Violent Swarm, about 24.1k
UPDATE `creature_template` SET `HealthModifier` = 14.241 WHERE `entry` = 162785; -- Watcher of the Path, about 86.9k
UPDATE `creature_template` SET `HealthModifier` = 3.16 WHERE `entry` = 162979; -- Lifedrinker, about 24.1k
UPDATE `creature_template` SET `HealthModifier` = 3.16 WHERE `entry` = 162980; -- Lifedrinker, about 24.1k
UPDATE `creature_template` SET `HealthModifier` = 2.109 WHERE `entry` = 162981; -- Lifedrinker, about 16.1k
UPDATE `creature_template` SET `HealthModifier` = 24.037 WHERE `entry` = 162982; -- Risen Cultist, about 183.4k
UPDATE `creature_template` SET `HealthModifier` = 8.441 WHERE `entry` = 162983; -- Risen Cultist, about 64.4k
UPDATE `creature_template` SET `HealthModifier` = 29.53 WHERE `entry` = 162988; -- Vol’zeen, about 225.3k

DELETE FROM `coa_dungeon_health` WHERE `map_id` = 937;
INSERT INTO `coa_dungeon_health` (`map_id`, `difficulty`, `creature_entry`, `max_health`, `evidence`, `source`) VALUES
(937, 1, 162711, 674735, 'log', 'Heroic from Mythic /1.3; Muzah, the Shadow Hunter'),
(937, 2, 162711, 877155, 'log', 'Mythic combat log 2026-08-05; Muzah, the Shadow Hunter'),
(937, 1, 162715, 665142, 'log', 'Heroic from Mythic /1.3; Drak''math the Sinister King'),
(937, 2, 162715, 864685, 'log', 'Mythic combat log 2026-08-05; Drak''math the Sinister King'),
(937, 1, 162716, 685735, 'log', 'Heroic from Mythic /1.3; Chimeric Embryo'),
(937, 2, 162716, 891455, 'log', 'Mythic combat log 2026-08-05; Chimeric Embryo'),
(937, 1, 162743, 66638, 'log', 'Heroic from Mythic /1.3; Spider'),
(937, 2, 162743, 86630, 'log', 'Mythic combat log 2026-08-05; Spider'),
(937, 1, 162765, 150060, 'log', 'Heroic from Mythic /1.3; Interstitial Wanderer'),
(937, 2, 162765, 195078, 'log', 'Mythic combat log 2026-08-05; Interstitial Wanderer'),
(937, 1, 162766, 42308, 'model', 'Heroic from Mythic /1.3; Bat of the Other Side'),
(937, 2, 162766, 55000, 'model', 'in-game estimate (2026-10-23); Bat of the Other Side'),
(937, 1, 162767, 42308, 'model', 'Heroic from Mythic /1.3; Bat of the Other Side'),
(937, 2, 162767, 55000, 'model', 'in-game estimate (2026-10-23); Bat of the Other Side'),
(937, 1, 162769, 150075, 'log', 'Heroic from Mythic /1.3; Deathweaver Matriarch'),
(937, 2, 162769, 195097, 'log', 'Mythic combat log 2026-08-05; Deathweaver Matriarch'),
(937, 1, 162770, 56177, 'log', 'Heroic from Mythic /1.3; Spider of the Other Side'),
(937, 2, 162770, 73030, 'log', 'Mythic combat log 2026-08-05; Spider of the Other Side'),
(937, 1, 162773, 427318, 'log', 'Heroic from Mythic /1.3; Gutdevourer'),
(937, 2, 162773, 555514, 'log', 'Mythic combat log 2026-08-05; Gutdevourer'),
(937, 1, 162775, 150041, 'log', 'Heroic from Mythic /1.3; Gutdevourer'),
(937, 2, 162775, 195053, 'log', 'Mythic combat log 2026-08-05; Gutdevourer'),
(937, 1, 162776, 150053, 'log', 'Heroic from Mythic /1.3; Interstitial Wanderer'),
(937, 2, 162776, 195069, 'log', 'Mythic combat log 2026-08-05; Interstitial Wanderer'),
(937, 1, 162780, 427319, 'log', 'Heroic from Mythic /1.3; Risen Cultist'),
(937, 2, 162780, 555515, 'log', 'Mythic combat log 2026-08-05; Risen Cultist'),
(937, 1, 162782, 150063, 'log', 'Heroic from Mythic /1.3; Hisser of the Other Side'),
(937, 2, 162782, 195082, 'log', 'Mythic combat log 2026-08-05; Hisser of the Other Side'),
(937, 1, 162783, 150046, 'log', 'Heroic from Mythic /1.3; Interstitial Wanderer'),
(937, 2, 162783, 195060, 'log', 'Mythic combat log 2026-08-05; Interstitial Wanderer'),
(937, 1, 162784, 56177, 'log', 'Heroic from Mythic /1.3; Violent Swarm'),
(937, 2, 162784, 73030, 'log', 'Mythic combat log 2026-08-05; Violent Swarm'),
(937, 1, 162785, 202568, 'log', 'Heroic from Mythic /1.3; Watcher of the Path'),
(937, 2, 162785, 263338, 'log', 'Mythic combat log 2026-08-05; Watcher of the Path'),
(937, 1, 162979, 56177, 'log', 'Heroic from Mythic /1.3; Lifedrinker'),
(937, 2, 162979, 73030, 'log', 'Mythic combat log 2026-08-05; Lifedrinker'),
(937, 1, 162980, 56177, 'log', 'Heroic from Mythic /1.3; Lifedrinker'),
(937, 2, 162980, 73030, 'log', 'Mythic combat log 2026-08-05; Lifedrinker'),
(937, 1, 162981, 37485, 'log', 'Heroic from Mythic /1.3; Lifedrinker'),
(937, 2, 162981, 48730, 'log', 'Mythic combat log 2026-08-05; Lifedrinker'),
(937, 1, 162982, 427319, 'log', 'Heroic from Mythic /1.3; Risen Cultist'),
(937, 2, 162982, 555515, 'log', 'Mythic combat log 2026-08-05; Risen Cultist'),
(937, 1, 162983, 150058, 'log', 'Heroic from Mythic /1.3; Risen Cultist'),
(937, 2, 162983, 195075, 'log', 'Mythic combat log 2026-08-05; Risen Cultist'),
(937, 1, 162988, 524988, 'log', 'Heroic from Mythic /1.3; Vol’zeen'),
(937, 2, 162988, 682485, 'log', 'Mythic combat log 2026-08-05; Vol’zeen');
