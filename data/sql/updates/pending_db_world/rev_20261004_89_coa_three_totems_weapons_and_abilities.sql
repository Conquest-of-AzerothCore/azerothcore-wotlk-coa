-- Three Totems mobs carry and use what players saw on CoA: a Grimtotem Marauder swings one axe and a Grimtotem Patrol
-- two, both use Heroic Strike and the Marauder charges; the Cruel Carrion Spirit knocks you off your feet and uses
-- Heroic Strike, as does the Owlish Totem's spirit. The axe is the one-handed axe 1905 of the stock Grimtotem
-- Mercenary; the spells are the low-level creature ones (Heroic Strike 25710 adds 11 weapon damage, Charge 22120 a
-- normal hit, Knockdown 5164 a 2 s stun), so a level 3-4 mob hits like a player's first rank. The Patrol shows its
-- second axe without off-hand swings, keeping its damage.
-- Grimtotem Guards and Villagers take simple starter-mob spells, INFERRED from mobs of their level: a Guard takes
-- Defensive Stance 7164 as it engages and Pummels 12555 (15 damage and an interrupt, the stock Grimtotem Mercenary's);
-- a Villager throws 10277 at range and once heals itself with Healing Wave 332 (45-54) when badly hurt.
-- The Funeral Guards cast Lightning Bolt, as players saw on CoA: the first rank 403 (13-15 Nature damage).
-- A Villager sometimes calls out as a fight begins, and a Funeral Guard always does, with their CoA lines as players
-- recorded them.
DELETE FROM `creature_equip_template` WHERE `CreatureID` IN (161809, 161810) AND `ID` = 1;
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`) VALUES
(161809, 1, 1905, 0, 0, 0),
(161810, 1, 1905, 1905, 0, 0);

UPDATE `creature` SET `equipment_id` = 1 WHERE `id` IN (161809, 161810);

-- Health as in video at level 3 (warrior base 71): a Marauder has 158, a Patrol 132.
UPDATE `creature_template` SET `HealthModifier` = 2.2254 WHERE `entry` = 161809;
UPDATE `creature_template` SET `HealthModifier` = 1.8592 WHERE `entry` = 161810;

UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` IN (161810, 161813, 161815, 161834, 161851);

DELETE FROM `creature_text` WHERE `CreatureID` IN (161815, 161813);
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Probability`, `comment`) VALUES
(161815, 0, 0, 'The red pigment of my tattoos was starting to fade...', 12, 100, 'Grimtotem Villager - aggro (CoA)'),
(161813, 0, 0, 'Defiler! The vultures have been making do with scraps for too long. They''ll rejoice when we feed them your corpse.', 12, 100, 'Funeral Guard - aggro (CoA)');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 161809 AND `source_type` = 0 AND `id` IN (1, 2);
DELETE FROM `smart_scripts` WHERE `entryorguid` = 161837 AND `source_type` = 0 AND `id` IN (4, 5);
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (161810, 161813, 161815, 161834, 161851) AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`,
    `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`,
    `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`,
    `target_o`, `comment`) VALUES
(161809, 0, 1, 0, 0, 0, 100, 0, 5000, 8000, 9000, 13000, 0, 0, 11, 25710, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Grimtotem Marauder - In Combat - Cast Heroic Strike'),
(161809, 0, 2, 0, 9, 0, 100, 0, 8, 25, 15000, 20000, 0, 0, 11, 22120, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Grimtotem Marauder - Victim 8-25 yd - Cast Charge'),
(161810, 0, 0, 0, 0, 0, 100, 0, 5000, 8000, 9000, 13000, 0, 0, 11, 25710, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Grimtotem Patrol - In Combat - Cast Heroic Strike'),
(161834, 0, 0, 0, 0, 0, 100, 0, 5000, 8000, 9000, 13000, 0, 0, 11, 25710, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Cruel Carrion Spirit - In Combat - Cast Heroic Strike'),
(161834, 0, 1, 0, 0, 0, 100, 0, 6000, 9000, 12000, 16000, 0, 0, 11, 5164, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Cruel Carrion Spirit - In Combat - Cast Knockdown'),
(161851, 0, 0, 0, 0, 0, 100, 0, 5000, 8000, 9000, 13000, 0, 0, 11, 25710, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Owlish Totem - In Combat - Cast Heroic Strike'),
(161837, 0, 4, 0, 4, 0, 100, 0, 0, 0, 0, 0, 0, 0, 11, 7164, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Grimtotem Guard - On Aggro - Cast Defensive Stance'),
(161837, 0, 5, 0, 0, 0, 100, 0, 6000, 9000, 10000, 15000, 0, 0, 11, 12555, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Grimtotem Guard - In Combat - Cast Pummel'),
(161815, 0, 0, 0, 9, 0, 100, 0, 5, 25, 6000, 9000, 0, 0, 11, 10277, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Grimtotem Villager - Victim 5-25 yd - Cast Throw'),
(161815, 0, 1, 0, 2, 0, 100, 1, 0, 40, 0, 0, 0, 0, 11, 332, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Grimtotem Villager - Below 40% Health - Cast Healing Wave (once)'),
(161815, 0, 2, 0, 4, 0, 30, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Grimtotem Villager - On Aggro - Say Line 0 (30%)'),
(161813, 0, 0, 0, 0, 0, 100, 0, 1000, 3000, 6000, 9000, 0, 0, 11, 403, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Funeral Guard - In Combat - Cast Lightning Bolt'),
(161813, 0, 1, 0, 4, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Funeral Guard - On Aggro - Say Line 0');
