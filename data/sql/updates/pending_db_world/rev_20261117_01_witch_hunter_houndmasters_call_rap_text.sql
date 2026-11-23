-- Houndmaster's Call (802273): the stray "2" after $<scalingbp> hid the ranged attack power term in the client text (owner ruling O-39).
DELETE FROM `coa_client_spell_description` WHERE `ID` = 802273;
INSERT INTO `coa_client_spell_description` (`ID`, `Description`, `ToolTip`) VALUES
(802273, 'Command your |cffffffffShadow Hounds|r to leap upon an enemy target, dealing two strikes for ${($706332m2+90)*$<scalingbp>+$RAP*0.55} Shadow damage.', '');
