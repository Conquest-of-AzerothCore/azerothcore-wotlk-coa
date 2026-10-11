-- Blackrock Depths - Prison: the Ring of Law completes the wing in the Dungeon Finder on Normal too, as on
-- Heroic and Mythic (Ascension's DungeonEncounter data: 1230 and 2230 end dungeons 1030 and 2030). On Normal
-- High Interrogator Gerstahn still ended it, so finishing the arena event did not complete the random dungeon.
UPDATE `instance_encounters` SET `lastEncounterDungeon` = 30 WHERE `entry` = 230;
UPDATE `instance_encounters` SET `lastEncounterDungeon` = 0 WHERE `entry` = 227;
