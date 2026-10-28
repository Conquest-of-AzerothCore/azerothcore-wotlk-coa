-- Brood Trap (803525) summons 52121, which live names "Brood Egg" and shows as the aqir egg cluster 412059 (client creature cache), not the spider egg 23058.
-- The 412059 model is 5.3 yards wide and no live source records a scale; 0.4 matches the cluster in live arena footage when compared in game.
UPDATE `creature_template` SET `name` = 'Brood Egg' WHERE `entry` = 52121;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 412059, `DisplayScale` = 0.4 WHERE `CreatureID` = 52121 AND `Idx` = 0;
DELETE FROM `creature_model_info` WHERE `DisplayID` = 412059;
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`) VALUES
(412059, 0.5, 1, 2);
