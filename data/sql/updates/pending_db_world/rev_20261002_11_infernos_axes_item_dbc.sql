-- Infernos, the Ignited (18129/218129/318129/1318129) and Infused, Infernos of
-- Elemental Fury (998102-998105) are new custom item IDs, so the client never
-- had an Item.dbc row for them even though both display ids (141303, 170282)
-- are display models the Ascension client already ships. Following the same
-- fix as the Heartwood Key item (#6211): insert the missing rows into
-- `item_dbc` so AscensionDisplayPatchService streams them to clients that
-- lack them, via the existing SMSG_PATCH_ITEM opcode. No raw .dbc file edits
-- needed, and no itemdisplayinfo_dbc row either, since both display ids are
-- already present in the client's own ItemDisplayInfo.dbc.

DELETE FROM `item_dbc` WHERE `ID` IN (18129, 218129, 318129, 1318129, 998102, 998103, 998104, 998105);
INSERT INTO `item_dbc` (`ID`, `ClassID`, `SubclassID`, `Sound_Override_Subclassid`, `Material`, `DisplayInfoID`, `InventoryType`, `SheatheType`)
VALUES
    (18129, 2, 1, -1, 1, 141303, 17, 1),
    (218129, 2, 1, -1, 1, 141303, 17, 1),
    (318129, 2, 1, -1, 1, 141303, 17, 1),
    (1318129, 2, 1, -1, 1, 141303, 17, 1),
    (998102, 2, 1, -1, 1, 170282, 17, 1),
    (998103, 2, 1, -1, 1, 170282, 17, 1),
    (998104, 2, 1, -1, 1, 170282, 17, 1),
    (998105, 2, 1, -1, 1, 170282, 17, 1);
