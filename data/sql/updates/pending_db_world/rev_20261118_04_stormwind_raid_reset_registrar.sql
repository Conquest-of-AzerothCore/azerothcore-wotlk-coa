--
-- Unlimited personal and bot-raid resets; the flat fee is CoA.RaidReset.CostGold in worldserver.conf.
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`,
    `unit_class`, `type`, `ScriptName`)
VALUES (9990501, 'Raid Registrar', 'Raid Lock Resets', 60, 60, 35, 1, 1, 7, 'npc_coa_raid_reset')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`),
    `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 9990501;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES (9990501, 0, 12923, 1, 1);

DELETE FROM `npc_text` WHERE `ID` = 9990502;
INSERT INTO `npc_text` (`ID`, `text0_0`, `Probability0`)
VALUES (9990502,
    CONCAT('I can clear your raid locks, or yours and those of your raid bots. ',
    'Speak to me again whenever you need a reset. ',
    'The quoted fee covers the entire operation; other players must clear their own raid locks.'), 1);

-- Stand beside the existing Stormwind Callboard, using its height and facing.
DELETE FROM `creature` WHERE `guid` = 9990501;
INSERT INTO `creature` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`,
    `orientation`, `spawntimesecs`, `MovementType`)
SELECT 9990501, 9990501, `map`, 1, 1, `position_x` - 2, `position_y` + 2, `position_z`, `orientation`, 120, 0
FROM `gameobject` WHERE `guid` = 7905400 AND `id` = 402000 AND `map` = 0;
