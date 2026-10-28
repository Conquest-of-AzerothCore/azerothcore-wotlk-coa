-- Stellar Convergence (#7523): 572784 triggers the Eclipsing Arrows mark
-- 574154 on every party and raid member in range, but its description only
-- names the mark. Lunar Cascade 704725 and the Eclipsing Arrows talent 800504
-- explain it: the mark lasts $574154d and Huntress Shot heals marked allies.
-- Republish the description with that explanation, using 800504's heal
-- formula so the shown amount matches the healing done.
-- Confirm in game: hover Stellar Convergence and read the duration and heal.

DELETE FROM `coa_client_spell_description` WHERE `ID` IN (572784);
INSERT INTO `coa_client_spell_description` (`ID`,`Description`) VALUES
(572784,'Applies |cFFFFFFFFEclipsing Arrows|r to all party and raid members within $a1 yds for $574154d.\r\n\r\nCasting |cffffffffHuntress Shot|r heals marked allies for ${($704232m1+$704232ppl1+$SP*.3)*((100+$887014ppl3)/100)}.');
