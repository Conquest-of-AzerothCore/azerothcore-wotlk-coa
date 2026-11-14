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

-- Ragefire Chasm: Taragaman the Hungerer's novas hit far too softly at level 60 (#11768).
-- He casts the SpellDifficulty variants: Fire Nova 154039 (Heroic) and 381390 (Mythic), Massive Fire Nova 2102517 and 2102518.
-- On Mythic our tester measured about 300 and 3k and asked for about 2k and 6k: Fire Nova x6.667, Massive Fire Nova x2.
-- Heroic hits 1.3 times softer than Mythic, as the other boss abilities do: Fire Nova x5.128, Massive Fire Nova x1.538.
-- Normal sets its own damage in CoADungeonNormal.
DELETE FROM `coa_dungeon_creature_damage` WHERE `entry` = 11520 AND `spell_id` IN (154039, 381390, 2102517, 2102518);
INSERT INTO `coa_dungeon_creature_damage` (`entry`, `spell_id`, `multiplier`, `comment`) VALUES
(11520, 154039, 5.128, 'Taragaman the Hungerer: Fire Nova (Heroic) x5.128'),
(11520, 381390, 6.667, 'Taragaman the Hungerer: Fire Nova (Mythic) x6.667'),
(11520, 2102517, 1.538, 'Taragaman the Hungerer: Massive Fire Nova (Heroic) x1.538'),
(11520, 2102518, 2, 'Taragaman the Hungerer: Massive Fire Nova (Mythic) x2');
