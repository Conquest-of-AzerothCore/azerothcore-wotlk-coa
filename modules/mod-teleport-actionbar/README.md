# mod-teleport-actionbar

Makes CoA teleport tokens usable from the spellbook collection and from an action bar
button, and keeps each stone on the side of the war it belongs to.

## Why

CoA teleport tokens (the `Stone of Retreat` collection and the Arcane/Balance Tomes)
teach their teleport spell when the item is used: the item carries `spellid_1 = 55884`
(the generic learn spell) on the on-use trigger and the taught spell on the
`LEARN_SPELL` trigger (`spelltrigger_* = 6`). The teleport itself is the learned spell,
which the matching Ascension client shows in its spellbook's vanity tab but will not
hand over as a bag item.

The server cannot change what the client lets a player pick up, but it can control what
the item does and whether a cast is allowed to happen.

## What it does

**1. Known token teleports work like any other spell.** At startup the module reads the
token teleports from the world database: every item that teaches a spell through the
`LEARN_SPELL` trigger whose taught spell has a row in `spell_target_position`. Casting
one from the spellbook works, and dragging it onto an action bar button keeps working
(the client stores that as an ordinary action button).

**2. Using a token item casts the teleport it unlocked.** `Player::CastItemUseSpell`
routes every item whose first spell is the generic learn spell through spell 55884 with
the item as the cast item; an `AllSpellScript` on that path casts the unlocked teleport
after the item's own learn effect has run. So a stone used from the bag, or from an
action bar button it was dragged onto, teleports. Disable with
`TeleportActionBar.CastFromItem = 0` to keep CoA's teach-only behavior.

**3. A stone only works for the faction whose hub it is.** Wall-of-the-war rules: an
Alliance character cannot use a Horde stone and vice versa, and shared hubs (Dalaran,
Shattrath, Booty Bay, Gadgetron, the instance terraces ...) stay open to both sides.
The check runs at cast time on every spell, so it covers the spellbook, an action bar
button, the item itself (a foreign stone is refused before it can even be learned), and
the module's own item-triggered teleport. A refusal shows the client's own cast error
plus a line naming the hub and its side. Disable with
`TeleportActionBar.EnforceFaction = 0`.

The Stockade dungeon stone is shared. Its Horde warning identifies a hostile landing;
the separate Stormwind capital stone remains Alliance-only.

The side of each hub is a generated table, `src/StoneFactionData.h`: every destination
was classified from the `FactionTemplate` of the NPCs standing at it (Alliance / Horde /
neither), then reviewed, with shared sites and a few camps whose only nearby NPCs are
holiday guests set by hand. Regenerate it from the destination list and the world
spawns if the stones ever change.

**4. Automatic button placement is optional.** `.teleportbar` (or `.teleportbar assign`)
fills empty slots with the known token spells; `TeleportActionBar.OnLogin`,
`OnLearnSpell` and `OnSpecChange` do the same automatically and are all off by default,
so stones reach a bar only when the player drags them there. Only empty slots inside the
configured range are used, and a spell already on a button in that range is left
untouched, so a player's own layout is never overwritten.

| Config | Purpose |
| --- | --- |
| `TeleportActionBar.Enable` | Master switch |
| `TeleportActionBar.EnforceFaction` | Refuse a stone whose hub is the other faction's |
| `TeleportActionBar.CastFromItem` | Token items cast the teleport they unlocked when used |
| `TeleportActionBar.ItemNameFilter` | `LIKE` pattern limiting which token items count (default: the Stone of Retreat collection) |
| `TeleportActionBar.OnLogin` / `OnLearnSpell` / `OnSpecChange` | Where the module may fill in empty action buttons |
| `TeleportActionBar.FirstButton` / `LastButton` | Button slots the module may use |
| `TeleportActionBar.MaxButtons` | Cap per character, `0` for no cap |
| `TeleportActionBar.LearnCarriedTokens` | Also teach the teleport of every token the character carries (CoA teaches those on use, so it is off by default) |

## Commands

| Command | Effect |
| --- | --- |
| `.teleportbar` | Place missing buttons now |
| `.teleportbar learn` | Teach the carried tokens' teleports and place their buttons now |
| `.teleportbar sides` | Report the stones you know split by side, with the hubs of the other faction |

## Notes

- The teleport cast from an item is a triggered cast, so it does not respect the
  teleport spell's own cooldown. Casting the spell from its button does.
- The first use of a stone still teaches its spell, and the stone keeps working
  afterwards.
- The module never creates or grants items: the stones live in the client's collection
  UI and on the action bar only.
