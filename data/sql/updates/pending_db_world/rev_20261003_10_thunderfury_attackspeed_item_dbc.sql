-- Thunderfury attack-speed variants (219001/219002/219003/219005/219006/219007/
-- 319024/319025/319026/1319020/1319021/1319022) are new custom item IDs, so the
-- client never had an Item.dbc row for them even though their display id (24114)
-- is the stock Thunderfury model the client already ships. Same fix as the
-- Heartwood Key item (#6211) and the Infernos axe pair above: insert the missing
-- rows into item_dbc so AscensionDisplayPatchService streams them to clients
-- that lack them. No raw .dbc file edits needed, and no itemdisplayinfo_dbc row
-- either, since display id 24114 is already present in the client's own
-- ItemDisplayInfo.dbc. Field values verified against the project's own archive
-- Item.dbc (AscensionServer/Build/install/dbc/Item.dbc), which already carries
-- identical rows for every one of these entries.

DELETE FROM `item_dbc` WHERE `ID` IN (219001, 219002, 219003, 219005, 219006, 219007, 319024, 319025, 319026, 1319020, 1319021, 1319022);
INSERT INTO `item_dbc` (`ID`, `ClassID`, `SubclassID`, `Sound_Override_Subclassid`, `Material`, `DisplayInfoID`, `InventoryType`, `SheatheType`)
VALUES
    (219001, 2, 7, -1, 1, 24114, 13, 1),
    (219002, 2, 7, -1, 1, 24114, 13, 1),
    (219003, 2, 7, -1, 1, 24114, 13, 1),
    (219005, 2, 7, -1, 1, 24114, 13, 1),
    (219006, 2, 7, -1, 1, 24114, 13, 1),
    (219007, 2, 7, -1, 1, 24114, 13, 1),
    (319024, 2, 7, -1, 1, 24114, 13, 1),
    (319025, 2, 7, -1, 1, 24114, 13, 1),
    (319026, 2, 7, -1, 1, 24114, 13, 1),
    (1319020, 2, 7, -1, 1, 24114, 13, 1),
    (1319021, 2, 7, -1, 1, 24114, 13, 1),
    (1319022, 2, 7, -1, 1, 24114, 13, 1);
