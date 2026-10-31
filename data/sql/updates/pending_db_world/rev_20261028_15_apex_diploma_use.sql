-- The three hides are epic quest items; the diploma is a readable scroll that
-- grants the title through SkinpeelerDiplomaScript when it is used.

UPDATE `item_template`
SET `Quality` = 4
WHERE `entry` IN (1009101, 1009102, 1009103);

UPDATE `item_template`
SET `spellid_1` = 18282, `spelltrigger_1` = 0, `spellcharges_1` = -1, `spellcooldown_1` = -1,
    `ScriptName` = 'SkinpeelerDiplomaScript'
WHERE `entry` = 1009100;
