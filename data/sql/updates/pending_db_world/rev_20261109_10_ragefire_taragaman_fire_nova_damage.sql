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

-- Ragefire Chasm: Taragaman the Hungerer's novas hit far too softly at level 60 (#11768): Fire Nova about 2k.
-- Fire Nova x3, Massive Fire Nova x5, as the tester asked.
DELETE FROM `coa_dungeon_creature_damage` WHERE `entry` = 11520 AND `spell_id` IN (11970, 2102516);
INSERT INTO `coa_dungeon_creature_damage` (`entry`, `spell_id`, `multiplier`, `comment`) VALUES
(11520, 11970, 3, 'Taragaman the Hungerer: Fire Nova x3'),
(11520, 2102516, 5, 'Taragaman the Hungerer: Massive Fire Nova x5');
