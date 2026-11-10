-- Per-spawn variety for character-model creatures: AscensionCreaturePresetMgr picks each spawn's skin, face, hair
-- style, hair colour and facial hair from these lists (space-separated values or ranges such as 0-24), seeded by the
-- spawn id, for the preset row of the same entry and gender. An empty list keeps the preset's own value.
CREATE TABLE IF NOT EXISTS `creature_display_preset_variety` (
  `entry` INT UNSIGNED NOT NULL,
  `gender` TINYINT UNSIGNED NOT NULL,
  `skins` VARCHAR(255) NOT NULL DEFAULT '',
  `faces` VARCHAR(255) NOT NULL DEFAULT '',
  `hair_styles` VARCHAR(255) NOT NULL DEFAULT '',
  `hair_colors` VARCHAR(255) NOT NULL DEFAULT '',
  `facial_hairs` VARCHAR(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`entry`, `gender`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;
