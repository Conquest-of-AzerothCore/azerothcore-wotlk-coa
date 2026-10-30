-- The Reaper tier had no PvE Power and no source line, and its helms wore the wrong shape.
--
-- Both missing pieces turned out to live in item_template, not in a client table. Comparing
-- 51227 (Sanctified Ymirjar Lord's Helmet) with ours shows exactly what the tier carries and
-- we did not:
--
--   description  '@Ascended Raid@'   the green line the client draws under the item name
--   spellid_4    101638              "PvE Power (+38)", spelltrigger_4 = 1, on equip
--
-- PvE Power goes by slot rather than by item level: across the 251, 264 and 277 Ymirjar pieces
-- head, chest and legs all carry 101638 (+38) and shoulders and hands carry 101625 (+25). The
-- same two spells therefore cover all four of our tiers, which is what the cap means in practice.
UPDATE `item_template` SET `spellid_4` = 101638, `spelltrigger_4` = 1
WHERE `entry` IN (992001, 992003, 992004,   -- 251: head, chest, legs
                  992011, 992013, 992014,   -- 264
                  992021, 992023, 992024,   -- 277
                  992031, 992033, 992034);  -- 284

UPDATE `item_template` SET `spellid_4` = 101625, `spelltrigger_4` = 1
WHERE `entry` IN (992002, 992005,   -- 251: shoulders, hands
                  992012, 992015,   -- 264
                  992022, 992025,   -- 277
                  992032, 992035);  -- 284

-- The source line names where the piece comes from, so it follows what each tier is called.
UPDATE `item_template` SET `description` = '@Heroic Raid@'   WHERE `entry` BETWEEN 992001 AND 992015;
UPDATE `item_template` SET `description` = '@Mythic@'        WHERE `entry` BETWEEN 992021 AND 992025;
UPDATE `item_template` SET `description` = '@Ascended Raid@' WHERE `entry` BETWEEN 992031 AND 992035;

-- 136808 is the Frostbitten Gaze of the Risen Nightmare, the head of the cosmetic set the other
-- four slots already use: 136807 shoulders, 136811 chest, 136814 legs, 136815 hands. 76717 was a
-- raid plate helm that matched none of them.
UPDATE `item_template` SET `displayid` = 136808
WHERE `entry` IN (992001, 992011, 992021, 992031);

-- The green line only draws for an item that carries flag 8. Every one of the 174,055 items with
-- an '@...@' description has it, and ours had Flags 0, so the text was there and never shown.
UPDATE `item_template` SET `Flags` = `Flags` | 8 WHERE `entry` BETWEEN 992001 AND 992099;
