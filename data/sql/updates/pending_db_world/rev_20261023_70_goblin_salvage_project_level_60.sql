-- CoA Goblin Salvage Project: the questline can be taken from level 30 to 60, not only up to 40.
UPDATE `quest_template_addon` SET `MaxLevel` = 60
WHERE `ID` IN (176000, 176001, 176002, 176003, 176004, 176011, 176012, 176013, 176014);
