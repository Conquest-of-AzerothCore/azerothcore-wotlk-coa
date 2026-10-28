-- Elude (Ranger stealth 801345) shares the client's Stealth form 30 with Rogue
-- Stealth and Runeshroud (500288). rev_20261015_06 set form 30 to BonusActionBar 0
-- so Runeshroud keeps the main bar, but one form cannot serve two bars: that also
-- killed the stealth-bar switch for Elude and Rogues (#7915, gamebreaking).
-- Restore the native stealth bar (BonusActionBar 1, matching
-- SpellShapeshiftForm.dbc) so stealth pages again. Giving Runeshroud a private
-- bar would need its own form, which the 32-bit stance fields cannot express for
-- its stealth-gated spells, so that stays a separate follow-up instead of
-- breaking stealth a second time.
DELETE FROM `coa_client_shapeshift_form` WHERE `ID` = 30;
INSERT INTO `coa_client_shapeshift_form` (`ID`, `BonusActionBar`) VALUES
(30, 1);
