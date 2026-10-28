-- The Spit-Soaked Report (999933) is picked up from the Half-Devoured Protector, a corpse every faction can talk to, but it
-- is handed in to Archivist Selnor of Sentinel Hill, who is hostile to the Horde: Horde characters could take it and never
-- finish it. Like the rest of Selnor's chain, it is for the Alliance.
UPDATE `quest_template` SET `AllowableRaces` = 1101 WHERE `ID` = 999933;
