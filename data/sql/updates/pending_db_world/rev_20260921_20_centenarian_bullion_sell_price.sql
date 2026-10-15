-- Centenarian Bullion (413799) is the trial currency item, and its vendor sell price was a tenth of
-- the value its own denomination implies: Centenarian Coin (413800), the smaller unit, sells for
-- 250000 copper against a 500000 buy price, while the Bullion sold for 50000 against a 1000000 buy
-- price. The ticket reports 500000 as the intended sell price, which is that same 2:1 relation.
UPDATE `item_template` SET `SellPrice` = 500000 WHERE `entry` = 413799 AND `SellPrice` = 50000;
