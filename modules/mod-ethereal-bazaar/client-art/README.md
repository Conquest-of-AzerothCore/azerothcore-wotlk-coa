# Groot Coin icon (Release B)

| File | Purpose |
| --- | --- |
| `groot_coin_rim_1024.png` | Source art chosen by John: the coin with the "GROOTLOOPS33" / "CONQUEST OF AZEROTHCORE" rim |
| `groot_coin_rim_256.png` | The same art at 256 x 256 |
| `groot_coin_source.png` | The originally supplied coin, kept for reference |
| `make_blp.py` | Deterministic converter (Python 3 + Pillow) |
| `INV_GrootCoin.blp` | 64 x 64 BLP2, 256-colour palette, opaque, full mip chain |
| `INV_GrootCoin.preview.png` | The BLP decoded again, for review |

Rebuild: `python3 make_blp.py` (writes `INV_GrootCoin.blp` and the preview next to it;
`sha256sum INV_GrootCoin.blp` is stable for a given Pillow version). The rim text is not legible at 64 px; the
tree face and bronze rim carry the icon at bag size.

The texture has **not** been rendered in the game client yet.

## Activation, in this order

1. Ship `Interface\Icons\INV_GrootCoin.blp` through the launcher's managed patch path. There is no verified
   launcher-safe MPQ slot in this repository: inspect the launcher manifest and its repair behaviour and add the
   file there. Do not replace whole client DBC archives and do not invent a new patch-N archive.
2. Check clean install, normal update, repair and reconnect keep the file.
3. Only then add a pending world migration that creates display 990001 and points the coin at it. 990001 was
   free in the dev overlay and the client's `ItemDisplayInfo.dbc` on 12 Oct 2026; recheck both first:

```sql
DELETE FROM `itemdisplayinfo_dbc` WHERE `ID` = 990001 AND `InventoryIcon_1` = 'INV_GrootCoin';
INSERT INTO `itemdisplayinfo_dbc` (`ID`, `ModelName_1`, `ModelName_2`, `ModelTexture_1`, `ModelTexture_2`,
    `InventoryIcon_1`, `InventoryIcon_2`, `GeosetGroup_1`, `GeosetGroup_2`, `GeosetGroup_3`, `Flags`,
    `SpellVisualID`, `GroupSoundIndex`, `HelmetGeosetVis_1`, `HelmetGeosetVis_2`, `Texture_1`, `Texture_2`,
    `Texture_3`, `Texture_4`, `Texture_5`, `Texture_6`, `Texture_7`, `Texture_8`, `ItemVisual`, `ParticleColorID`)
VALUES
(990001, '', '', '', '', 'INV_GrootCoin', '', 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', '', '', '', '', '', 0, 0);
UPDATE `item_template` SET `displayid` = 990001 WHERE `entry` = 910001 AND `displayid` = 30015;
UPDATE `item_dbc` SET `DisplayInfoID` = 990001 WHERE `ID` = 910001 AND `DisplayInfoID` = 30015;
```

Copy the column layout of an existing `itemdisplayinfo_dbc` row before using this; the server streams the row
through the existing AscensionCompat display patch route, which sends metadata only, never the texture. A client
without the texture shows a missing icon, so never activate step 3 before step 1 has reached players. Display
30015 itself must not be changed: other items use it.
