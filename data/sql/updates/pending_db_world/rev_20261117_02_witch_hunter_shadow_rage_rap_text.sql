-- Shadow Rage (680275): the client text scaled with attack power and carried a stray ")"; the server uses ranged attack power (owner ruling O-39).
DELETE FROM `coa_client_spell_description` WHERE `ID` = 680275;
INSERT INTO `coa_client_spell_description` (`ID`, `Description`, `ToolTip`) VALUES
(680275, 'Ranged auto attacks deal an additional ${$m3+$RAP*0.15} Shadow Damage.', '');
