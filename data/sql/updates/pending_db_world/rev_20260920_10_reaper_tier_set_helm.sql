-- The Reaper tier helm goes back to the set's own art.
--
-- rev_20260916_68 pointed the four helms at display 990000, the Lich King's Crown of Domination,
-- which needed a display record of its own and the "Lich King Armor 3.X.X" art installed as
-- patch-Y.MPQ on every client that wanted to see it. The set reads better wearing the helmet it was
-- designed around, and it costs the realm nothing to draw: 76717 is the display the four helms were
-- created with, the Sanctified Ymirjar Lord's Helmet shape the rest of the set already matches.
UPDATE `item_template` SET `displayid` = 76717
WHERE `entry` IN (992001, 992011, 992021, 992031);

-- Nothing references 990000 any more. The row only ever existed for those four helms, so it goes
-- with them; the client-side ItemDisplayInfo row and patch-Y.MPQ are removed alongside it.
DELETE FROM `itemdisplayinfo_dbc` WHERE `ID` = 990000;
