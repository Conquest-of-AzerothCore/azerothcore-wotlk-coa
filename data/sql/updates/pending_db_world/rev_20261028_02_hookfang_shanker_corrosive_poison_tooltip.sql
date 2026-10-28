-- Hookfang Shanker's (item 11635) proc Corrosive Poison (#7988): the client's own Spell.dbc description is
-- a constant zero, `${$abs(0)} Nature damage`, instead of the per-tick reference. The periodic damage aura
-- (effect 0, EffectBasePoints 0 / EffectDieSides 1 / EffectRealPointsPerLevel 0.25) is live and correct
-- (verified: level 55 - BaseLevel 1 = 54, 54 x 0.25 = 13 truncated +1 for the die = 14 Nature damage per
-- tick); only the client's own stored text names the wrong placeholder. AscensionCompat streams
-- `coa_client_spell_description` to every client as SMSG_PATCH_SPELL, so the correction is published here,
-- repeating the client's own sentence with `${$abs(0)}` replaced by the level-scaled reference `$s1`.
DELETE FROM `coa_client_spell_description` WHERE `ID` = 13526;
INSERT INTO `coa_client_spell_description` (`ID`, `Description`) VALUES
(13526, 'Corrosive acid that deals $s1 Nature damage every 3 sec and enables you to bypass $s2% of targets armor for $d.');
