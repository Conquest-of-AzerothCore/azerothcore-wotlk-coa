-- #10807: Conjure Thunderkeg hands out Thunderale (item 2000150), which was Weak Thunder Ale: spell 804762 restored a
-- flat 17 health and 42 mana per tick for 18 sec, tiny at level 60. Thunderale is a conjured drink that
-- "Restores 6% of your health and mana per second for 25 sec. Must remain seated while drinking.", the same figures
-- Conjure Thunderale (807850) itself advertises. The core now turns 804762 into the percentage drink every Food spell
-- already is (OBS_MOD_HEALTH / OBS_MOD_POWER, 1 sec ticks, 25 sec); the client keeps the old amounts in its Spell.dbc,
-- so its tooltips are rewritten here with literal numbers. Fel Morsel (2000151) uses the same spell and follows it.
UPDATE `item_template` SET `name` = 'Thunderale' WHERE `entry` = 2000150;
DELETE FROM `coa_client_spell_description` WHERE `ID` = 804762;
INSERT INTO `coa_client_spell_description` (`ID`, `Description`, `ToolTip`) VALUES
(804762, 'Restores 6% of your health and mana per second for 25 sec. Must remain seated while drinking.', 'Restoring 6% of your health and mana per second.');
