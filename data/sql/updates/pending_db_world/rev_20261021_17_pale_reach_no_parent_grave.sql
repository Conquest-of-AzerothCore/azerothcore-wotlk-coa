-- No Parent Should Bury Their Child (175041): Noghan's grave lacked its headstone (Tomb 2300658, the stock Stormwind
-- gravestone, standing uphill of the Niche as on the realm, Redthedeer VOD Day 2) and the Niche sat level on a 15
-- degree slope, so one end floated. The Niche now follows the slope, and like the Ideals Are Poison clues it can
-- only be clicked while its quest still needs it (GO_FLAG_INTERACT_COND), so a buried keepsake cannot be buried
-- again. Aralia's completion text comes from the realm window (VOD YzysjpunNbs, 00:05:24).
UPDATE `gameobject` SET `position_z` = 167.591, `rotation0` = -0.132238, `rotation1` = 0.010566, `rotation2` = 0.991146,
    `rotation3` = -0.005653 WHERE `guid` = 9980000 AND `id` = 2300657;

DELETE FROM `gameobject` WHERE `guid` = 9989905;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(9989905, 2300658, 0, 0, 0, 1, 1, -7557.2, 1162.11, 167.84, 3.153, 0, 0, 0.99998, -0.0057, 300, 100, 1, '', 0, 'Headstone of Noghan Dolmen''s grave, Cresthairn cemetery');

DELETE FROM `gameobject_template_addon` WHERE `entry` IN (2300646, 2300647, 2300648, 2300649, 2300650, 2300657);
INSERT INTO `gameobject_template_addon` (`entry`, `faction`, `flags`, `mingold`, `maxgold`, `artkit0`, `artkit1`, `artkit2`, `artkit3`) VALUES
(2300646, 0, 4, 0, 0, 0, 0, 0, 0),
(2300647, 0, 4, 0, 0, 0, 0, 0, 0),
(2300648, 0, 4, 0, 0, 0, 0, 0, 0),
(2300649, 0, 4, 0, 0, 0, 0, 0, 0),
(2300650, 0, 4, 0, 0, 0, 0, 0, 0),
(2300657, 0, 4, 0, 0, 0, 0, 0, 0);

DELETE FROM `quest_offer_reward` WHERE `ID` = 175041;
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `Emote2`, `Emote3`, `Emote4`, `EmoteDelay1`, `EmoteDelay2`, `EmoteDelay3`, `EmoteDelay4`, `RewardText`, `VerifiedBuild`) VALUES
(175041, 0, 0, 0, 0, 0, 0, 0, 0, 'Have you done it?$B$B<Despite the circumstances, Aralia manages to offer a faint, tiny smile of gratitude.>$B$BI cannot pay you for what you have done for me. I could not, even if I were the wealthiest woman in the province.', 0);
