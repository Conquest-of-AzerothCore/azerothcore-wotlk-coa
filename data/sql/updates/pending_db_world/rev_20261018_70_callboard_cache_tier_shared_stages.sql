-- A Callboard cache tier is released with the stage of its cache on the shared release ladder
-- (Ascension.CallboardCache.ReleaseStage): the table keeps the item level thresholds only.
ALTER TABLE `ascension_callboard_cache_tier` DROP COLUMN `ReleaseStage`;
