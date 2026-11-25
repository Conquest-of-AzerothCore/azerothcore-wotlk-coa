-- Halrin Kenari <Cenarion Circle Quartermaster> (115175, #13151): rev_20261118_12625 fell back to display 55
-- (raw NightElfMale.mdx, ExtendedDisplayInfoID 0, no textures) because Ascension display 650603 is absent from the
-- client DBC and 115175 has no creature_display_preset, leaving him untextured in-game. Use 17320 (Fedryen Swiftspear
-- <Cenarion Expedition Quartermaster>, ModelID 55, ExtendedDisplayInfoID 11968, baked texture in stock 3.3.5a).
DELETE FROM `creature_template_model` WHERE `CreatureID` = 115175 AND `Idx` = 0;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`,
    `VerifiedBuild`) VALUES
(115175, 0, 17320, 1, 1, 0);
