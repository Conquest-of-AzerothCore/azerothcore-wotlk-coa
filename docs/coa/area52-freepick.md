# Area 52 Free Pick initial setup

This profile enables the native Area 52 character-creation and Season 9 catalog UI in a compatible
Ascension client. It is an initial setup profile, not a complete Free Pick progression implementation.
Use a dedicated realm and matching client/server DBCs as described in [the CoA setup guide](README.md).

## Worldserver configuration

Set these values in `etc/modules/coa.conf`, preserving unrelated settings:

```ini
CoA.ClassModel = "hero"
CoA.MapClass10ToWarrior = 0
CoA.RealmType = "live"
CoA.GameModeMask = 0
CoA.ClientBooleanConfigs = "CONFIG_LEGACY_CHARACTER_ADVANCEMENT_ENABLED=1,CONFIG_CHARACTER_CREATION_ARCHETYPES_ENABLED=1"
CoA.ClientIntegerConfigs = ""
```

Merge the two boolean overrides into any existing list rather than discarding other required overrides.
Keep the matching client's transport settings from the main setup guide. No plaintext-header override is
part of this profile. For remote clients, review `CoA.AllowRemoteClients` in `coa.conf.dist`; it must be
enabled when serving the matching Ascension client beyond loopback.

`live` selects the client records flagged for the persistent realm. `seasonal` selects a different catalog;
enabling the legacy advancement UI alone does not select the Area 52 abilities, talents or Mystic Enchants.
Do not combine `live seasonal` for this profile. The realm flags also affect appearances, vanity offers,
tutorials and Build Creator eligibility. They are independent of the worldserver's PvP rules and rates.

## Realm identity and artwork

Set the dedicated realm's `realmlist.name` in the authentication database to exactly
`Area 52 - Free-Pick`, keeping its existing ID, connection address and port. The inspected client's native
archetype UI checks this full name. Update only the intended realm row; do not create a second placeholder
realm to supply artwork.

In `authserver.conf`:

```ini
RealmCards.Enable = 1
RealmCards.GameMode = 0
RealmCards.Image = "Area52"
```

The realm name, artwork key `Area52`, and client overlay directory `area-52` serve different purposes.
Do not rename client directories to match the display name. Preserve the client's compatible Area 52
overlay. For `CoA.ClassModel = "hero"`, realm information explicitly sends `area-52` as the data path,
so the client loads `Data/area-52/listarchive` and its `patch-D.MPQ` over the base archives.
The display name is sent separately. Other class models retain an empty data path. These settings do not install client assets or replace the data required by the server.

Back up the configuration and realm name before applying this profile. Start authentication before the
worldserver: authserver startup marks realm rows offline, and worldserver startup restores its realm's
online state. After restarting, verify worldserver readiness and the intended realm's online flag.
Fully close and reopen the client before testing. Roll back the profile by restoring the saved settings
and name and restarting the affected services in the same order.

## Configuration delivery

The character-list request sends `SMSG_COA_CONFIG` before realm information and the secure addon list.
This makes the archetype configuration available before new-character creation, without requiring an
existing character to enter the world first. Existing world-entry configuration delivery is retained.
The extension-packet regression checks this order and that normal character enumeration continues.

## Verified scope and remaining work

Local client testing confirmed realm entry, correct realm artwork, Hero character creation, archetype
role/category/build selection, and Area 52 ability, talent and Mystic Enchant listings. The configuration
delivery change was built and tested on that local server. Client files were not modified for this profile.
The data-path fix was also built and tested locally: a level-11 Hero with no spent essence changed
from 28 AE / 2 TE to the Area 52 budget of 11 AE / 2 TE after restarting the client.
These results are for the tested client/data pair, not a guarantee for every client release.

Selecting an archetype does not yet deliver its build. A tested Bulwark character entered the world without
its abilities. Hero learning, point budgets and progression persistence need separate implementation;
correct listings do not establish functional learning. Lua event-recursion and advancement-selection
errors were also reported and remain unresolved. Vanity and build import/export acceptance are deferred.
Do not advertise this setup as a playable or production-ready Free Pick ruleset.

No realm row, account, client archive or private configuration is shipped by this change. Operators apply
the profile to their own dedicated realm; existing CoA defaults and unrelated realms remain unchanged.
