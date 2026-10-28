-- The Forgotten Heirloom (64): after one player looted Furlbrow's Pocket Watch from Furlbrow's Wardrobe (290), the
-- wardrobe kept its quest sparkle for the next player but opened empty for 30 s, its restock time, with no sign of
-- when it would be ready again. The same holds for every non-consumable chest that holds only quest items and
-- restocks after 5 s or more. They now restock after 1 s, as most such chests already do, so each player on the
-- quest finds their own item.
UPDATE `gameobject_template` SET `Data2` = 1 WHERE `type` = 3 AND `Data2` >= 5 AND `entry` IN (119, 263, 264, 290, 321, 1594, 1736, 1760, 2084, 2689, 2690, 2691, 28024, 50982, 58369, 85563, 92420, 174728, 176785, 178553, 181671, 182122, 184310, 185220, 186885, 186886, 188461, 190208, 192187, 192188, 192189, 192190, 192191, 192192, 480101, 480102, 480103, 480104);
