-- Annihilation (504581, #7465) is not a normally-learned ability; it is the temporary replacement
-- AscensionXoroth.cpp swaps in for 800340 (Knight of Xoroth skill line 64, SkillLineAbility row 86489)
-- while auras 706502 and 712294 are active, so the player actually learns 504581 and loses 800340.
-- 504581 has no SkillLineAbility row of its own, so the client has no tab for it and lists it under
-- General, the same defect and fix shape as Primal Weapons (#8295, rev_20261020_83).
-- The client only places a spell into a tab when its SkillLineAbility row already exists, so an
-- unused existing row id must be repurposed rather than inserted fresh. Row 1323 (reused by the Primal
-- Weapons fix) is the only row in the client's SkillLineAbility.dbc whose own Spell does not exist at
-- all; every other row's spell is a real, playable ability. Row 777 is instead a duplicate of row 12820:
-- both map spell 965426 ("Meditate", SkillLine 38, RaceMask 0, ClassMask 512 = Druid) and differ only in
-- MinSkillLineRank (1 against 0), which AcquireMethod 0 ignores. Repurposing row 777 leaves row 12820
-- covering spell 965426, which the build creator data references, so that spell keeps its tab.
DELETE FROM `skilllineability_dbc` WHERE `ID` = 777;
INSERT INTO `skilllineability_dbc` (`ID`, `SkillLine`, `Spell`, `RaceMask`, `ClassMask`, `ExcludeRace`, `ExcludeClass`, `MinSkillLineRank`, `SupercededBySpell`, `AcquireMethod`, `TrivialSkillLineRankHigh`, `TrivialSkillLineRankLow`, `CharacterPoints_1`, `CharacterPoints_2`) VALUES
(777, 64, 504581, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0);

DELETE FROM `coa_client_skill_line_ability` WHERE `ID` = 777;
INSERT INTO `coa_client_skill_line_ability` (`ID`, `SkillLine`) VALUES
(777, 64);
