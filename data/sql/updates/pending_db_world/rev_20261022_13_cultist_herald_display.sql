-- Herald of the Depths (#5707): the transform used display 28844 (FacelessOne at display scale 4) and a script then
-- shrank the player to 0.25, so the client drew the full-size model first and visibly shrank it. Display 280071 is
-- the same model and skin at display scale 1, the same final size without any scale change.
UPDATE `creature_template_model` SET `CreatureDisplayID` = 280071, `DisplayScale` = 1 WHERE `CreatureID` = 250042 AND `Idx` = 0;
