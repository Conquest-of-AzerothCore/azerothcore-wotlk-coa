-- Deathstalker Exsangue 161741 (The True Heir of the Cains) is a man in black leather with his face covered in
-- CoA footage; rev_20260926_10's stand-in 2863 is a female Deathstalker. His CoA display is not in the client: he
-- takes the Forsaken Keldor the Lost 19533 (black leather tunic and trousers, face-covering hood) (INFERRED).
DELETE FROM `creature_template_model` WHERE `CreatureID` = 161741;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(161741, 0, 19533, 1, 1);
