-- "The Three Sisters' Wisdom": "Cellar trapdoor in Grandmother's Remedy used" counts the trapdoor the user placed in the
-- Graysky herb shop's cellar (2310425, which takes the player into the passage below Graysky), not an unplaced copy.
UPDATE `quest_template` SET `RequiredNpcOrGo1` = -2310425 WHERE `ID` = 175203 AND `RequiredNpcOrGo1` = -2310423;
