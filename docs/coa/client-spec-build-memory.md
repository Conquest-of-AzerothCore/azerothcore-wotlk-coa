# Talent window: inspecting another specialization keeps your build

Choosing another specialization in the talent window only edits the client's pending build. The client
drops every entry of the specialization you leave and adds only the identity and signature of the new
one, so going back to your own specialization showed an empty tree until you pressed Discard. The server
was never involved and nothing was lost, but pressing Apply in that state would have saved the empty tree.

`client/Interface/FrameXML/CoASpecBuildMemory.lua` wraps `C_CharacterAdvancement.SwitchActiveChrSpec`. Before
a switch it exports the pending build of the specialization being left with `ExportBuild`. When the switch
returns to a specialization whose build was exported earlier in the same pending session, it imports that build
back with `ImportPendingBuild`, which validates it in full and leaves the plain switch result when it is
refused. The remembered builds are forgotten when the pending build is cleared (Discard, reset) and when the
server reports a known-entry change (Apply, level up, login). It never sends anything to the server, never
changes what Apply uploads, and does not touch the Apply, Go Back and Discard dialog.

## Package

```powershell
python tools/package_hotspot_client.py `
  --baseline "C:/Client/Data/patch-B.MPQ" `
  --output "C:/Staging/patch-B.MPQ" `
  --mpqcli "C:/Tools/mpqcli.exe" `
  --lua CoASpecBuildMemory.lua
```

The tool copies the release's effective `patch-B.MPQ`, adds the Lua file and appends one loader entry to
`FrameXML.toc`, then extracts and compares every member. Pass `--lua XPHotspots.lua` as well to ship both
overlays in one archive. Close the client before installing, keep the previous archive for rollback, and
update the release manifest hash through the launcher's normal release process. A source merge does not
distribute the archive.
