-- #10089: "A Friend in Hell" (175186) sends the player to speak with Engrym (creature 164472), whose only
-- spawn still carried the reconstruction's guess: the row comment says "best guess, near Ada-Gumbad, toward
-- Flamehowl Cave (position unknown)" at (-6120 -790 426.03), 400 yards away from the quest marker. The
-- quest_poi points for 175186 cover (-6515..-6495, -690..-670), and the report was filed from
-- (-6512.05 -682.46 378.73), inside that polygon, so Engrym belongs there instead.
UPDATE `creature`
SET `position_x` = -6512.05, `position_y` = -682.46, `position_z` = 378.73,
    `Comment` = 'Engrym, Tarnished Plateaus: quest 175186 marker area (-6512,-682), at the report position'
WHERE `guid` = 9962254;
