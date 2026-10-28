Corrected Manastorm client files

Alternative without a client archive: Manastorm.ClientUIFixes = 15 in
manastorm-endless.conf makes the server send these four corrections as interface
Lua at login (see the module README).

The canonical files are under overlay/Interface/ and retain their archive paths:
  Interface/FrameXML/UIParent.lua
  Interface/AddOns/Ascension_Manastorm/ManastormQueue.xml
  Interface/AddOns/Ascension_Manastorm/ManastormQueue.lua
  Interface/AddOns/Ascension_Manastorm/ManastormLoadoutFlyout.lua

With the client closed, add all four to patch B using these exact paths, or build
an override archive with build_keybind_patch.py. The builder requires Windows,
StormLib and the matching original patch B. It refuses an unrecognized UIParent.
Run from the repository root (replace the three example paths):
python -B modules/mod-manastorm-endless/client/build_keybind_patch.py --stormlib "C:/tools/StormLib.dll" --archive "C:/client/Data/patch-B.MPQ" --output "C:/client/Data/patch-Manastorm.MPQ"

Use an archive name/order that the matching client loads after patch B, or copy
its members into patch B. The builder never changes the input archive, refuses
an existing output, and reads every output member back for byte verification.

The older tracked patch-ZZ.MPQ contains only the original two fixes. Do not use
it as the complete updated client package. Regenerate from source for deployment.
The local 'Corrected Addons Needs to get added to patch b' folder is a duplicate
staging convenience and is excluded; overlay/ is the source to publish.
Addon trust comes from the updated worldserver secure-addon list. Do not bypass
RegisterForSave or weaken protected client APIs.
