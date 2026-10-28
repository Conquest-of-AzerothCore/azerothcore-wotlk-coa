-- #4979: Homebound Runestone (560316) summons creature 50058 (SummonProperties 61), which had no
-- creature_template row anywhere in this repo, so SummonCreature silently failed and nothing appeared.
-- Identity (name, CreatureDisplayID 154351) is the one calibrated community source that names entry 50058:
-- hertigservices/ascension-data exiles-db-export-2026-09-13, table `creature`, row id=50058 ("Primordial
-- Portal", display_ids={154351}). Display 154351 is confirmed present in CreatureDisplayInfo.dbc.
-- Everything else follows the neutral level-one marker defaults already used for other Runemaster summon
-- markers (rev_20260914_06_runemaster_travel.sql); no ScriptName is set, since that migration's
-- npc_ascension_runemaster_marker AI is specific to the Echo Rune/Warpdagger travel bookkeeping.
-- Without a creature_model_info row, CreatureTemplate::GetFirstVisibleModel skips a display it cannot find
-- model info for and falls back to the default model, so one is added here too (same precedent defaults).
DELETE FROM `creature_template_model` WHERE `CreatureID` = 50058;
INSERT INTO `creature_template` (`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `unit_class`, `type`)
SELECT 50058, 'Primordial Portal', 1, 1, 35, 1, 11
WHERE NOT EXISTS (SELECT 1 FROM `creature_template` WHERE `entry` = 50058);
UPDATE `creature_template` SET `name` = 'Primordial Portal', `minlevel` = 1, `maxlevel` = 1,
    `faction` = 35, `unit_class` = 1, `type` = 11 WHERE `entry` = 50058;
DELETE FROM `creature_template_model` WHERE `CreatureID` = 50058;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES (50058, 0, 154351, 1, 1);
DELETE FROM `creature_model_info` WHERE `DisplayID` = 154351;
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`)
VALUES (154351, 0.5, 0, 2);
