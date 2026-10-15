-- Runeshroud 500288 shifts into the client's "Stealth" form 30, whose SpellShapeshiftForm row carries BonusActionBar 1
-- and pages the main action bar to an empty stealth bar. Keep the player's own bar, as the Guardian formations do.
DELETE FROM `coa_client_shapeshift_form` WHERE `ID` = 30;
INSERT INTO `coa_client_shapeshift_form` (`ID`, `BonusActionBar`) VALUES
(30, 0);
