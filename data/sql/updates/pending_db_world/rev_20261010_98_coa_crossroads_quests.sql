-- Crossroads (The Barrens) Ascension quests 255078-255083 and their NPCs, restored from Ascension captures.
-- Quests: client quest cache, conquest-of-azeroth mode, captured 2026-09-10 (hertigservices/ascension-data); paragraph
-- breaks from the Dawnrise quest cache capture (2026-09-01). NPCs: client creature cache, same mode and date.
-- Givers and enders follow the quest texts and NextQuestInChain. Recorded on live realms (YouTube): reward texts of
-- 255082 (PrimitiveWoW Part 12, 2026-08-08, 22:12) and 255083 (Part 13, 2026-08-11, 09:00), Raj'iri and Naj'iri's
-- exchange (Part 12, 01:02; Part 13, 10:04 and 35:00), Voltzix Sprocketpop level 21 Orgrimmar (Part 12, 22:16)
-- and Rhuna level 35 Orgrimmar (JohnGamingFuntime, 2026-07-07, 17:44). Spawns stand on the quests' client
-- QuestSuperTrack/SuperTrack points (patch-M, identical in the server DBC), facing the town centre (inferred). The
-- 255080 ender is Raj'iri: its "Taz'iri" turn-in point 21368 lies 0.1 yd from Raj'iri's point 21366. Raj'iri, Martin
-- and Brumbof take Rhuna's and Voltzix's Orgrimmar faction (inferred). Quest item drops use the 80% chance of the
-- Barrens quest drops from the mobs the quest texts name, and Brumbof hands out the drumstick through a gossip option
-- (both inferred, no capture). Naj'iri takes her sister's faction. The client has none of the captured displays except
-- Brumbof's 2129, so the others use stand-ins from the client (captured display in brackets): Raj'iri 4087 (112912) and
-- Naj'iri 4089 (112911), troll women; Rhuna 2127 (256406), Una's tauren leatherworker; Martin Lesterfield 1574
-- (112978), a Forsaken merchant; Voltzix Sprocketpop 10472 (919573), Roxxik's goblin engineer. Draft: Naj'iri's spawn
-- and the other NPCs' levels are not restored yet.

INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `RewardNextQuest`,
  `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `Flags`, `RewardItem1`, `RewardAmount1`, `RewardItem2`,
  `RewardAmount2`, `RewardFactionID1`, `RewardFactionValue1`, `LogTitle`, `LogDescription`, `QuestDescription`,
  `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`,
  `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredItemId1`, `RequiredItemId2`,
  `RequiredItemCount1`, `RequiredItemCount2`)
VALUES
(255078, 2, 13, 9, 17, 255079, 5, 600, 405, 8, 375250, 100, 1397885, 1, 76, 5, 'Play It by Ear', 'Raj’iri wants to dance with her sister, but Naj’iri isn’t in the mood. Maybe some music will help get her off her feet. Collect a centaur windflute from Kolkar Wranglers, and Kolkar Stormers.', 'Ahh, I be feelin’ it in me bones today, mon! De spirits got me feet tappin’ and me heart drummin!$B$BBut me poor sister…she been broodin’ in de shade since sunrise. Won’t smile, won’t sway, won’t even hum a tune. It ain’t right.$B$BWhat we need be music!$B$BI been thinkin’…dem centaur camps nearby? Dey always got dem lightning-callin’ mages chantin’ and stompin’ through de day. Surely dey got an instrument or two lyin’ about.', '', 'Return to Raj''iri at the Crossroads.', 0, 0, 0, 0, 0, 0, 355118, 0, 1, 0),
(255079, 2, 15, 11, 17, 255080, 5, -300, 0, 8, 375250, 100, 1397885, 1, 76, 5, 'Finding the Rhythm', 'Maybe a flute was the wrong instrument. Gather 5 Hecklefang Hyena skins, 1 Barrens Giraffe Leather, and 3 silver. Then deliver it to Unah to make a drum.', 'Ahh…so de flute weren’t enough to stir her spirit. Shame, mon. It sang sweet, but her heart still be heavy.$B$BStill-we ain’t givin’ up! No, no, we just need somethin’ stronger. Somethin’ louder...a drum! Yes, dat be it!$B$BRhuna, de leatherworker, could stitch one together for us if she had de right materials...would you be willin'' to do dat for me poor old sister?', '', 'Bring the materials to Rhuna in the Barrens along with 3 Silver as payment.', 0, 0, 0, 0, 0, 0, 355119, 355120, 5, 1),
(255080, 2, 15, 11, 17, 0, 4, 600, 405, 8, 375250, 100, 1397885, 1, 76, 4, 'Dancing to the Beat', 'There’s been a party in the tauren lodge for a while with lots of dancing. Ask the drummer Brumbof, if he has an extra stick he can spare. Acquire the drumstick and deliver it to Taz’iri along with the drum.', 'This drum may be the finest in all of Kalimdor, but without a stick or mallet to strike it with...$B$BBefore you leave, check the lodge across the road, the drummer might have an extra stick lying around.', '', 'Return to Taz''iri at the Crossroads.', 0, 0, 0, 0, 0, 0, 355122, 0, 1, 0),
(255081, 2, 11, 7, 17, 0, 5, 600, 405, 8, 375250, 100, 1397885, 1, 76, 5, 'Understanding the Scriptures', 'Hearing of the power of the Burning Blade cult, Martin asks you to retrieve some of their demonic scriptures from Burning Blade Acolytes, and Burning Blade Bruisers so he can study them and perhaps learn something of their power.', 'Ah! What opportune timing!$B$BI am in dire need of a capable assistant! Yes, yes… you’ll do nicely.$B$BThe Burning Blade cultists have taken refuge upon the mountain just north of here, I wish to decode their scripture!$B$BI don''t care how you get it, bring me their writings so I-we may harness their power for our own!', '', 'Return to Martin Lesterfield at the Crossroads.', 0, 0, 0, 0, 0, 0, 355123, 0, 8, 0),
(255082, 2, 14, 10, 17, 255083, 5, 600, 405, 8, 375250, 100, 1397885, 1, 76, 5, 'Killing the Competition', 'Voltzix Sprocketpop wants you to kill Venture Co. forces at the sludge field to the north.', 'Ya know what ain''t good for business? Other goblins also doin'' business!$B$BEspecially in a perfectly good sludge field I was TRYING to use!$B$BVenture ain''t on good terms with the Horde anyways. Or anyone really. Not sure how they''re actually gettin'' money the way they go around makin'' enemies.$B$BWhy don''t ya go take ''em out, I get the sludge field, you all get less hostile forces around your town, and everyone''s happy!', '', 'Return to Voltzix Sprocketpop at the Crossroads.', 3282, 3284, 3285, 6, 6, 6, 0, 0, 0, 0),
(255083, 2, 16, 12, 17, 0, 5, 600, 405, 8, 375250, 100, 1397885, 1, 76, 5, 'Annihilating the Competition', 'Voltzix Sprocketpop wants you to kill Venture Co. forces at the Boulder Lode Mine to the north.', 'Problem with Venture, they get everywhere!$B$BNow they''re in my mines too! Perfectly good, mines full of very valuable gems, and they decided to help themselves!$B$BYou''ve proven good at takin'' those loses down a peg, go over to that mine and just do what you did last time!', '', 'Return to Voltzix Sprocketpop at the Crossroads.', 3283, 3286, 0, 8, 8, 0, 0, 0, 0, 0)
ON DUPLICATE KEY UPDATE `QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`),
    `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`),
    `RewardNextQuest` = VALUES(`RewardNextQuest`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`),
    `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`),
    `Flags` = VALUES(`Flags`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`),
    `RewardItem2` = VALUES(`RewardItem2`), `RewardAmount2` = VALUES(`RewardAmount2`),
    `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`),
    `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`),
    `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`),
    `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`),
    `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`),
    `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`),
    `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`),
    `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredItemId1` = VALUES(`RequiredItemId1`),
    `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`),
    `RequiredItemCount2` = VALUES(`RequiredItemCount2`);

DELETE FROM `quest_template_addon` WHERE `ID` IN (255079,255080,255083);
INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`) VALUES
(255079, 255078),
(255080, 255079),
(255083, 255082);

