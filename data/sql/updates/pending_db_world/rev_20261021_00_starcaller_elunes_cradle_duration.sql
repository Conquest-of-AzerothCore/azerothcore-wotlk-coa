-- Elune's Cradle (#7531): the area 807992 lasts 12 sec (duration index 29),
-- but its description never states the duration, so Warden's Blade's
-- Aspect of the Goddess line (which embeds @s:807992:0@) omits it too.
-- Republish the DBC description with the duration added.
-- Confirm in game: hover Warden's Blade and Elune's Cradle and read 12 sec.

DELETE FROM `coa_client_spell_description` WHERE `ID` IN (807992);
INSERT INTO `coa_client_spell_description` (`ID`,`Description`) VALUES
(807992,'Creates an area of rejuvenating stars around the enemy for $d, healing up to $i allies within $a1 yds for ${$m1*$<scalingbp>+$BH*0.08} every $t1 sec.');
