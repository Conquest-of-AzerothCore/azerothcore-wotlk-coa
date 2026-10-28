-- Restless Family Members 1660025: clicking a relative's remains in the Cain crypt summoned the relative at once. On
-- Ascension the player prays first (#6197; CoA footage shows the "Heartfelt Prayer" cast bar and its holy glow at the
-- remains). The remains now make the player cast Heartfelt Prayer 256701, the 3 s holy cast Northshire's relics use
-- (its spell_dbc row: unit target, 30 yd), at an invisible marker standing on them; the cross cast needs a unit target.
-- The marker copies Northshire's [KC] markers (161880). It answers the completed prayer by summoning the relative,
-- who attacks the player as before, and despawns the remains until they respawn. Moving or being interrupted summons
-- nothing.
INSERT INTO `creature_template` (`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `unit_class`, `unit_flags`,
    `dynamicflags`, `type`, `AIName`, `flags_extra`) VALUES
(9300261, '[KC] Cain Remains', 1, 1, 35, 1, 33554432, 256, 0, 'SmartAI', 0)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`),
    `faction` = VALUES(`faction`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`),
    `dynamicflags` = VALUES(`dynamicflags`), `type` = VALUES(`type`), `AIName` = VALUES(`AIName`),
    `flags_extra` = VALUES(`flags_extra`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 9300261;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(9300261, 0, 11686, 1, 1);
DELETE FROM `creature` WHERE `guid` IN (9003731, 9003732, 9003733, 9003734);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`,
    `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`,
    `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`,
    `CreateObject`, `Comment`) VALUES
(9003731, 9300261, 0, 0, 0, 1, 1, 0, 1767.97, 1974.13, 124.7, 4.38, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0,
    'CoA Cain crypt: prayer marker on Mother''s remains'),
(9003732, 9300261, 0, 0, 0, 1, 1, 0, 1795.55, 1973.23, 124.7, 5.95, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0,
    'CoA Cain crypt: prayer marker on Father''s remains'),
(9003733, 9300261, 0, 0, 0, 1, 1, 0, 1751.59, 1947.12, 133.51, 0, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0,
    'CoA Cain crypt: prayer marker on Cousin Salem''s remains'),
(9003734, 9300261, 0, 0, 0, 1, 1, 0, 1785.96, 1928.36, 133.04, 5.95, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0,
    'CoA Cain crypt: prayer marker on Uncle Abel''s remains');
DELETE FROM `smart_scripts` WHERE (`entryorguid` IN (2300540, 2300541, 2300542, 2300543) AND `source_type` = 1)
    OR (`entryorguid` IN (-9003731, -9003732, -9003733, -9003734) AND `source_type` = 0);
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
    `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
    `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`,
    `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`,
    `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(2300540, 1, 0, 0, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 86, 256701, 0, 7, 0, 0, 0, 10, 9003731, 9300261, 0, 0, 0, 0, 0, 0,
    'Remains of Riscell''s relatives - On Use - Invoker casts Heartfelt Prayer at the marker'),
(2300541, 1, 0, 0, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 86, 256701, 0, 7, 0, 0, 0, 10, 9003732, 9300261, 0, 0, 0, 0, 0, 0,
    'Remains of Riscell''s relatives - On Use - Invoker casts Heartfelt Prayer at the marker'),
(2300542, 1, 0, 0, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 86, 256701, 0, 7, 0, 0, 0, 10, 9003733, 9300261, 0, 0, 0, 0, 0, 0,
    'Remains of Riscell''s relatives - On Use - Invoker casts Heartfelt Prayer at the marker'),
(2300543, 1, 0, 0, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 86, 256701, 0, 7, 0, 0, 0, 10, 9003734, 9300261, 0, 0, 0, 0, 0, 0,
    'Remains of Riscell''s relatives - On Use - Invoker casts Heartfelt Prayer at the marker'),
(-9003731, 0, 0, 1, 8, 0, 100, 0, 256701, 0, 0, 0, 0, 0, 12, 161762, 1, 120000, 1, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0,
    'Cain remains marker - On Heartfelt Prayer Hit - Summon Mother'),
(-9003731, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 14, 7916000, 2300540, 0, 0, 0, 0, 0, 0,
    'Cain remains marker - Linked - Despawn the remains until they respawn'),
(-9003732, 0, 0, 1, 8, 0, 100, 0, 256701, 0, 0, 0, 0, 0, 12, 161763, 1, 120000, 1, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0,
    'Cain remains marker - On Heartfelt Prayer Hit - Summon Father'),
(-9003732, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 14, 7916001, 2300541, 0, 0, 0, 0, 0, 0,
    'Cain remains marker - Linked - Despawn the remains until they respawn'),
(-9003733, 0, 0, 1, 8, 0, 100, 0, 256701, 0, 0, 0, 0, 0, 12, 161764, 1, 120000, 1, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0,
    'Cain remains marker - On Heartfelt Prayer Hit - Summon Cousin Salem'),
(-9003733, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 14, 7916002, 2300542, 0, 0, 0, 0, 0, 0,
    'Cain remains marker - Linked - Despawn the remains until they respawn'),
(-9003734, 0, 0, 1, 8, 0, 100, 0, 256701, 0, 0, 0, 0, 0, 12, 161765, 1, 120000, 1, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0,
    'Cain remains marker - On Heartfelt Prayer Hit - Summon Uncle Abel'),
(-9003734, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 14, 7916003, 2300543, 0, 0, 0, 0, 0, 0,
    'Cain remains marker - Linked - Despawn the remains until they respawn');
