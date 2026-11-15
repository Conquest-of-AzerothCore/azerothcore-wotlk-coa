-- CoA: Gorn Axefist (75133) <Riding Trainer> only stood in Durotar, so Horde players in the Barrens had no riding
-- trainer (#11925). An Ascension client cache (and gameplay video) shows a mount stand just north of Ratchet:
-- Gorn, John Stallion <Steed Salesman>, Yerg the Ambassador <The Ambassador> (mount vendor), a Pinto horse, a
-- Dire Wolf and an Empty Signpost. Recreate it at the captured positions.

-- John Stallion has no captured vendor list, so he is set dressing only.
DELETE FROM `creature_template` WHERE `entry` IN (75132, 415000);
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `type`) VALUES
(75132, 'John Stallion', 'Steed Salesman', 1, 1, 35, 0, 1, 7),
(415000, 'Yerg the Ambassador', 'The Ambassador', 1, 1, 35, 128, 1, 7);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (75132, 415000);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(75132, 0, 3274, 1, 1),
(415000, 0, 7191, 1, 1);

DELETE FROM `npc_vendor` WHERE `entry` = 415000;
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`) VALUES
(415000, 0, 12302), (415000, 1, 12303), (415000, 2, 12353), (415000, 3, 12354), (415000, 4, 13326),
(415000, 5, 13327), (415000, 6, 13328), (415000, 7, 13329), (415000, 8, 15292), (415000, 9, 15293);

DELETE FROM `creature` WHERE `guid` BETWEEN 7905116 AND 7905120;
INSERT INTO `creature` (`guid`, `id`, `map`, `position_x`, `position_y`, `position_z`, `orientation`, `Comment`) VALUES
(7905116, 75133, 1, -955.512, -3635.21, 16.08, 2.91207, 'Gorn Axefist, Ratchet (#11925)'),
(7905117, 75132, 1, -960.069, -3636.72, 16.903, 5.47235, 'John Stallion, Ratchet (#11925)'),
(7905118, 415000, 1, -959.73, -3632.47, 17.476, 1.96086, 'Yerg the Ambassador, Ratchet (#11925)'),
(7905119, 307, 1, -960.348, -3634.57, 17.3, 5.57992, 'Pinto, Ratchet mount stand (#11925)'),
(7905120, 4271, 1, -957.842, -3633.387, 17.047, 4.94875, 'Dire Wolf, Ratchet mount stand (#11925)');

DELETE FROM `gameobject` WHERE `guid` = 12101050;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation2`, `rotation3`, `spawntimesecs`, `state`, `Comment`) VALUES
(12101050, 188232, 1, -959.427, -3633.49, 17.306, 0, 0, 1, 300, 1, 'Empty Signpost, Ratchet mount stand (#11925)');
