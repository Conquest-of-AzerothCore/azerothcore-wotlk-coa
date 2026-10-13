# Groot Coin icon (display 990001)

**The client patch must ship before, or together with, the server change that uses it.** The world migration
`rev_20261012_60_groot_coin_item.sql` puts item 910001 on display 990001 (`InventoryIcon_1 = INV_GrootCoin`).
The server streams that display row through the AscensionCompat display patch route, but it sends metadata
only, never the texture: a client without `Interface\Icons\INV_GrootCoin.blp` shows the coin as a red
question mark.

| File | Purpose |
| --- | --- |
| `groot_coin_rim_1024.png` | Source art chosen by John: the coin with the "CONQUEST OF AZEROTHCORE" rim (server name only) |
| `groot_coin_rim_256.png` | The same art at 256 x 256 |
| `groot_coin_source.png` | The originally supplied coin, kept for reference |
| `make_blp.py` | Deterministic converter (Python 3 + Pillow) |
| `INV_GrootCoin.blp` | 64 x 64 BLP2, DXT5 (alpha depth 8, alpha type 7), full mip chain, no palette |
| `INV_GrootCoin.preview.png` | The BLP decoded again, for review |
| `add_display_990001.py` | Appends display 990001 (a copy of 30015 with `InventoryIcon_1 = INV_GrootCoin`) to a client `ItemDisplayInfo.dbc` |
| `build_client_patch.sh` | Builds `patch-ZG.MPQ` (icon + `ItemDisplayInfo.dbc` with 990001) from a client's `Data` directory |

Rebuild the icon: `python3 make_blp.py` (writes `INV_GrootCoin.blp` and the preview; sha256 `3ca16759…35ca` with
Pillow 12.3). The layout matches the client's own icons (`Interface\icons\_KeyGoldBlood.blp` in `patch-I.MPQ`):
148-byte header, DXT5 mips 64 to 1. The first, 256-colour palettized BLP rendered as a red question mark in the
Ascension client; this DXT5 one was confirmed in game on 13 Oct 2026 in bags and in the mailbox.

## The client patch

It contains exactly two files:

- `Interface\Icons\INV_GrootCoin.blp`: this directory's BLP. Required.
- `DBFilesClient\ItemDisplayInfo.dbc`: the client's own table (from `patch-M.MPQ` on 13 Oct 2026, 129694 rows,
  25 fields, 100-byte records) with row 990001 appended. The streamed row already gives the client 990001,
  so this copy covers a client that has not received the stream yet. Rebuild it from the current client
  whenever the launcher changes `ItemDisplayInfo.dbc`, never from an old copy.

```bash
./build_client_patch.sh /mnt/c/ascension-live/Data ~/opt/mpqcli/mpqcli /tmp/zg   # mpqcli v0.12.0
```

The Ascension client loads every `Data\patch-*.MPQ`; `patch-ZG.MPQ` sorts after `patch-Z.MPQ`, so it wins.
For players, put the two files into the launcher's managed patch path (inspect the launcher manifest and its
repair behaviour; a standalone `patch-ZG.MPQ` is what was verified locally). Check clean install, normal
update, repair and reconnect keep the files. Existing clients need a full restart and `Cache\WDB` deleted (or
the item cache to expire) before the mailbox and bags show the new icon.

Local test client: copy `/tmp/zg/patch-ZG.MPQ` into `C:\ascension-live\Data\` with the client closed (a loose
`Interface\Icons\INV_GrootCoin.blp` also works), apply the world migration, restart the worldserver, fully
restart the client and delete `Cache\WDB`.

## Revert (client patch not shipped, or withdrawn)

Run this on the world database, restart the worldserver, and have clients clear `Cache\WDB`. The coin goes
back to display 30015, the Bazaar Token icon, which every client has. Display 30015 itself must never be
changed; other items use it.

```sql
UPDATE `item_template` SET `displayid` = 30015 WHERE `entry` = 910001 AND `displayid` = 990001;
UPDATE `item_dbc` SET `DisplayInfoID` = 30015 WHERE `ID` = 910001 AND `DisplayInfoID` = 990001;
DELETE FROM `itemdisplayinfo_dbc` WHERE `ID` = 990001 AND `InventoryIcon_1` = 'INV_GrootCoin';
```
