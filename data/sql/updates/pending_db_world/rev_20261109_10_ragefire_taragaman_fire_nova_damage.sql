-- coa_dungeon_creature_damage rows can now name one spell (spell_id); 0 keeps the row for all of the creature's damage.
SELECT IF(NOT EXISTS (SELECT 1 FROM `information_schema`.`COLUMNS`
        WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = 'coa_dungeon_creature_damage'
        AND `COLUMN_NAME` = 'spell_id'),
    "ALTER TABLE `coa_dungeon_creature_damage` "
        "ADD COLUMN `spell_id` INT UNSIGNED NOT NULL DEFAULT 0 AFTER `entry`, "
        "DROP PRIMARY KEY, ADD PRIMARY KEY (`entry`, `spell_id`)",
    'DO 0') INTO @coa_dungeon_creature_damage_spell;
PREPARE `coa_dungeon_creature_damage_spell` FROM @coa_dungeon_creature_damage_spell;
EXECUTE `coa_dungeon_creature_damage_spell`;
DEALLOCATE PREPARE `coa_dungeon_creature_damage_spell`;

-- Ragefire Chasm: Taragaman the Hungerer's Fire Nova hit for about 2k at level 60 (#11768); three times that.
DELETE FROM `coa_dungeon_creature_damage` WHERE `entry` = 11520 AND `spell_id` = 11970;
INSERT INTO `coa_dungeon_creature_damage` (`entry`, `spell_id`, `multiplier`, `comment`) VALUES
(11520, 11970, 3, 'Taragaman the Hungerer: Fire Nova x3');
