# mod-portablemail

Restores the world objects that CoA's portable gadgets summon, so the items work again.

## The problem

The gadgets are ordinary items whose on-use spell creates a temporary world object:

| item | name | spell | object it spawns |
|---|---|---|---|
| 1903512 | Gnomish Portable Post Tube | 985210 | 1903511 - mailbox |
| 1903510 | Gnomish Portable Transpolyporter | 979611 | 1903510 - spellcaster |
| 1903513 / 1903514 / 3648545 | Mystic / Volatile Mystic / QA Enchanting Altar | 985211 / 985212 / 985211 | 1903512 - binder |
| 1903515 | Fel-Infused Gateway | 979411 | 1903520 - spellcaster |

The spell effect is `SPELL_EFFECT_TRANS_DOOR`, so the core spawns the gameobject named in its
`MiscValue` after looking it up in `gameobject_template`
(`Spell::EffectTransmitted`, `src/server/game/Spells/SpellEffects.cpp`). When that row does not
exist the effect returns early - the item is consumed, no object appears, and the server logs:

```
Gameobject (Entry: 1903511) not exist and not created at spell (ID: 985210) cast
```

None of those four rows existed in the world database. `item_template`, `Spell.dbc` and the
summoned "Anti-Block Dummy" creature (289612) were all fine; the object was the missing half.

The objects are the half that can be restored from realm data; what a player *does* with them is
not. That matters for the altars: they summon and stand as they did, but right-clicking one
toggles nothing here, because the enchanting itself is CoA's own client feature (Bronzebeard),
not server content. The mailbox, both transpolyporters and the gateway work end to end.

There was a second, smaller defect behind the same items. How long a summoned object stands is
the spell's duration, not the object's, and the Fel Gateway's did not match its own tooltip:
the tooltip promises "Demonic Transpolyporter combusts after 30 seconds" while the spell's
`DurationIndex` pointed at 180 seconds, so the gateway stood for three minutes. That text comes
from the client's copy of `Spell.dbc` and is drawn client-side, so the lifetime is the half the
server can set - and now does.

## The fix

`data/sql/db-world/portablemail.sql` restores the four rows with `REPLACE INTO`, keyed on
`entry`, so re-applying it always reproduces the same data. The DB updater applies module SQL at
startup (`Updates.EnableDatabases`), and the module then verifies the result.

The values are the realm's own rows, not a reconstruction. The client caches the server's answer
to the gameobject query, so `gameobjectcache.wdb` holds exactly what the realm served - type,
model, name, size and `Data0..Data23`. They were read out of those caches with the datamine's
`WGOB` reader, and every captured copy agreed with every other copy: 98 caches carried the post
tube's row, 164 the altar's, 124 the demonic portal's, 22 the gnomish portal's. The mapping
between a cache record and a `gameobject_template` row was validated against the rows held in
both places (type, displayId, name, size and Data0/Data1 matched exactly).

The same file carries one `spell_dbc` row: the game's own row for the Fel Gateway's spell
(979411) with `DurationIndex` changed from 25 (180 s) to 9 (30 s) and nothing else touched.
`spell_dbc` replaces a whole DBC row, so all 234 columns are present; a partial row would zero
every field it omits.

The models ship in the client, so once the rows exist the objects render:
`World\Custom\7dl_dalaran_postofficepipe01.mdx` (post tube, `patch-WC3.MPQ`),
`World\Goober\G_GoblinTeleporter.mdx` (gnomish portal), `7nb_nightborn_cage01.mdx` (altar),
`7fx_orderhallportal_deadscarrift.mdx` (demonic portal).

## What the module does at runtime

* `PortableMail.VerifyOnStartup` (default on) - one check at startup that each listed item casts
  its spell on use, the spell summons the expected object with the expected lifetime, and the
  object has the expected type, model and size. Both portals must cast teleport spell 979612 on
  click, and that spell must exist in the server's spell data. An error names the broken link;
  an unrelated object row or a portal without a click spell cannot make the check pass.
  The same list is logged with each gadget's lifetime. These are data checks: they do not
  validate the altars' client enchanting feature.
* `.portablemail status` (GM, also from the console) - the same list on demand.

The module never creates or grants items. On CoA the post tube was handed out by the onboarding
chain ("Path to Ascension: Collection and Capitals"), not sold by a vendor; that grant does not
exist here, so the item is still obtained the usual way for testing (`.additem 1903512`).

## How to confirm it

1. Start the worldserver and look for `mod-portablemail: all 4 portable gadgets are complete
   (item, spell and world object).`, followed by one line per gadget with its lifetime:

   ```
     Gnomish Portable Post Tube [mailbox] - item 1903512 -> spell 985210 (lives 3m) -> object 1903511: ok
     Gnomish Portable Transpolyporter [spellcaster] - item 1903510 -> spell 979611 (lives 30s) -> object 1903510: ok
     Portable Mystic Altar [binder] - item 1903513 -> spell 985211 (lives 5m) -> object 1903512: ok
     Demonic Portable Transpolyporter [spellcaster] - item 1903515 -> spell 979411 (lives 30s) -> object 1903520: ok
   ```

2. `.additem 1903512`, right-click it - a post pipe appears at your feet and gives mail access.
   It despawns by itself after 3 minutes; the item has a 30-minute cooldown.
3. Same for the Fel-Infused Gateway (1903515): its portal stands for 30 seconds, as its tooltip
   says, and clicking it ports you to your hearthstone.
4. `.portablemail status` lists each gadget, its lifetime and whether its object is present.
