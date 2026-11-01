-- Strength of the Black Empire (Dreadnought's void monstrosity, 680556): the transform used display 28844
-- (FacelessOne2 brute at DBC scale 4) and ScaleBlackEmpire then shrank the player to 0.25, so the client drew the
-- full-size model first and visibly shrank it. Display 280073 is the FacelessOne2 brute with the purple skin and
-- void fx texture at DBC scale 0.75, confirmed in game against Ascension footage of Dreadnought. It is drawn at
-- its final size, so no object scale change follows (transforms ignore DisplayScale, and ScaleBlackEmpire only
-- acts on display 28844). The custom display has no creature_model_info row, which makes the client fall back to
-- a default model, so it is added here.
UPDATE `creature_template_model` SET `CreatureDisplayID` = 280073, `DisplayScale` = 1 WHERE `CreatureID` = 250043 AND `Idx` = 0;

DELETE FROM `creature_model_info` WHERE `DisplayID` = 280073;
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`) VALUES
(280073, 1.0, 1.0, 0, 0);
