-- Starcaller Huntress Shot (#7527): the DBC Lunar Eclipse line promises 1
-- additional Scattered Star while Moon Priest 92134 and the server both
-- apply 2 (1 base + 2 for 3 total, verified in game). All five ranks
-- carry the identical stale line behind the $?s92134 Moon Priest gate.
--
-- Root cause is text, not mechanics: AscensionStarcallerAbilities applies
-- Stars(..., 1) on every Huntress hit plus Stars(..., 2) while Lunar
-- Eclipse 800386 is active, and the Moon Priest talent text already says
-- "Applies 2 additional Scattered Stars". Only the per-rank tooltip line
-- disagrees, so republish each rank's unchanged DBC text with the count
-- fixed through coa_client_spell_description, which the server streams
-- to the client (SMSG_PATCH_SPELL); DELETE+INSERT stays idempotent.
-- Confirm in game: spec Moon Priest, hover Huntress Shot during Lunar
-- Eclipse, check the 2-star wording and 3 Scattered Star stacks on hit.

DELETE FROM `coa_client_spell_description` WHERE `ID` IN (680220, 680586, 680587, 680588, 680589);
INSERT INTO `coa_client_spell_description` (`ID`,`Description`) VALUES
(680220,'|cffffffffDrains $805553s1% Maximum Mana|r\r\n|cff66ccffApplies 1 Scattered Star|r\r\nFire an enchanted arrow, dealing $s3% Ranged Weapon Damage plus ${$m2+$POWER1*0.0385+$spa*0.25} as Arcane damage, increased further based on your maximum mana.$?s92134[\r\n\r\n|cffffffffLunar Eclipse|r: Applies 2 additional |cFFFFFFFFScattered Stars|r.][]\r\n@s:804378:0@'),
(680586,'|cffffffffDrains $805553s1% Maximum Mana|r\r\n|cff66ccffApplies 1 Scattered Star|r\r\nFire an enchanted arrow, dealing $s3% Ranged Weapon Damage plus ${$m2+$POWER1*0.0385+$spa*0.25} as Arcane damage, increased further based on your maximum mana.$?s92134[\r\n\r\n|cffffffffLunar Eclipse|r: Applies 2 additional |cFFFFFFFFScattered Stars|r.][]\r\n@s:804378:0@'),
(680587,'|cffffffffDrains $805553s1% Maximum Mana|r\r\n|cff66ccffApplies 1 Scattered Star|r\r\nFire an enchanted arrow, dealing $s3% Ranged Weapon Damage plus ${$m2+$POWER1*0.0385+$spa*0.25} as Arcane damage, increased further based on your maximum mana.$?s92134[\r\n\r\n|cffffffffLunar Eclipse|r: Applies 2 additional |cFFFFFFFFScattered Stars|r.][]\r\n@s:804378:0@'),
(680588,'|cffffffffDrains $805553s1% Maximum Mana|r\r\n|cff66ccffApplies 1 Scattered Star|r\r\nFire an enchanted arrow, dealing $s3% Ranged Weapon Damage plus ${$m2+$POWER1*0.0385+$spa*0.25} as Arcane damage, increased further based on your maximum mana.$?s92134[\r\n\r\n|cffffffffLunar Eclipse|r: Applies 2 additional |cFFFFFFFFScattered Stars|r.][]\r\n@s:804378:0@'),
(680589,'|cffffffffDrains $805553s1% Maximum Mana|r\r\n|cff66ccffApplies 1 Scattered Star|r\r\nFire an enchanted arrow, dealing $s3% Ranged Weapon Damage plus ${$m2+$POWER1*0.0385+$spa*0.25} as Arcane damage, increased further based on your maximum mana.$?s92134[\r\n\r\n|cffffffffLunar Eclipse|r: Applies 2 additional |cFFFFFFFFScattered Stars|r.][]\r\n@s:804378:0@');
