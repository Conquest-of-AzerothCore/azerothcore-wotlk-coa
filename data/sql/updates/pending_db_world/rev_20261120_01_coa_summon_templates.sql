-- CoA creature-cache dataset 836dab599218015bced50dfb87a5a3b022f745b8636ae86e632e22e0349b1730 (2026-11-18).
-- Source file: cachedata/by-locale/enUS/by-mode/conquest-of-azeroth/creaturecache.tsv.gz.
-- The cache records the names, displays, families, types, flags, and health and mana modifiers.
-- Faction, unit class, attack timing, and Mindbender model geometry use core summon defaults.
-- Run after rev_20261003_20_ascension_creature_families.sql widens the creature family column.
START TRANSACTION;

DELETE FROM `creature_model_info` WHERE `DisplayID` = 464978;
INSERT INTO `creature_model_info`
    (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`, `VerifiedBuild`)
VALUES (464978, 0.389, 1.5, 2, 0, 12340);

INSERT INTO `creature_template`
    (`entry`, `name`, `faction`, `unit_class`, `BaseAttackTime`, `RangeAttackTime`,
     `family`, `type`, `type_flags`, `HealthModifier`, `ManaModifier`, `VerifiedBuild`)
VALUES
    (50095, 'Faceless Servant', 35, 1, 2000, 2000, 544, 10, 1, 1.0, 1.0, 12340),
    (50308, 'Infinite Protector', 35, 1, 2000, 2000, 550, 2, 1, 1.3, 1.0, 12340),
    (50315, 'Spirit of the Hawk', 35, 1, 2000, 2000, 0, 1, 1, 1.0, 1.0, 12340),
    (50317, 'Spirit of the Turtle', 35, 1, 2000, 2000, 0, 1, 0, 1.1, 1.0, 12340),
    (50318, 'Spirit of the Tiger', 35, 1, 2000, 2000, 0, 1, 1, 1.0, 1.0, 12340),
    (50319, 'Spirit of Earth', 35, 1, 2000, 2000, 0, 1, 1, 1.0, 1.0, 12340),
    (50328, 'Mindbender', 35, 2, 2000, 2000, 553, 12, 0, 1.0, 1.0, 12340)
ON DUPLICATE KEY UPDATE `entry` = `creature_template`.`entry`;

DELETE FROM `creature_template_model`
WHERE `CreatureID` IN (50095, 50308, 50315, 50317, 50318, 50319, 50328) AND `Idx` = 0;
INSERT INTO `creature_template_model`
    (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`)
VALUES
    (50095, 0, 28465, 1, 1, 12340),
    (50308, 0, 20515, 1, 1, 12340),
    (50315, 0, 22633, 1, 1, 12340),
    (50317, 0, 4829, 1, 1, 12340),
    (50318, 0, 11031, 1, 1, 12340),
    (50319, 0, 9589, 1, 1, 12340),
    (50328, 0, 464978, 1, 1, 12340);

-- Summon: Mindbender (803062) references Entropic Union (800022) in its client tooltip.
DELETE FROM `creature_template_spell` WHERE `CreatureID` = 50328 AND `Index` = 0;
INSERT INTO `creature_template_spell` (`CreatureID`, `Index`, `Spell`, `VerifiedBuild`)
VALUES (50328, 0, 800022, 12340);

COMMIT;
