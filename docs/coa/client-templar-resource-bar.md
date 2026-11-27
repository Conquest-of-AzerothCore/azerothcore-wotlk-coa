# Templar Oath Chain resource bar

The Templar's resource display, the three-link Oath Chain above the action bar, never appeared (#7341). The
release `patch-B.MPQ` ships the display itself (`Interface/FrameXML/Ascension_CoAResources/Ascension_TemplarResource.lua`,
`ClassMixinTemplar`, the `Templar*` atlas entries and `Interface/CoAResource/templar_atlas.blp`) but never runs it:
`Ascension_CoAResources.xml` does not load that file, and `ClassResources.lua` has no `MONK` branch (the client
class token of the Templar) to drive it. The server already sends what it reads: Oath Chain 704576, the five Oath
auras 804903, 804904, 804922, 804924 and 805332, and Chastise 803157, which every Templar starts with.

The package loads the shipped `Ascension_TemplarResource.lua` from `FrameXML.toc` and adds
`client/Interface/FrameXML/CoATemplarResourceBar.lua`. For a Templar it calls `ClassMixinTemplar:OnLoad` on entering
the world and `ClassMixinTemplar:OnPlayerAura` on the same aura, spell and specialization events that
`ClassResources.lua` uses for the other classes. Each Oath fills one link with its icon, a full chain glows, and
the links pulse during the last five seconds of Oath Chain. Other classes load nothing. It changes no server
behavior.

Tested in game on a Templar with the archive built by the command below.

## Package

```powershell
python tools/package_hotspot_client.py `
  --baseline "C:/Client/Data/patch-B.MPQ" `
  --output "C:/Staging/patch-B.MPQ" `
  --mpqcli "C:/Tools/mpqcli.exe" `
  --load Ascension_CoAResources/Ascension_TemplarResource.lua `
  --lua CoATemplarResourceBar.lua
```

`--load` adds a `FrameXML.toc` entry for a file the baseline already contains, ahead of the `--lua` overlays, and
refuses a path the baseline lacks. Repeat `--lua` to ship it with the other FrameXML overlays. A source merge does
not distribute the archive.
