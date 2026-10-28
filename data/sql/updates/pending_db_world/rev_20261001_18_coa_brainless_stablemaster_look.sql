-- Brainless Stablemaster 161755 is a Forsaken stable master in CoA footage; his CoA display 652012 is in neither
-- DBC, and the stand-in 1196 (Rotting Ancestor) read as a corpse. He takes the stock Forsaken stable master look of
-- Theodore Mont Claire 9279 (INFERRED), and turns from the doorway to face into the stable: toward the centre of
-- DUSKWOOD_STABLE.WMO (1884.1, 1949.9), 4.6 yd from his CoA track point ST8685.
DELETE FROM `creature_template_model` WHERE `CreatureID` = 161755;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(161755, 0, 9279, 1, 1);
UPDATE `creature` SET `orientation` = 2.38 WHERE `guid` = 9010010 AND `id` = 161755;
