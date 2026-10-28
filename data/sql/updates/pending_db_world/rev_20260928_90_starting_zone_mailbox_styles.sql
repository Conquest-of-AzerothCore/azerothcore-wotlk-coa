-- Starting zone mailboxes: use the local style, still usable by both factions
UPDATE `gameobject` SET `id` = 181236 WHERE `guid` = 6901512 AND `id` = 144570;
UPDATE `gameobject` SET `id` = 175864 WHERE `guid` IN (6901514, 6901515, 6901516) AND `id` = 188132;
