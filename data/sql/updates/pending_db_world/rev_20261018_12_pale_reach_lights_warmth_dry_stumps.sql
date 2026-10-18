-- Light's Warmth (175056): the Dry Stumps could not be picked up. Their item drops only for players whose quest lists it,
-- and the quest listed it nowhere (its objectives are credits), so every Dry Stump showed an empty loot window. List the
-- Dry Stump item as the quest's source item: it then drops while a player on the quest holds fewer than its limit (5).
UPDATE `quest_template` SET `ItemDrop1` = 559882, `ItemDropQuantity1` = 0 WHERE `ID` = 175056;
