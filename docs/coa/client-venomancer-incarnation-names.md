# Wardrobe: Venomancer sees its own form names on the Druid Incarnation tabs

Venomancer shares the Druid Incarnation categories 17-23 of `AppearanceCategories.dbc` (class bit 29 and the
Venomancer form in field 21). A category row has one name and one icon, so a Venomancer saw "Cat Form" and the Druid
icon on tabs that apply to Spider Form.

`client/Interface/FrameXML/CoAVenomancerIncarnationNames.lua` wraps `C_AppearanceCollection.GetCategoryInfo`. For a
player whose class token is `PROPHET` it returns the name and icon of the matching Venomancer form spell for those
seven categories and keeps every other return value. Every other class and category gets the client's own answer, so
Druids see exactly what they saw before.

| Category | Druid form | Venomancer form |
|---|---|---|
| 17 | Bear Form | Beetle Form 803183 |
| 18 | Cat Form | Spider Form 800841 |
| 19 | Travel Form | Venomwing Form 520307 |
| 20 | Aquatic Form | Sea Serpent Form 803212 |
| 21 | Flight Form | Wasp Form 805141 |
| 22 | Moonkin Form | Weaver Form 804980 |
| 23 | Tree of Life | Vizier Form 800912 |

## Package

```powershell
python tools/package_hotspot_client.py `
  --baseline "C:/Client/Data/patch-B.MPQ" `
  --output "C:/Staging/patch-B.MPQ" `
  --mpqcli "C:/Tools/mpqcli.exe" `
  --lua CoAVenomancerIncarnationNames.lua
```

The tool copies the effective `patch-B.MPQ`, adds the Lua file and appends one loader entry to `FrameXML.toc`. It ships
together with the edited `DBFilesClient\AppearanceCategories.dbc` in `patch-M.MPQ`; without that DBC a Venomancer has
no Incarnation tabs and the overlay changes nothing. A source merge does not distribute either archive.
