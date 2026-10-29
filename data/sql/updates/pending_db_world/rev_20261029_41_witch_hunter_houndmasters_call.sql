-- Houndmaster's Call: changelog entry 71842 (2026-08-25) raised its ranged attack power scaling to 55%; the client text still shows 35%.
DELETE FROM `coa_client_spell_description` WHERE `ID` = 802273;
INSERT INTO `coa_client_spell_description` (`ID`, `Description`, `ToolTip`) VALUES
(802273, 'Command your |cffffffffShadow Hounds|r to leap upon an enemy target, dealing two strikes for ${$706332m2*$<scalingbp>2+$RAP*0.55} Shadow damage.', '');