DELETE FROM `quest_offer_reward` WHERE `ID` IN (255082,255083);
INSERT INTO `quest_offer_reward` (`ID`, `RewardText`) VALUES
(255082, 'They''re dead? Good! Knew I could count on ya!'),
(255083, 'Sounds like that''s the last of ''em! Actually, I heard they''re packin'' up and heading back to...somewhere, I didn''t pay much attention.$B$BWhat matters is they''re leaving, something about hazard expenses.');

INSERT INTO `creature_template` (`entry`, `name`, `subname`, `npcflag`, `type`, `type_flags`, `HealthModifier`,
  `ManaModifier`)
VALUES
(41719, 'Raj''iri', NULL, 2, 7, 0, 1.032, 1),
(741719, 'Naj''iri', NULL, 0, 7, 0, 0.99072, 1),
(41739, 'Rhuna', 'Leatherworking Trainer', 2, 7, 134217728, 1.136, 1),
(741722, 'Martin Lesterfield', 'Scrolls and Oddities', 2, 7, 0, 1.136, 1),
(753513, 'Brumbof Bramstum', NULL, 0, 7, 0, 2.048, 1),
(753524, 'Voltzix Sprocketpop', 'Engineering Trainer', 2, 7, 0, 2.048, 1)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `npcflag` = VALUES(`npcflag`),
    `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `HealthModifier` = VALUES(`HealthModifier`),
    `ManaModifier` = VALUES(`ManaModifier`);

UPDATE `creature_template` SET `minlevel` = 35, `maxlevel` = 35, `faction` = 29 WHERE `entry` = 41739;
UPDATE `creature_template` SET `minlevel` = 21, `maxlevel` = 21, `faction` = 29 WHERE `entry` = 753524;
UPDATE `creature_template` SET `faction` = 29 WHERE `entry` IN (41719,741719,741722,753513);
UPDATE `creature_template` SET `unit_class` = 1 WHERE `entry` IN (41719,741719,41739,741722,753513,753524);
UPDATE `creature_template` SET `npcflag` = 1, `gossip_menu_id` = 9010700, `AIName` = 'SmartAI' WHERE `entry` = 753513;

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (41719,741719,41739,741722,753513,753524);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(41719, 0, 4087, 1, 1),
(741719, 0, 4089, 1, 1),
(41739, 0, 2127, 1, 1),
(741722, 0, 1574, 1, 1),
(753513, 0, 2129, 1, 1),
(753524, 0, 10472, 1, 1);

DELETE FROM `creature_queststarter` WHERE `quest` IN (255078,255079,255080,255081,255082,255083);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES
(41719, 255078),
(41719, 255079),
(41739, 255080),
(741722, 255081),
(753524, 255082),
(753524, 255083);

DELETE FROM `creature_questender` WHERE `quest` IN (255078,255079,255080,255081,255082,255083);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES
(41719, 255078),
(41739, 255079),
(41719, 255080),
(741722, 255081),
(753524, 255082),
(753524, 255083);

DELETE FROM `creature` WHERE `guid` BETWEEN 9010700 AND 9010704;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`)
VALUES
(9010700, 41719, 1, 0, 0, 1, 1, 0, -393.124, -2607.53, 96.351, 2.32863, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Crossroads: Raj''iri at SuperTrack 21366, turn-in of 255078 and 255080'),
(9010701, 753513, 1, 0, 0, 1, 1, 0, -546.686, -2705.27, 96.037, 1.57543, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Crossroads: Brumbof Bramstum by the lodge drums near SuperTrack 21367, objective of 255080 in the tauren lodge'),
(9010702, 41739, 1, 0, 0, 1, 1, 0, -531.499, -2639.09, 96.066, 4.26463, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Crossroads: Rhuna at SuperTrack 21372, turn-in of 255079'),
(9010703, 741722, 1, 0, 0, 1, 1, 0, -464.983, -2536.49, 115.152, 4.766, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Crossroads: Martin Lesterfield at SuperTrack 21374, turn-in of 255081'),
(9010704, 753524, 1, 0, 0, 1, 1, 0, -354.925, -2657.8, 96.201, 2.883, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Crossroads: Voltzix Sprocketpop at SuperTrack 21379, turn-in of 255083');

DELETE FROM `creature_text` WHERE `CreatureID` IN (41719,741719);
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Probability`, `comment`) VALUES
(41719, 0, 0, 'Feel like dancin'' now?', 12, 100, 'Raj''iri - ask Naj''iri to dance'),
(41719, 1, 0, 'How about now mon?', 12, 100, 'Raj''iri - ask Naj''iri again'),
(741719, 0, 0, 'Not really mon...', 12, 100, 'Naj''iri - decline'),
(741719, 1, 0, 'Alright, just for a bit...', 12, 100, 'Naj''iri - agree');

DELETE FROM `creature_loot_template` WHERE `Item` IN (355118,355119,355120,355123);
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(3272, 355118, 0, 80, 1, 1, 0, 1, 1, 'Kolkar Wrangler - Centaur Windflute (255078)'),
(3273, 355118, 0, 80, 1, 1, 0, 1, 1, 'Kolkar Stormer - Centaur Windflute (255078)'),
(4127, 355119, 0, 80, 1, 1, 0, 1, 1, 'Hecklefang Hyena - Hyena Skin (255079)'),
(3248, 355120, 0, 80, 1, 1, 0, 1, 1, 'Barrens Giraffe - Giraffe Leather (255079)'),
(3379, 355123, 0, 80, 1, 1, 0, 1, 1, 'Burning Blade Bruiser - Demonic Scripture (255081)'),
(3380, 355123, 0, 80, 1, 1, 0, 1, 1, 'Burning Blade Acolyte - Demonic Scripture (255081)');

DELETE FROM `npc_text` WHERE `ID` = 9010700;
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `lang0`, `Probability0`) VALUES
(9010700, 'The beat never stops in this lodge, $c.', 'The beat never stops in this lodge, $c.', 0, 1);

DELETE FROM `gossip_menu` WHERE `MenuID` = 9010700;
INSERT INTO `gossip_menu` (`MenuID`, `TextID`) VALUES
(9010700, 9010700);

DELETE FROM `gossip_menu_option` WHERE `MenuID` = 9010700;
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`) VALUES
(9010700, 0, 0, 'Do you have an extra drumstick you can spare?', 0, 1, 1, 0, 0, 0, 0, '', 0);

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 15 AND `SourceGroup` = 9010700;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(15, 9010700, 0, 0, 0, 9, 0, 255080, 0, 0, 0, 0, 0, '', 'Brumbof Bramstum - drumstick option only while Dancing to the Beat is taken'),
(15, 9010700, 0, 0, 0, 2, 0, 355122, 1, 0, 1, 0, 0, '', 'Brumbof Bramstum - drumstick option only without a Drumstick');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 753513 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(753513, 0, 0, 1, 62, 0, 100, 0, 9010700, 0, 0, 0, 0, 0, 56, 355122, 1, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Brumbof Bramstum - On Gossip Option 0 Selected - Add Drumstick'),
(753513, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Brumbof Bramstum - Linked - Close Gossip');
