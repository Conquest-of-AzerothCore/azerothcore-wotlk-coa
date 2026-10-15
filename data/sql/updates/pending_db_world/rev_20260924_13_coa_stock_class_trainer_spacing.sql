-- Stock class trainers keep their spawns and their trainer role: a realm may still offer the stock
-- classes, and a CoA class cannot train with them (Trainer.cpp checks the exact class). The one exception is
-- Mathrengyl Bearwalker 4217, CoA's Darnassus Primalist (rev_20260923_05): a creature has one trainer, and
-- Denatharion 4218 and Fylerian Nightwing 4219 still train Druids beside him in the Cenarion Enclave. The CoA
-- class trainers and chain NPCs of migrations 05-17 took some of their posts, so the ones that would now
-- stand on or inside another NPC step aside.
--
-- WHERE EACH VALUE COMES FROM
--   Thotar  moved to the turn-in point of his CoA quests (section 1).
--   spacing  a stock class trainer spawn (Type 0 trainer for classes 1-11, not event-only) within 1.5 yd of
--     another NPC on the same floor (2.5 yd of height) moves to the nearest standable floor (slope up to 20)
--     2.5 yd clear of every NPC and 1.0 yd of every object, keeping its facing. Pairs that both stand where
--     the stock world has them are left alone. Checked against the world after every other migration.
--   kill copies  the Cultist quests "Going MAD!" send the player to kill a copy of a stock trainer (entries
--     299235-299240). The copy shows only while the quest is taken and the stock trainer is hidden from that
--     player over the same span, so the two never stand together (section 3; the Northshire copy has its
--     own condition in rev_20260923_06).
--
-- No creature, template, quest or gossip id is created. Every statement is keyed exactly and re-runs to the
-- same state.

-- ---------------------------------------------------------------------------
-- 1. Thotar stands at his CoA turn-in point
-- ---------------------------------------------------------------------------
-- Thotar 3171: CoA stands him 6.5 yd deeper in the Razor Hill burrow, at the turn-in point of his quests 6062,
-- 6068-6070, 6082 and 6083 (SuperTrack 566, SOURCED-CLIENT). surface.check: Trollburrow.wmo floor 11.628,
-- headroom 3.8, slope 0.1, no problems; 4.1 yd from Harruk 3620 on the same floor; Gar'Thok is 3.0 yd away in
-- plan but 5.9 yd higher, on the upper floor. Faces the burrow entrance like Harruk.
UPDATE `creature` SET `position_x` = 272.0, `position_y` = -4709.57, `position_z` = 11.627, `orientation` = 1.27
    WHERE `guid` = 7293 AND `id` = 3171;

-- ---------------------------------------------------------------------------
-- 2. Stock trainers that would stand on another NPC
-- ---------------------------------------------------------------------------
-- Granis Swiftaxe 1229 (Kharanos): the stock spot is within Eyma Thunderbrew 9008483 at 1.15 yd; moved 2.5 yd to
-- the nearest standable floor 2.5 yd clear of every NPC (surface.standable: headroom 7.253, slope 0.1)
UPDATE `creature` SET `position_x` = -5603.43, `position_y` = -529.4, `position_z` = 399.656, `orientation` = 0.174533
    WHERE `guid` = 196 AND `id` = 1229;
-- Solm Hargrin 916 (Coldridge Valley): the stock spot is within Groldha 9008000 at 0.5 yd; moved 2.5 yd to the
-- nearest standable floor 2.5 yd clear of every NPC (surface.standable: headroom 12.952, slope 0.1)
UPDATE `creature` SET `position_x` = -6091.25, `position_y` = 404.92, `position_z` = 395.541, `orientation` = 4.5204
    WHERE `guid` = 421 AND `id` = 916;
