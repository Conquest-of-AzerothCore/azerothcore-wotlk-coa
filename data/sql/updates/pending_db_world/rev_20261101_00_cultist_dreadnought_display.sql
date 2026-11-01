-- Strength of the Black Empire (Dreadnought's void monstrosity, 680556): the transform used display 28844
-- (FacelessOne2 brute at DBC scale 4) and ScaleBlackEmpire then shrank the player to 0.25, so the client drew the
-- full-size model first and visibly shrank it. Display 280071 is the same model and blue skin at DBC scale 1.
-- Transforms ignore DisplayScale, so ScaleBlackEmpire now applies a mild 0.75 object scale on 280071 to match
-- the Dreadnought size seen on Ascension. 280071 already has its creature_model_info row.
UPDATE `creature_template_model` SET `CreatureDisplayID` = 280071, `DisplayScale` = 1 WHERE `CreatureID` = 250043 AND `Idx` = 0;
