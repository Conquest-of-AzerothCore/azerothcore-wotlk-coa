-- Basalthane's real loot table, pulled from AtlasLoot's Classic item database
-- (refLootEntry 10185, Basalthane's original pre-rename entry) -- 17 items,
-- one random drop per kill at an equal ~5.88% (1/17) chance each, matching
-- AtlasLoot's own ItemDropRates.lua ([10185] = {[1] = 0.0588}).
--
-- lootid is shared across all 4 difficulty entries (set to 10189, the Normal
-- entry) so only one set of creature_loot_template rows is needed.

UPDATE `creature_template` SET `lootid` = 10189 WHERE `entry` IN (10189, 10190, 10191, 10192);

DELETE FROM `creature_loot_template` WHERE `Entry` = 10189;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Chance`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
    (10189, 15717, 5.88, 1, 1, 1, 'Drakon Soul Shard'),
    (10189, 18086, 5.88, 1, 1, 1, 'Dreadshot'),
    (10189, 18087, 5.88, 1, 1, 1, 'Fissured Warplate'),
    (10189, 18107, 5.88, 1, 1, 1, 'Ashen Drape'),
    (10189, 18108, 5.88, 1, 1, 1, 'Ash Stitched Gauntlets'),
    (10189, 18109, 5.88, 1, 1, 1, 'Obsidian Signet'),
    (10189, 18110, 5.88, 1, 1, 1, 'Obsidian Emberlance'),
    (10189, 18112, 5.88, 1, 1, 1, 'Eruption Cord'),
    (10189, 18124, 5.88, 1, 1, 1, 'Basalt Pauldrons'),
    (10189, 18125, 5.88, 1, 1, 1, 'Emberthorn'),
    (10189, 18126, 5.88, 1, 1, 1, 'Infernos, the Extinguished'),
    (10189, 18210, 5.88, 1, 1, 1, 'Draconic Effigy'),
    (10189, 18548, 5.88, 1, 1, 1, 'Wyrmguard Talisman'),
    (10189, 18549, 5.88, 1, 1, 1, 'Molten Visor'),
    (10189, 18571, 5.88, 1, 1, 1, 'Living Lavastone Conduit'),
    (10189, 18572, 5.88, 1, 1, 1, 'Corelit Igneous'),
    (10189, 18906, 5.88, 1, 1, 1, 'Obsidian Heartseeker');
