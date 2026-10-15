-- Destiny Weaver: the human pair shares one appearance, so both rows carry it.
--
-- The Weavers come in pairs: one per race stands in the racial starting area, the other in the
-- racial capital, and the two share a single custom display id - the human pair, entries 449347
-- (Galric Olim) and 449357 (Galrin Olemar), both use 449299. The live service defined the look
-- once per display, which is why `creature_display_preset` answers for a display id and not for
-- an individual NPC, and why the pair renders identically.
--
-- rev_20260920_00 wrote the captured body of 449347 into its row and left 449357 on the stand-in
-- look rev_20260919_04 had authored for it, so the two halves of the pair disagreed: the
-- Stormwind weaver, the one players actually walk past, did not wear the recovered appearance.
--
-- The values below are the captured ones (2026-09-01, SMSG_MIRRORIMAGE_DATA for 449347): race 1,
-- gender 0, class 1, skin 4, face 2, hair 6, haircolour 8, facial hair 4, body/chest/legs/feet/
-- wrists 126792/66195/66200/142624/142619, head/shoulders/waist/hands/back/tabard empty.

UPDATE `creature_display_preset`
SET `class` = 1, `skin` = 4, `face` = 2, `hair` = 6, `haircolor` = 8, `facialhair` = 4,
    `item_head` = 0, `item_shoulders` = 0, `item_body` = 126792, `item_chest` = 66195,
    `item_waist` = 0, `item_legs` = 66200, `item_feet` = 142624, `item_wrists` = 142619,
    `item_hands` = 0, `item_back` = 0, `item_tabard` = 0
WHERE `entry` = 449357;
