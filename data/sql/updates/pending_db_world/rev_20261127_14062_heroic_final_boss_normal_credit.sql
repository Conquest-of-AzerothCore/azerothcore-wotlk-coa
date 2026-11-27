-- The Heroic and Mythic final-boss templates copied the Normal Dungeon Completion Credit (81042) from their Normal
-- templates, so a Heroic or Mythic clear completed the Normal "Dungeon Diving" daily. Ascension's captured data
-- carries 81042 only on the Normal templates (SUB creature.kill_credits, 2026-10-04: 39705, 162704, 162716; 139705
-- and 239705 have none). The Heroic and Mythic dailies keep their own credit from the Dungeon Finder completion.
UPDATE `creature_template` SET `KillCredit2` = 0 WHERE `entry` IN (139705, 239705) AND `KillCredit2` = 81042;
UPDATE `creature_template` SET `KillCredit1` = 0
WHERE `entry` IN (262704, 362704, 262716, 362716) AND `KillCredit1` = 81042;
