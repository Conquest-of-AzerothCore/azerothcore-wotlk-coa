-- Hoax Unclaimed Belongings (item 555005) casts Summon Highrisk Chest (823035), whose SPELL_EFFECT_TRANS_DOOR
-- places gameobject 823035; without a template the cast places nothing. The decoy copies the Ascension export's
-- Unclaimed Belongings chest (818001: type 3, display 259, no lock, no loot).
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `size`, `Data0`, `Data1`, `ScriptName`)
VALUES (823035, 3, 259, 'Unclaimed Belongings', 1, 0, 0, '')
ON DUPLICATE KEY UPDATE `type` = 3, `displayId` = 259, `name` = 'Unclaimed Belongings', `size` = 1,
  `Data0` = 0, `Data1` = 0, `ScriptName` = '';
