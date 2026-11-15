-- Flamefist Claw (#10351): spelltrigger 2 with spellppmRate_1 0 and the spells' ProcChance 100 fired on every hit
-- although the tooltip promises 2ppm.
UPDATE `item_template` SET `spellppmRate_1` = 2
WHERE `entry` IN (1378534, 1380534, 1382534, 1384534, 1386534, 1392534) AND `spellppmRate_1` = 0;
