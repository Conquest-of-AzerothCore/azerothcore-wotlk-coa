-- Houndmaster's Call: changelog entries 71841 and 71842 (2026-08-25) added 90 base damage and raised its ranged attack
-- power scaling to 55%; the client text still shows the old base and 35%.
DELETE FROM `coa_client_spell_description` WHERE `ID` = 802273;
INSERT INTO `coa_client_spell_description` (`ID`, `Description`, `ToolTip`) VALUES
(802273, 'Command your |cffffffffShadow Hounds|r to leap upon an enemy target, dealing two strikes for ${($706332m2+90)*$<scalingbp>2+$RAP*0.55} Shadow damage.', '');
