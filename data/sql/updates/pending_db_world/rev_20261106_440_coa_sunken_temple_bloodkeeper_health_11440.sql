-- jealous-sound/azerothcore-wotlk-coa#11440: Hakkari Bloodkeeper (8438), an add of the Avatar of Hakkar event, had no
-- coa_dungeon_health row, so on Heroic and Mythic it kept its Normal health. It has the shape of the other rank 1,
-- class 2 Sunken Temple elites (Hakkari Sapper 8336, Hakkari Frostwing 5291, Nightmare Suppressor 8497): same rows.
DELETE FROM `coa_dungeon_health` WHERE `map_id` = 109 AND `creature_entry` = 8438;
INSERT INTO `coa_dungeon_health` (`map_id`, `difficulty`, `creature_entry`, `max_health`, `evidence`, `source`) VALUES
(109, 2, 8438, 50818, 'model', 'siblings 8336, 5291, 8497; Hakkari Bloodkeeper not exported'),
(109, 1, 8438, 39091, 'model', 'Heroic from Mythic; siblings 8336, 5291, 8497; Hakkari Bloodkeeper not exported');
