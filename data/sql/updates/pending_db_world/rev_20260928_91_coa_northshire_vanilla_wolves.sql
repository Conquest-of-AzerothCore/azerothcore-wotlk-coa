-- Northshire wolves, Wolves Across the Border (33) and Eagan Peltskinner (5261) as in CoA: vanilla wolves, Tough Wolf Meat
UPDATE `creature_template` SET `name` = 'Timber Wolf' WHERE `entry` = 69;
UPDATE `creature_template` SET `name` = 'Young Wolf' WHERE `entry` = 299;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 604 WHERE `CreatureID` = 69 AND `Idx` = 0;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 447 WHERE `CreatureID` = 299 AND `Idx` = 0;
UPDATE `creature_template_addon` SET `auras` = NULL WHERE `entry` IN (69, 299) AND `auras` = '71764';
UPDATE `creature_loot_template` SET `Item` = 750 WHERE `Entry` IN (69, 299) AND `Item` = 50432;
UPDATE `creature_questitem` SET `ItemId` = 750 WHERE `CreatureEntry` IN (69, 299) AND `ItemId` = 50432;
UPDATE `quest_template` SET `RequiredItemId1` = 750,
`LogDescription` = 'Bring 8 pieces of Tough Wolf Meat to Eagan Peltskinner outside Northshire Abbey.',
`QuestDescription` = 'I hate those nasty timber wolves! But I sure like eating wolf steaks... Bring me tough wolf meat and I will exchange it for something you\'ll find useful.$B$BTough wolf meat is gathered from hunting the timber wolves and young wolves wandering the Northshire countryside.'
WHERE `ID` = 33;
UPDATE `quest_request_items` SET `CompletionText` = 'Hey $N. How goes the hunt for wolves?' WHERE `ID` = 33;
UPDATE `quest_template` SET `QuestDescription` = 'Eagan Peltskinner is looking for someone to hunt wolves for him. That\'s good news, because we\'re seeing a lot more wolves in Northshire Valley lately.' WHERE `ID` = 5261;
