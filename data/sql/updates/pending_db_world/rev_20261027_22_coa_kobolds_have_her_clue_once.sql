-- The Kobolds Have Her (175071): each Shadewell Cave clue (2300677-2300681) counts once per character and then
-- disappears for that character, as the Shadewell Falls clues of They Grabbed Her By The Ankle already do. Before,
-- one clue could be clicked five times to finish the quest.
UPDATE `gameobject_template` SET `ScriptName` = 'go_coa_shadewell_cave_clue' WHERE `entry` BETWEEN 2300677 AND 2300681;
