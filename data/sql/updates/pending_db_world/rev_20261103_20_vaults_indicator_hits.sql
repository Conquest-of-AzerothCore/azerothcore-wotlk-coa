-- Vaults of the Inquisition (map 936): two attacks hit well outside what the client draws for them.
-- Voidflare (256927) targets cone 24, which the core reads as 24 degrees out to the DBC radius of 40 yards; its graphic
-- spells\spell_deceiver_presence_cone.m2 at a fixed 0.6 outlines 90 degrees out to 18 yards. The script keeps the
-- reach to 18 yards.
-- Spectral Strike (256975) is drawn as a line (9fx_raid3_jailer_line_projection at a fixed 1.7: 53 yards long, 2.5 to
-- each side) but hit a 24 degree cone out to 100 yards. Its cone opens to 180 degrees so the script's line filter
-- decides alone.
DELETE FROM `spell_cone` WHERE `ID` IN (256927, 256975);
INSERT INTO `spell_cone` (`ID`, `ConeDegrees`) VALUES (256927, 90), (256975, 180);
DELETE FROM `spell_script_names` WHERE `spell_id` IN (256927, 256975) AND `ScriptName` IN ('spell_coa_vaults_voidflare', 'spell_coa_vaults_spectral_strike');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(256927, 'spell_coa_vaults_voidflare'),
(256975, 'spell_coa_vaults_spectral_strike');
