-- #12717 Chronomancer: Unstable Chronoglass (503836) missing summon creature 506015
-- Display 24868 (COT_HourGlass_redo.mdx) and type 12 from exiles-db-export creature.csv.gz (2026-09-13) and CreatureDisplayInfo.dbc.
START TRANSACTION;

INSERT INTO `creature_template` (`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `unit_class`, `unit_flags`, `type`, `BaseAttackTime`, `RangeAttackTime`, `ScriptName`) VALUES
(506015, 'Unstable Chronoglass', 1, 1, 35, 1, 4, 12, 2000, 2000, 'npc_ascension_unstable_chronoglass') ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `faction` = VALUES(`faction`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `type` = VALUES(`type`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 506015;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(506015, 0, 24868, 1, 1);

COMMIT;
