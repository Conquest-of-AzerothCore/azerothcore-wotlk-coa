-- COA-10191: Searing Hatchling and Searing Whelp skinning rows were five independent GroupId 0 rolls summing to 100%, so about 27% of skins were empty.
-- Peer dragonkin tables put the same kind of row in GroupId 1, which always yields exactly one result.
UPDATE `skinning_loot_template` SET `GroupId` = 1 WHERE `Entry` IN (4323, 4324) AND `GroupId` = 0;
