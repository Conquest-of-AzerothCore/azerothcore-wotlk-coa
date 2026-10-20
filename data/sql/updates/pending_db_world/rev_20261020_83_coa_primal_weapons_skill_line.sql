-- Primal Weapons (537218, #8295) had no SkillLineAbility row, so the client had no
-- spellbook tab for it and listed it under General at best. Every player-visible
-- Wildwalker ability uses skill line 110 ("Wildwalker"), while the hidden helpers
-- (563262, 806070, 806071) carry none.
-- The client only places a spell into a tab when its SkillLineAbility row already
-- exists: SMSG_PATCH_SKILL_LINE_ABILITY runs the native re-placement for an
-- overwritten row (erase the old spell mapping, patch, re-add to the book) and skips
-- it for an inserted one. Row 1323 is therefore reused: its spell 84387 exists in
-- neither the client nor the server Spell.dbc, so nothing loses a tab.
-- Authored in the world's skilllineability_dbc override and listed in
-- coa_client_skill_line_ability so the row is streamed; no client patch.
DELETE FROM `skilllineability_dbc` WHERE `ID` = 1323;
INSERT INTO `skilllineability_dbc` (`ID`, `SkillLine`, `Spell`, `RaceMask`, `ClassMask`, `ExcludeRace`, `ExcludeClass`, `MinSkillLineRank`, `SupercededBySpell`, `AcquireMethod`, `TrivialSkillLineRankHigh`, `TrivialSkillLineRankLow`, `CharacterPoints_1`, `CharacterPoints_2`) VALUES
(1323, 110, 537218, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0);

DELETE FROM `coa_client_skill_line_ability` WHERE `ID` = 1323;
INSERT INTO `coa_client_skill_line_ability` (`ID`, `SkillLine`) VALUES
(1323, 110);
