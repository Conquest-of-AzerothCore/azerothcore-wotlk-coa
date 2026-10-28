-- Eldya (161848, Vulture Cult, The Eyrie in Teldrassil): her model changes from the Evergrove Druid woman 20992 to
-- the Night Elf woman 4841.
--
-- WHERE EACH VALUE COMES FROM
--   161848, Idx 0, DisplayScale 1, Probability 1  her existing creature_template_model row
--     (rev_20260924_10_coa_teldrassil_vulture_cult.sql); only the display changes.
--   4841  approved by the user for #6260. Project Descension picked it for Eldya
--     (descension-server db/history/staging/ascension-area-repair/R1_DEFERRED.tsv:107, commit 78dcaeeb). Server and
--     installed client CreatureDisplayInfo.dbc both hold 4841: model 56 NightElfFemale.mdx, extra 3037 (race 4,
--     female). Her own CoA display 652083 (AscensionDB creaturecache) is still missing from the client.
--     The model info pairs 4841 with 4842, both Night Elf women (4842: model 56, extra 3038, race 4, female), so
--     the server shows either one.
DELETE FROM `creature_template_model` WHERE `CreatureID` = 161848 AND `Idx` = 0;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(161848, 0, 4841, 1, 1, NULL);
