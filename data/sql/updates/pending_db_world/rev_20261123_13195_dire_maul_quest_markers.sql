-- Unfinished Gordok Business (1318, 7703), The Madness Within (7461) and The Instigator's Enchantment (8950): their
-- Dire Maul markers were drawn on Silverpine's map (map 0, world map area 21), over Hillsbrad and Alterac. Each
-- point is a Dire Maul spawn: The Prince's Chest (go guid 6), Captain Kromcrush (guid 248081), Immol'thar (248037),
-- Prince Tortheldrin (248022), 14358 (247502) and 16032 (247694). Same values as 7461 id 3 and 7463 (#13193).
UPDATE `quest_poi` SET `MapID` = 429, `WorldMapAreaId` = 699, `Floor` = 0
WHERE (`QuestID` IN (1318, 7703) AND `id` IN (0, 1))
   OR (`QuestID` = 7461 AND `id` IN (0, 1, 2))
   OR (`QuestID` = 8950 AND `id` IN (0, 1));
