DELETE FROM `spell_cooldown_overrides` WHERE `Id` IN (9931368, 9931369);
INSERT INTO `spell_cooldown_overrides`
(`Id`, `RecoveryTime`, `CategoryRecoveryTime`, `StartRecoveryTime`, `StartRecoveryCategory`, `Comment`) VALUES
(9931368, 300000, 0, 0, 0, 'Portable Sawmill'),
(9931369, 300000, 0, 0, 0, 'Compact Portable Sawmill');

UPDATE `item_template` SET `spellcooldown_1` = 300000
WHERE `entry` = 1777064 AND `spellid_1` = 9931368;
