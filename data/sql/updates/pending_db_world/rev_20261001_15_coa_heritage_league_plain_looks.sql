-- Heritage League camp, Cain Family Estate: CoA footage shows Riscell Cain 161740 and Kalis 161746 as plain Forsaken
-- in worn, tattered clothes; rev_20260926_10 had given them richer stand-ins (Sir Malory Wheeler 15113, Martin
-- Lindsey 12290). Their CoA displays (652005, 652007) are in neither DBC, so they take stock Forsaken commoner looks:
-- Riscell the Brill mushroom farmer Hamlin Atkins 1635 (dark shirt, brown trousers), Kalis the Undercity fungus
-- vendor Morley Bates 2640 (brown worn tunic) (INFERRED).
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (161740, 161746);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(161740, 0, 1635, 1, 1),
(161746, 0, 2640, 1, 1);
