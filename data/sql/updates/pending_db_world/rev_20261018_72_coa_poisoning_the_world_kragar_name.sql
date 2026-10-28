-- Poisoning the World (200026, Valley of Trials): the quest text and objective 2 name "Nekai the Reanimator", but the
-- trainer the concoction must hit is Kragar the Reanimator (502925, Necromancer Trainer; name and subname from
-- creaturecache 502925, SOURCED-CACHE). No creature is called Nekai, so the text now names the NPC the player sees.
UPDATE `quest_template` SET
    `ObjectiveText2` = 'Kragar the Reanimator',
    `QuestDescription` = REPLACE(`QuestDescription`, 'Nekai the Reanimator', 'Kragar the Reanimator')
WHERE `ID` = 200026;
