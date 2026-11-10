-- Gilgaen (161728) looked like a ghost in The Eyrie (#8352): rev_20260924_10 gave him the stand-in display 12269,
-- whose CreatureDisplayInfo alpha is 128, so the client drew him translucent. 4246 has the same model (55) and
-- the same CreatureDisplayInfoExtra (2511) at full opacity, so his gaunt look stays.
UPDATE `creature_template_model` SET `CreatureDisplayID` = 4246 WHERE `CreatureID` = 161728 AND `Idx` = 0 AND `CreatureDisplayID` = 12269;
