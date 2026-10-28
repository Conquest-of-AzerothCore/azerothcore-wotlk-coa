-- The Demon Inside 200035 (Knight of Xoroth, "Kill the crazed Undead") is CoA's own quest, but nothing places its
-- target: CoA's creature cache has no record of 299226, the client has no QuestSuperTrack point for the quest
-- and the atlas has no sighting. rev_20260923_09 made the Crazed Undead's look and spot up (INFERRED), so the
-- spawn and the quest's relations go until a source places him; no later quest requires 200035.
DELETE FROM `creature` WHERE `guid` = 9003721 AND `id` = 299226;
DELETE FROM `creature_queststarter` WHERE `id` = 9300250 AND `quest` = 200035;
DELETE FROM `creature_questender` WHERE `id` = 9300250 AND `quest` = 200035;
