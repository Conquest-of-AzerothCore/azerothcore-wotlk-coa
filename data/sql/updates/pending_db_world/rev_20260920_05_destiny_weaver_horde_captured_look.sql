-- Destiny Weaver: the Horde pair wears the captured Weaver's clothing, not a stand-in set.
--
-- The packet corpus holds exactly one Weaver: Galric Olim (449347, human male, template display
-- 449299).  It is answered three times across the captures - once in the short 14:06 capture and
-- twice in the 16:23 one - and all three replies are byte-identical.  They give, verbatim:
--
--   race 1, gender 0, class 1, skin 4, face 2, hair 6, haircolour 8, facial hair 4, guild 0
--   shirt 126792, chest 66195, legs 66200, feet 142624, wrists 142619, all other slots empty
--
-- Those five item displays are "Hallowed Undershirt of Lunar Communion", "Weary Worker's Tunic",
-- "Weary Worker's Pants", "Scribe's Opulent Waders" and "Scribe's Opulent Wristwraps" - a plain
-- civilian cloth outfit, and clearly the Weaver's working dress rather than armour.  Leather,
-- cloth and shirt displays are worn by several races in the same corpus (12955 is on a human and
-- a blood elf, 11183 on a human and a dwarf, 136769 on five races), so these ids are not
-- race-bound: the same ItemDisplayInfo row dresses any body.
--
-- The Horde pair was still wearing the stand-in copied out of a dressed troll NPC (extra 19788):
-- the Darkspear tabard, a full mail PvP set and a helm.  Nothing in the corpus, the client, the
-- world database, the datamine or the archive carries a Horde Weaver's own reply, so the captured
-- Weaver clothing is the only evidence-backed answer - the same clothes, on a troll.
--
-- Race, gender and the troll's own face and hair are left exactly as they are; only the gear moves.
-- TAV'VIN and TAV'RAL (449340 / 449350, both display 449292) are one look in the archive's own
-- creature cache, so they are corrected together.

UPDATE `creature_display_preset` SET `item_head` = 0, `item_shoulders` = 0, `item_body` = 126792, `item_chest` = 66195, `item_waist` = 0, `item_legs` = 66200, `item_feet` = 142624, `item_wrists` = 142619, `item_hands` = 0, `item_back` = 0, `item_tabard` = 0 WHERE `entry` = 449340;  -- Tav'vin
UPDATE `creature_display_preset` SET `item_head` = 0, `item_shoulders` = 0, `item_body` = 126792, `item_chest` = 66195, `item_waist` = 0, `item_legs` = 66200, `item_feet` = 142624, `item_wrists` = 142619, `item_hands` = 0, `item_back` = 0, `item_tabard` = 0 WHERE `entry` = 449350;  -- Tav'ral
