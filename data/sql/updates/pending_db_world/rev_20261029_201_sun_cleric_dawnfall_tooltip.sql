-- Dawnfall (806118): enemies carry only effects 1-2 and allies only effect 3, so the shared tooltip's live
-- ${$w1} and ${$w3} read 0% on whichever half is absent (#9781). Use the static $s1/$s3 values, and state
-- Solar Flare's own damage formula (807175) instead of Dawnfall's empty effect 2 amount.
DELETE FROM `coa_client_spell_description` WHERE `ID` = 806118;
INSERT INTO `coa_client_spell_description` (`ID`, `Description`, `ToolTip`) VALUES
(806118, 'Bring down the light of An\'she down at the target location for $d.\r\n\r\nWhile inside, allies receive $s3% increased healing from all sources and enemies take $s1% increased damage from you and are struck by a |cffffffffSolar Flare|R every $t2 sec.@s:807175:0@', 'Enemies inside take $s1% increased damage from the Sun Cleric and are struck by a Solar Flare, dealing ${$807175m2+$807175ppl2+$SP*0.26} Holyfire Damage every $t2 sec.\r\n\r\nAllies inside take $s3% increased healing from all sources.');
