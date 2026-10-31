# Heirloom armor tooltip shows its real armor type

The 3.3.5 client draws heirloom armor as the best lower armor type the character knows, the old WotLK
mail-to-plate heirloom display. CoA classes keep one armor type, so a plate heirloom such as Strengthened
Stockade Pauldrons (1644099) reads "Leather" in white on a leather class even though the server correctly
refuses to equip it ("You do not have the required proficiency"). The item is plate in `item_template`, the
server `Item.dbc` and the client `Item.dbc`.

`client/Interface/FrameXML/CoAHeirloomArmorTooltip.lua` hooks `OnTooltipSetItem` on `GameTooltip`,
`ItemRefTooltip` and the comparison tooltips. For heirloom-quality armor whose type is cloth, leather, mail or
plate it replaces the armor-type text with the item's real type, white when the character knows that armor
proficiency (spells 9078, 9077, 8737, 750, or the matching skill line) and red when not. Every other tooltip,
including ordinary armor and heirloom weapons, is unchanged. It changes no server behavior.

Tested in game on a leather class (red Plate), a plate-wearing Guardian (white Plate, item equips), a cloth
heirloom and an ordinary leather item, plus comparison and chat-link tooltips.

## Package

```powershell
python tools/package_hotspot_client.py `
  --baseline "C:/Client/Data/patch-B.MPQ" `
  --output "C:/Staging/patch-B.MPQ" `
  --mpqcli "C:/Tools/mpqcli.exe" `
  --lua CoAHeirloomArmorTooltip.lua
```

The tool copies the release's effective `patch-B.MPQ`, adds the Lua file, appends one loader entry to
`FrameXML.toc` and verifies every member. Repeat `--lua` to ship it with the other FrameXML overlays. A source
merge does not distribute the archive.
