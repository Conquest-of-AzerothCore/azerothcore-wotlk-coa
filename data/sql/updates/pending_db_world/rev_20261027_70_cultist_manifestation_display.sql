-- Manifestation of Y'Shaarj (#9105): the proc used display 28844 (FacelessOne/Herald of the Depths at 0.5 scale),
-- a huge model, not the small adds the tooltip implies. Display 427990 is the same entry 397771's actual display
-- id, cross-confirmed by two independent client captures (conquest-of-azeroth, 2026-08-06 and 2026-09-04) and the
-- Exiles DB export (db.exil.es/npc/397771), all naming it "Manifestation of Sha". DisplayScale reverts to the
-- column default (1): the 0.5 override existed only to shrink the oversized 28844 model.
UPDATE `creature_template_model` SET `CreatureDisplayID` = 427990, `DisplayScale` = 1 WHERE `CreatureID` = 397771 AND `Idx` = 0;
