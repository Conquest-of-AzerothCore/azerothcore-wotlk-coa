-- Whether `scaling_level` already holds the client's item key. Rows stored before this column held the
-- plain level; with CoA.ItemScaling.Native.LevelKeys the worldserver converts them once at startup.
ALTER TABLE `character_item_scaling`
  ADD COLUMN `client_key` TINYINT UNSIGNED NOT NULL DEFAULT 0 AFTER `scaling_level`;
