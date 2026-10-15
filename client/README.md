# Ancient Enchanting Altar map markers

## Install the client update

1. Close the game. Download this PR branch and find `client/AncientEnchantingAltars`.
2. Copy that entire folder into your game folder's `Interface/AddOns` directory. The resulting paths must be:
   - `Interface/AddOns/AncientEnchantingAltars/AncientEnchantingAltars.toc`
   - `Interface/AddOns/AncientEnchantingAltars/OutlandAltarPOIs.lua`
3. Launch the client, enable **Ancient Enchanting Altars** in the character-selection AddOns list, and log in.
4. Check Outland and the Netherstorm, Terokkar Forest and Nagrand maps. Hover the altar icons to see the notes.

No MPQ editing, cache deletion, external dependencies or downloaded model assets are required on the compatible Ascension client. This uses its built-in `DB_MapPOI` API and existing icon 188. Stock Blizzard clients do not have that API. To undo the client update, close the game and remove only `Interface/AddOns/AncientEnchantingAltars`.

## Server and distribution

Apply the pending world SQL through the normal server database updater. It supplies template 80148 and the seven approved permanent placements. Merging that SQL does **not** distribute the client addon: client maintainers must include the two files above in their client package or launcher manifest. This PR does not change an upstream launcher feed.

The four Azeroth map markers already exist in the compatible client. The addon adds only the three Outland markers with the same title, icon, scale and map/minimap flags. Registration replaces matching IDs, so relogging, teleporting and the earlier Area 52 marker addon do not create duplicate icons. The markers are global like the existing Azeroth markers and SQL placements; no Mystic Enchant mechanics are enabled by this addon.

Altars primarily serve Free Pick and Bronzebeard. Enchant rules and interactions are outside this placement-only change. The seven placements and three notes were visually approved on Area 52; standalone-addon packaging and other-mode smoke testing remain pending.
