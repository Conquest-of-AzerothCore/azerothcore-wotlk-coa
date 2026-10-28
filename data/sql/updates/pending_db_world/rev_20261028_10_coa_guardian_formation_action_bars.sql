--
-- Guardian formations are shapeshift forms 35 (Line Formation), 36 (Tower Formation) and 37 (Assault
-- Formation). The client's own SpellShapeshiftForm.dbc gives them BonusActionBar 2, 3 and 1 - the same
-- paging the warrior stances get from rows 17 to 19 - so entering a formation pages the main bar and its
-- hotkeys to that formation's own bar. An earlier change wrote 0 for all three into this override table,
-- which leaves the client on the main bar and is what "Guardian stances/formations no longer change to
-- their respective bar" and "Changing Guardian formation no longer switches to that formation's
-- configured skill bar" describe.
--
-- This table is exactly what SMSG_PATCH_SPELL_SHAPESHIFT_FORM (0x0949) streams at login:
-- AscensionCompat's LoadShapeshiftFormPatchRows reads it, walks the server's SpellShapeshiftForm.dbc and
-- sends one row per id it finds here, so a row present here replaces the client's value. The DBC values are
-- written back explicitly instead of dropping the rows so the intended paging stays pinned even if a later
-- client DBC carries something else.
--
CREATE TABLE IF NOT EXISTS `coa_client_shapeshift_form` (
  `ID` INT UNSIGNED NOT NULL,
  `BonusActionBar` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELETE FROM `coa_client_shapeshift_form` WHERE `ID` IN (35, 36, 37);
INSERT INTO `coa_client_shapeshift_form` (`ID`, `BonusActionBar`) VALUES
(35, 2),
(36, 3),
(37, 1);
