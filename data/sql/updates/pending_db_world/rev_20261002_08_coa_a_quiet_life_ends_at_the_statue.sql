-- A Quiet Life 200081 (Templar, Deathknell) is turned in at the Hidden Statue it sends the player to, not back at
-- Vaelion Grandbell (author's call; INFERRED). The statue becomes a quest giver object (type 2);
-- go_coa_deathknell_hidden_statue ignores clicks from players without the quest, who would get an empty greeting.
-- No source records the quest's turn-in text: CoA's quest cache holds no reward text, and no archive or database
-- export has any for the six A Quiet Life quests. This text is INFERRED, written for the statue.
UPDATE `gameobject_template` SET `type` = 2, `ScriptName` = 'go_coa_deathknell_hidden_statue' WHERE `entry` = 9301257;
DELETE FROM `creature_questender` WHERE `id` = 502803 AND `quest` = 200081;
DELETE FROM `gameobject_questender` WHERE `id` = 9301257 AND `quest` = 200081;
INSERT INTO `gameobject_questender` (`id`, `quest`) VALUES (9301257, 200081);
DELETE FROM `quest_offer_reward` WHERE `ID` = 200081;
INSERT INTO `quest_offer_reward` (`ID`, `RewardText`) VALUES
(200081, 'A weathered statue of a paladin stands in the gap, hidden where few would think to look.$B$BHere the noise of the world falls away. You can see why Vaelion makes the climb.');
