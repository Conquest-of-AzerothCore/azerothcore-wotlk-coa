-- Deathstalker Exsangue 161741: the stand-in 19533 (rev_20261001_24) showed bare legs. CoA footage has him in dark
-- leather from shoulders to boots, spiked shoulder pads and a face-covering hood: the stock Forsaken Assassin 4154
-- (black cloth under a dark leather chest, shoulder pads, the Deathstalker hood) (INFERRED).
DELETE FROM `creature_template_model` WHERE `CreatureID` = 161741;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(161741, 0, 4154, 1, 1);
