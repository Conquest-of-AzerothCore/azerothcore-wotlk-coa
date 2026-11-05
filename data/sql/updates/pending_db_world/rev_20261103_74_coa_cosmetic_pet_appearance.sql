-- Wardrobe cosmetic pet appearances the client's Appearances.dbc does not have. The server adds each row to the
-- wardrobe and sends it to the client once its extension is ready (SMSG_PATCH_APPEARANCES, display type CREATURE). category_id is a
-- cosmetic pet category (AppearanceCategories 33-37); the realm columns match the Appearances.dbc realm flags.
-- preview_creature is the creature the wardrobe draws for it (0: creature_entry). The wardrobe draws a creature's
-- display, so a creature dressed at runtime (creature_display_preset) needs a stand-in whose display has its look baked in.
CREATE TABLE IF NOT EXISTS `coa_cosmetic_pet_appearance` (
    `appearance_id` INT UNSIGNED NOT NULL,
    `token_item` INT UNSIGNED NOT NULL,
    `creature_entry` INT UNSIGNED NOT NULL,
    `category_id` TINYINT UNSIGNED NOT NULL,
    `preview_creature` INT UNSIGNED NOT NULL DEFAULT 0,
    `live` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `seasonal` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `league` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `ptr` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `development` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    PRIMARY KEY (`appearance_id`),
    UNIQUE KEY `token_item` (`token_item`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
