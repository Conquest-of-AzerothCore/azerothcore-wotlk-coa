-- mod-ascension-compat: creature display presets (mirror-image NPCs).
--
-- AscensionCreaturePreset.cpp reads this table at startup; the feature commit
-- (#3983) shipped the code without the schema, so a fresh world DB aborted with
-- "[1146] Table 'acore_world.creature_display_preset' doesn't exist".
--
-- One row per (entry, display_id): the appearance (race/gender/class + custom
-- fields + worn item displays) to apply to a preset creature. Empty by default.
--
-- Filename is the update key recorded in `updates` (state = MODULE); do not
-- rename once applied.

CREATE TABLE IF NOT EXISTS `creature_display_preset` (
    `entry`       INT UNSIGNED NOT NULL,
    `display_id`  INT UNSIGNED NOT NULL,
    `race`        TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `gender`      TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `class`       TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `skin`        TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `face`        TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `hair`        TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `haircolor`   TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `facialhair`  TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `guild_id`    INT UNSIGNED NOT NULL DEFAULT 0,
    `item_head`      INT UNSIGNED NOT NULL DEFAULT 0,
    `item_shoulders` INT UNSIGNED NOT NULL DEFAULT 0,
    `item_body`      INT UNSIGNED NOT NULL DEFAULT 0,
    `item_chest`     INT UNSIGNED NOT NULL DEFAULT 0,
    `item_waist`     INT UNSIGNED NOT NULL DEFAULT 0,
    `item_legs`      INT UNSIGNED NOT NULL DEFAULT 0,
    `item_feet`      INT UNSIGNED NOT NULL DEFAULT 0,
    `item_wrists`    INT UNSIGNED NOT NULL DEFAULT 0,
    `item_hands`     INT UNSIGNED NOT NULL DEFAULT 0,
    `item_back`      INT UNSIGNED NOT NULL DEFAULT 0,
    `item_tabard`    INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`entry`, `display_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
