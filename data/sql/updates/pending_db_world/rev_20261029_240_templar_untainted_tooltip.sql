-- Untainted (705298 talent, 705299 buff): 705299's effect 0 is SPELL_AURA_MOD_DAMAGE_TAKEN with a negative
-- base (-10), and aura_ascension_templar_lifecycle subtracts 0.1 x Stamina from it, so the reduction is
-- 10 + 0.1 x Stamina. The client text added the negative base to the positive Stamina term and read
-- "reduced by -0" at about 100 Stamina (#9895).
DELETE FROM `coa_client_spell_description` WHERE `ID` IN (705298, 705299);
INSERT INTO `coa_client_spell_description` (`ID`, `Description`, `ToolTip`) VALUES
(705298, 'Effectively healing yourself now reduces your Physical damage taken by ${-$705299m1+$STA*0.1} for $705299d.\r\n\r\nCan only occur every 15 sec.', ''),
(705299, '', 'Physical damage taken reduced by ${-$m1+$STA*0.1}.');
