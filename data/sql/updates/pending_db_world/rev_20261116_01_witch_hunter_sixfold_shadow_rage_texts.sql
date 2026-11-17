-- Sixfold Shot (807364, inlined in 500567): owner ruling O-19 (2026-11-15) with mentor D-154; Shadow Rage (804192, inlined in 705455): owner ruling O-27 (D-214, D-215), both texts render the server's RAP terms.
DELETE FROM `coa_client_spell_description` WHERE `ID` IN (807364, 804192);
INSERT INTO `coa_client_spell_description` (`ID`, `Description`, `ToolTip`) VALUES
(807364, 'Unleash 6 quick shots across $d, each dealing $807527s1% Ranged Weapon Damage plus ${45+$807527ppl2+$RAP*0.25} Physical damage and generating $/10;521228s1 Rage. and $521228s2% maximum mana.\r\n\r\nUsable while moving.', ''),
(804192, 'Auto attacks have a $h% chance to deal an additional ${$m3*$<scalingbp>+$RAP*0.15} Shadow Damage. Lasts $d.', '');
