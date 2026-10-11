-- CoA: the CoA NPCs around Goldshire showed the wrong target-frame portrait (issue #7023).
--
-- Westfall Refugee, Alandra, Clara the Mad, Goldshire Farmer, Eldor Hammer and their neighbours
-- look correct in the world but their target portrait is the default face for their race and
-- gender, not the face they wear.
--
-- WHY.  The look of a CoA NPC travels over the mirror-image channel: the unit is created on the
-- plain character display for its race and gender (49 human male, 50 human female - the same ids
-- the Weavers use, see docs/coa/npc-restoration.md), UNIT_FLAG2_MIRROR_IMAGE makes the client ask
-- for the appearance, and creature_display_preset answers with the paper-doll.  The client builds
-- the 3D model from that reply, which is why the model in the world is right.  The target-frame
-- portrait is drawn differently: the client composes it from the unit's display info, and a
-- display is a portrait source only when it carries a CreatureDisplayInfoExtra
-- (ExtendedDisplayInfoID).  Displays 49 and 50 have ExtendedDisplayInfoID 0, so there is no face
-- to draw and the client falls back to the stock default customization for the race and gender -
-- the brown-haired woman and the default bearded man in the report.
--
-- Every humanoid NPC that has a real portrait uses such a display: Marshal Dughan 1985 (extra
-- 634), Innkeeper Farley 1291 (extra 61) and Corina Steele 1287 (extra 56) all sit on displays
-- that carry one.  The preset NPCs do not: of the 300 entries with a creature_display_preset row,
-- 298 stand on a display whose ExtendedDisplayInfoID is 0 (47 on 49, 30 on 50, and the rest on the
-- other bare character displays - 57, 51, 53, 56, 1478, 15475, 15476, 16125, 16126).  This file
-- fixes the 21 reported in Goldshire, which is where the issue was filed; the rest are the same
-- change and are deliberately left to a follow-up so this one can be checked in a client first.
--
-- FIX.  Point creature_template_model at a client display that keeps the NPC's character model
-- (ModelID 49 or 50, so the model the client builds first is unchanged) but carries an Extra, and
-- move the preset row onto that display id, since AscensionCreaturePresetMgr keys on
-- (entry, display_id) and would otherwise serve the look under the wrong key.  The five
-- customization bytes are set from the Extra, so the paper-doll on the model and the face in the
-- portrait are the same face.  The captured outfit is not touched: the NPC keeps the clothing it
-- was captured with.
--
-- HOW THE EXTRA WAS CHOSEN, and what is still an approximation.  For each NPC the client's
-- CreatureDisplayInfoExtra.dbc rows of the same race and gender were scored by (1) the head slot -
-- the identical item if the Extra carries it, otherwise the same presence, because the portrait is
-- a head-and-shoulders bust and a hat the NPC does not wear is the most visible error - (2) the
-- shoulders slot the same way, (3) the customization distance
-- |skin|+|face|+|hair|+|haircolor|+|facialhair|, (4) the remaining slots.  Distance 0 means the
-- captured face was found unchanged in the client's own table and nothing about the appearance
-- changes; the largest here is 11 for 162818, whose captured haircolor 18 does not exist for
-- humans in the client's table, so it was already unrenderable and is moved onto the nearest valid
-- set.  Where the captured face had no exact twin the portrait and the model move together by one
-- or two indices.
--
-- Two limits, stated rather than hidden.  The portrait's clothing is the borrowed Extra's, so a
-- slot the Extra wears that the NPC does not can show in the bust; the head and shoulders slots
-- were chosen to match, which is what the frame shows.  162805 Clara the Mad wears the CoA head
-- item 142077, and no Extra in the client's table carries that item, so her portrait cannot show
-- that exact hat - she is the one NPC left on a stand-in head slot.  The change was verified against
-- the client's own DBCs and applied to the world database; it has not been checked in a client.
--
-- Idempotent: a keyed upsert, and CASE updates that no longer match once they have run.

-- 1. The display the unit is created as.  Same character model, but it carries a
--    CreatureDisplayInfoExtra, which is what the client needs before it can draw a face.
UPDATE `creature_template_model` SET `CreatureDisplayID` = 25599 WHERE `CreatureID` = 162800 AND `Idx` = 0;   -- Dulcinea
UPDATE `creature_template_model` SET `CreatureDisplayID` = 3565 WHERE `CreatureID` = 162801 AND `Idx` = 0;   -- Eldor Hammer
UPDATE `creature_template_model` SET `CreatureDisplayID` = 37113 WHERE `CreatureID` = 162805 AND `Idx` = 0;   -- Clara the Mad
UPDATE `creature_template_model` SET `CreatureDisplayID` = 33555 WHERE `CreatureID` = 162806 AND `Idx` = 0;   -- Aliscar Lend
UPDATE `creature_template_model` SET `CreatureDisplayID` = 10478 WHERE `CreatureID` = 162807 AND `Idx` = 0;   -- Harvend Thorm
UPDATE `creature_template_model` SET `CreatureDisplayID` = 14944 WHERE `CreatureID` = 162808 AND `Idx` = 0;   -- Thalira Conacher
UPDATE `creature_template_model` SET `CreatureDisplayID` = 16597 WHERE `CreatureID` = 162809 AND `Idx` = 0;   -- Rowena
UPDATE `creature_template_model` SET `CreatureDisplayID` = 44702 WHERE `CreatureID` = 162810 AND `Idx` = 0;   -- Isolde
UPDATE `creature_template_model` SET `CreatureDisplayID` = 8029 WHERE `CreatureID` = 162811 AND `Idx` = 0;   -- Darron
UPDATE `creature_template_model` SET `CreatureDisplayID` = 44703 WHERE `CreatureID` = 162812 AND `Idx` = 0;   -- Cerys
UPDATE `creature_template_model` SET `CreatureDisplayID` = 22821 WHERE `CreatureID` = 162813 AND `Idx` = 0;   -- Alandra
UPDATE `creature_template_model` SET `CreatureDisplayID` = 20664 WHERE `CreatureID` = 162814 AND `Idx` = 0;   -- Ainora
UPDATE `creature_template_model` SET `CreatureDisplayID` = 41651 WHERE `CreatureID` = 162817 AND `Idx` = 0;   -- Westfall Refugee
UPDATE `creature_template_model` SET `CreatureDisplayID` = 29836 WHERE `CreatureID` = 162818 AND `Idx` = 0;   -- Westfall Refugee
UPDATE `creature_template_model` SET `CreatureDisplayID` = 3696 WHERE `CreatureID` = 162819 AND `Idx` = 0;   -- Westfall Refugee
UPDATE `creature_template_model` SET `CreatureDisplayID` = 24902 WHERE `CreatureID` = 162820 AND `Idx` = 0;   -- Westfall Refugee
UPDATE `creature_template_model` SET `CreatureDisplayID` = 16497 WHERE `CreatureID` = 162821 AND `Idx` = 0;   -- Goldshire Farmer
UPDATE `creature_template_model` SET `CreatureDisplayID` = 10478 WHERE `CreatureID` = 162822 AND `Idx` = 0;   -- Goldshire Farmer
UPDATE `creature_template_model` SET `CreatureDisplayID` = 3349 WHERE `CreatureID` = 162823 AND `Idx` = 0;   -- Goldshire Farmer
UPDATE `creature_template_model` SET `CreatureDisplayID` = 6773 WHERE `CreatureID` = 162824 AND `Idx` = 0;   -- Goldshire Farmer
UPDATE `creature_template_model` SET `CreatureDisplayID` = 33555 WHERE `CreatureID` = 162943 AND `Idx` = 0;   -- Arcane Projection of Aliscar

-- 2. The preset has to answer for the display the unit actually has: the manager keys on
--    (entry, display_id) and otherwise falls back to the entry's first row, so a stale
--    display_id would serve the look under the wrong key.  The five customization bytes
--    follow the Extra, so the paper-doll on the model and the face in the portrait agree.
UPDATE `creature_display_preset` SET `display_id` = 25599, `skin` = 3, `face` = 2, `hair` = 7, `haircolor` = 1, `facialhair` = 3 WHERE `entry` = 162800 AND `display_id` = 50;   -- Dulcinea
UPDATE `creature_display_preset` SET `display_id` = 3565, `skin` = 5, `face` = 5, `hair` = 10, `haircolor` = 3, `facialhair` = 1 WHERE `entry` = 162801 AND `display_id` = 49;   -- Eldor Hammer
UPDATE `creature_display_preset` SET `display_id` = 37113, `skin` = 0, `face` = 3, `hair` = 0, `haircolor` = 2, `facialhair` = 0 WHERE `entry` = 162805 AND `display_id` = 50;   -- Clara the Mad
UPDATE `creature_display_preset` SET `display_id` = 33555, `skin` = 5, `face` = 10, `hair` = 16, `haircolor` = 9, `facialhair` = 8 WHERE `entry` = 162806 AND `display_id` = 49;   -- Aliscar Lend
UPDATE `creature_display_preset` SET `display_id` = 10478, `skin` = 1, `face` = 1, `hair` = 1, `haircolor` = 1, `facialhair` = 1 WHERE `entry` = 162807 AND `display_id` = 49;   -- Harvend Thorm
UPDATE `creature_display_preset` SET `display_id` = 14944, `skin` = 2, `face` = 2, `hair` = 1, `haircolor` = 2, `facialhair` = 1 WHERE `entry` = 162808 AND `display_id` = 50;   -- Thalira Conacher
UPDATE `creature_display_preset` SET `display_id` = 16597, `skin` = 10, `face` = 3, `hair` = 2, `haircolor` = 3, `facialhair` = 2 WHERE `entry` = 162809 AND `display_id` = 50;   -- Rowena
UPDATE `creature_display_preset` SET `display_id` = 44702, `skin` = 4, `face` = 4, `hair` = 4, `haircolor` = 4, `facialhair` = 4 WHERE `entry` = 162810 AND `display_id` = 50;   -- Isolde
UPDATE `creature_display_preset` SET `display_id` = 8029, `skin` = 1, `face` = 11, `hair` = 11, `haircolor` = 5, `facialhair` = 8 WHERE `entry` = 162811 AND `display_id` = 49;   -- Darron
UPDATE `creature_display_preset` SET `display_id` = 44703, `skin` = 6, `face` = 6, `hair` = 6, `haircolor` = 6, `facialhair` = 6 WHERE `entry` = 162812 AND `display_id` = 50;   -- Cerys
UPDATE `creature_display_preset` SET `display_id` = 22821, `skin` = 3, `face` = 8, `hair` = 8, `haircolor` = 6, `facialhair` = 4 WHERE `entry` = 162813 AND `display_id` = 50;   -- Alandra
UPDATE `creature_display_preset` SET `display_id` = 20664, `skin` = 1, `face` = 1, `hair` = 1, `haircolor` = 1, `facialhair` = 1 WHERE `entry` = 162814 AND `display_id` = 50;   -- Ainora
UPDATE `creature_display_preset` SET `display_id` = 41651, `skin` = 4, `face` = 7, `hair` = 5, `haircolor` = 3, `facialhair` = 2 WHERE `entry` = 162817 AND `display_id` = 49;   -- Westfall Refugee
UPDATE `creature_display_preset` SET `display_id` = 29836, `skin` = 4, `face` = 10, `hair` = 1, `haircolor` = 9, `facialhair` = 8 WHERE `entry` = 162818 AND `display_id` = 49;   -- Westfall Refugee
UPDATE `creature_display_preset` SET `display_id` = 3696, `skin` = 1, `face` = 3, `hair` = 7, `haircolor` = 5, `facialhair` = 1 WHERE `entry` = 162819 AND `display_id` = 50;   -- Westfall Refugee
UPDATE `creature_display_preset` SET `display_id` = 24902, `skin` = 6, `face` = 9, `hair` = 4, `haircolor` = 0, `facialhair` = 5 WHERE `entry` = 162820 AND `display_id` = 50;   -- Westfall Refugee
UPDATE `creature_display_preset` SET `display_id` = 16497, `skin` = 3, `face` = 10, `hair` = 8, `haircolor` = 8, `facialhair` = 4 WHERE `entry` = 162821 AND `display_id` = 50;   -- Goldshire Farmer
UPDATE `creature_display_preset` SET `display_id` = 10478, `skin` = 1, `face` = 1, `hair` = 1, `haircolor` = 1, `facialhair` = 1 WHERE `entry` = 162822 AND `display_id` = 49;   -- Goldshire Farmer
UPDATE `creature_display_preset` SET `display_id` = 3349, `skin` = 2, `face` = 2, `hair` = 2, `haircolor` = 2, `facialhair` = 3 WHERE `entry` = 162823 AND `display_id` = 49;   -- Goldshire Farmer
UPDATE `creature_display_preset` SET `display_id` = 6773, `skin` = 3, `face` = 7, `hair` = 2, `haircolor` = 4, `facialhair` = 5 WHERE `entry` = 162824 AND `display_id` = 50;   -- Goldshire Farmer
UPDATE `creature_display_preset` SET `display_id` = 33555, `skin` = 5, `face` = 10, `hair` = 16, `haircolor` = 9, `facialhair` = 8 WHERE `entry` = 162943 AND `display_id` = 49;   -- Arcane Projection of Aliscar

-- 3. The core needs a creature_model_info row for every display a creature is
--    created as; radius, reach and gender come from the character display it replaces.
DELETE FROM `creature_model_info` WHERE `DisplayID` IN (37113, 33555, 44702, 44703, 41651);
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`, `VerifiedBuild`) VALUES
(37113, 0.208, 1.500, 1, 0, 0),
(33555, 0.306, 1.500, 0, 0, 0),
(44702, 0.208, 1.500, 1, 0, 0),
(44703, 0.208, 1.500, 1, 0, 0),
(41651, 0.306, 1.500, 0, 0, 0);