-- Marryk Nurribit 944 (Coldridge Valley): the stock spot is within Grelin Ironbeard 9003311 at 0.15 yd; moved
-- 2.5 yd to the nearest standable floor 2.5 yd clear of every NPC (surface.standable: headroom 12.466, slope
-- 0.0)
UPDATE `creature` SET `position_x` = -6057.62, `position_y` = 390.15, `position_z` = 392.761, `orientation` = 3.33358
    WHERE `guid` = 1025 AND `id` = 944;
-- Gart Mistrunner 3060 (Camp Narache): the stock spot is within Sunwalker Thunderhorn 9003908 at 0.1 yd; moved
-- 2.5 yd to the nearest standable floor 2.5 yd clear of every NPC (surface.standable: headroom 11.627, slope
-- 0.0)
UPDATE `creature` SET `position_x` = -2871.07, `position_y` = -268.59, `position_z` = 53.917, `orientation` = 2.68781
    WHERE `guid` = 26898 AND `id` = 3060;
-- Frahun Shadewhisper 3594 (Shadowglen): the stock spot is within Saelina Shedana 9004111 at 1.05 yd; moved 2.5
-- yd to the nearest standable floor 2.5 yd clear of every NPC (surface.standable: headroom 14.536, slope 0.0)
UPDATE `creature` SET `position_x` = 10521.6, `position_y` = 778.01, `position_z` = 1329.599, `orientation` = 1.53589
    WHERE `guid` = 46179 AND `id` = 3594;
-- Priestess Anetta 375 (Northshire Abbey): the stock spot is within Chaplain Nysoni 9003112 at 1.13 yd; moved
-- 2.5 yd to the nearest standable floor 2.5 yd clear of every NPC (surface.standable: headroom 6.877, slope
-- 10.0)
UPDATE `creature` SET `position_x` = -8851.09, `position_y` = -193.34, `position_z` = 81.933, `orientation` = 2.54818
    WHERE `guid` = 79963 AND `id` = 375;

-- ---------------------------------------------------------------------------
-- 3. Stock trainers hidden while their kill copy stands at their post
-- ---------------------------------------------------------------------------
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 30 AND `SourceGroup` = 0 AND `SourceEntry` IN (925, 926, 3593, 3707, 2119, 299236, 299237, 299239, 299240) AND `ConditionTypeOrReference` = 9;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(30, 0, 925, 0, 0, 9, 0, 200071, 0, 0, 1, 0, 0, '', 'Brother Sammuel - hidden while Going MAD! (200071) is taken; copy 299235 stands in'),
(30, 0, 926, 0, 0, 9, 0, 200072, 0, 0, 1, 0, 0, '', 'Bromos Grummner - hidden while Going MAD! (200072) is taken; copy 299236 stands in'),
(30, 0, 3593, 0, 0, 9, 0, 200073, 0, 0, 1, 0, 0, '', 'Alyissia - hidden while Going MAD! (200073) is taken; copy 299237 stands in'),
(30, 0, 3707, 0, 0, 9, 0, 200074, 0, 0, 1, 0, 0, '', 'Ken''jai - hidden while Going MAD! (200074) is taken; copy 299239 stands in'),
(30, 0, 2119, 0, 0, 9, 0, 200075, 0, 0, 1, 0, 0, '', 'Dannal Stern - hidden while Going MAD! (200075) is taken; copy 299240 stands in'),
(30, 0, 299236, 0, 0, 9, 0, 200072, 0, 0, 0, 0, 0, '', 'Bromos Grummner (Going MAD! target) - visible only while Going MAD! (200072) is taken'),
(30, 0, 299237, 0, 0, 9, 0, 200073, 0, 0, 0, 0, 0, '', 'Alyissia (Going MAD! target) - visible only while Going MAD! (200073) is taken'),
(30, 0, 299239, 0, 0, 9, 0, 200074, 0, 0, 0, 0, 0, '', 'Ken''jai (Going MAD! target) - visible only while Going MAD! (200074) is taken'),
(30, 0, 299240, 0, 0, 9, 0, 200075, 0, 0, 0, 0, 0, '', 'Dannal Stern (Going MAD! target) - visible only while Going MAD! (200075) is taken');
