-- Transmogrifier Gimbly (79027, model 48811) was shrunk to 0.1411 by the companion scale pass: its client bounding box
-- reaches 6.63 yd below the feet, so the 1.2 yd height cap read an 8.5 yd tall model. The visible model is 1.87 yd tall;
-- 0.64 gives the same 1.2 yd companion height.
UPDATE `creature_template_model` SET `DisplayScale` = 0.64 WHERE `CreatureID` = 79027 AND `Idx` = 0 AND `DisplayScale` BETWEEN 0.1410 AND 0.1412;
