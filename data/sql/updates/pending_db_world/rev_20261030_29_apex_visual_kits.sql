-- Custom visual kits used by the apex encounters. Like the spell rows, these existed
-- only in the local database, so the client had nothing to draw.
START TRANSACTION;
DELETE FROM `spellvisualkitmodelattach_dbc` WHERE `ParentSpellVisualKitID` BETWEEN 99000 AND 99199;
INSERT INTO `spellvisualkitmodelattach_dbc` (`ParentSpellVisualKitID`, `SpellVisualEffectNameID`, `ID`, `AttachmentID`, `OffsetX`, `OffsetY`, `OffsetZ`, `Yaw`, `Pitch`, `Roll`) VALUES
('99091', '99093', '99091', '0', '0', '0', '0', '0', '0', '0'),
('99099', '99095', '99099', '0', '0', '0', '0', '0', '0', '0'),
('99102', '99096', '99102', '0', '0', '0', '0', '0', '0', '0'),
('99114', '99116', '99114', '19', '0', '0', '0', '0', '0', '0');
COMMIT;
