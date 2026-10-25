-- Lexicon Ring pickup (#8948): back to the realm's hand-authored spot on the Tower of Azora top floor;
-- the LootCollector move had put it under the ground floor.
UPDATE `gameobject` SET `position_x` = -9540.927734, `position_y` = -724.318359, `position_z` = 100.40554
WHERE `guid` = 6940697 AND `id` = 90233;
