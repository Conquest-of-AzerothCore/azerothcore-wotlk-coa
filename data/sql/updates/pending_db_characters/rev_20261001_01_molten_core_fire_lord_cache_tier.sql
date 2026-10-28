-- Cache of the Fire Lord (world item 2400040) carries no payload of its own, so the gear pool it
-- opens into (one of four, by raid difficulty - see pending_db_world's
-- rev_20261001_19_molten_core_fire_lord_cache.sql) has to be decided once, at the moment the
-- item instance is created from real Ragnaros loot, not at open time: reading the player's raid
-- difficulty *setting* when opening is exploitable (kill on Normal, flip to Ascended, open for
-- Ascended-tier gear). AscensionFireLordCache.cpp's PlayerScript binds the killed map's own
-- difficulty (Map::GetSpawnMode(), the same 0-3 Normal/Heroic/Mythic/Ascended convention
-- coa_mc_token_loot/FlexLoot.cpp already use) to the item's guid here, and the ItemScript deletes
-- the row once the cache is opened. A row absent at open time (a GM-added cache, or one looted
-- before this table existed) falls back to the player's current raid difficulty setting instead.
CREATE TABLE IF NOT EXISTS `coa_mc_fire_lord_cache_tier` (
  `ItemGuid` INT UNSIGNED NOT NULL,
  `RaidDifficulty` TINYINT UNSIGNED NOT NULL,
  PRIMARY KEY (`ItemGuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
