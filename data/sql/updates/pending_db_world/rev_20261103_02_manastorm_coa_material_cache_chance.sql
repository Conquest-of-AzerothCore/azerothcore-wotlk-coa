-- Retention percentage after the existing category/item selection, only in enabled CoA loot mode.
-- A rejected selection leaves that category empty. Counts, gold and base weights are preserved.
-- 100 retains the original odds, 0 suppresses the item. Omitted items retain the original odds.
CREATE TABLE IF NOT EXISTS `manastorm_coa_material_cache_chance`
(
    `item_entry` INT UNSIGNED NOT NULL,
    `chance_pct` TINYINT UNSIGNED NOT NULL DEFAULT 100,
    PRIMARY KEY (`item_entry`),
    CONSTRAINT `chk_manastorm_coa_material_chance` CHECK (`chance_pct` <= 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELETE FROM `manastorm_coa_material_cache_chance` WHERE `item_entry` IN
(11382, 17010, 17011, 13468, 12360, 13926, 20725,
13463, 13464, 13465, 13466, 13467, 10620, 11370, 11371, 12359, 12365,
12361, 12364, 12799, 12800, 11754, 14047, 14256, 14342, 8170, 8171, 15417, 17012,
16202, 16203, 16204, 14343, 14344, 7076, 7078, 7080, 7082, 12803);
INSERT INTO `manastorm_coa_material_cache_chance` (`item_entry`, `chance_pct`) VALUES
-- Rare raid materials and scarce crafted/reagent items: 75% less frequent.
(11382, 25), -- Blood of the Mountain
(17010, 25), -- Fiery Core
(17011, 25), -- Lava Core
(13468, 25), -- Black Lotus
(12360, 25), -- Arcanite Bar
(13926, 25), -- Golden Pearl
(20725, 25), -- Nexus Crystal
-- Late-game profession materials: 50% less frequent.
(13463, 50), -- Dreamfoil
(13464, 50), -- Golden Sansam
(13465, 50), -- Mountain Silversage
(13466, 50), -- Plaguebloom
(13467, 50), -- Icecap
(10620, 50), -- Thorium Ore
(11370, 50), -- Dark Iron Ore
(11371, 50), -- Dark Iron Bar
(12359, 50), -- Thorium Bar
(12365, 50), -- Dense Stone
(12361, 50), -- Blue Sapphire
(12364, 50), -- Huge Emerald
(12799, 50), -- Large Opal
(12800, 50), -- Azerothian Diamond
(11754, 50), -- Black Diamond
(14047, 50), -- Runecloth
(14256, 50), -- Felcloth
(14342, 50), -- Mooncloth
(8170, 50), -- Rugged Leather
(8171, 50), -- Rugged Hide
(15417, 50), -- Devilsaur Leather
(17012, 50), -- Core Leather
(16202, 50), -- Lesser Eternal Essence
(16203, 50), -- Greater Eternal Essence
(16204, 50), -- Illusion Dust
(14343, 50), -- Small Brilliant Shard
(14344, 50), -- Large Brilliant Shard
(7076, 50), -- Essence of Earth
(7078, 50), -- Essence of Fire
(7080, 50), -- Essence of Water
(7082, 50), -- Essence of Air
(12803, 50); -- Living Essence
