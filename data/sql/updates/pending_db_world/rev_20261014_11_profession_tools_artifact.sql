START TRANSACTION;

-- Mining Pick, Blacksmith Hammer and Skinning Knife reach the client as Artifact (6) on every CoA mode, like the Lumber Axe; the stock rows are white.
UPDATE `item_template` SET `Quality` = 6 WHERE `entry` IN (2901, 5956, 7005) AND `Quality` <> 6;

COMMIT;
