-- Blessing of Yogg-Saron (#10521): with talent 807128, Herald of the Depths also applies 806769, which transforms
-- the Cultist into the Faceless Monstrosity (250044). Its display 28844 is the FacelessOne2 brute at DBC scale 4,
-- and transforms ignore DisplayScale, so the form was drawn at boss size. Display 280071 is the same model and skin
-- at DBC scale 1 (#5707), and already has its creature_model_info row.
UPDATE `creature_template_model` SET `CreatureDisplayID` = 280071, `DisplayScale` = 1
WHERE `CreatureID` = 250044 AND `Idx` = 0;
