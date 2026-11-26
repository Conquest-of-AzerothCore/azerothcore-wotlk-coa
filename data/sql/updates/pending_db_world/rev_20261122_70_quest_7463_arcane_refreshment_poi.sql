-- Arcane Refreshment (7463): both map markers belong to Dire Maul (map 429, world map area 699), where Hydrospawn
-- (guid 248418) and Lorekeeper Lydros (guid 247567) stand and where client QuestSuperTrack 4018 places the turn-in.
-- The inherited rows drew the Dire Maul points on Silverpine's map (map 0, area 21), over Hillsbrad and Alterac.
UPDATE `quest_poi` SET `MapID` = 429, `WorldMapAreaId` = 699, `Floor` = 0 WHERE `QuestID` = 7463 AND `id` IN (0, 1);
