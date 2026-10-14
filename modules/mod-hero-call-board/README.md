# mod-hero-call-board

The **Hero's Call Board** (Stormwind, `402000`) and the **Warchief's Command Board** (Orgrimmar, `402001`) with
47 daily quests, answered in the form the Ascension client's Call Board window expects:

- The board opens on its three categories (**PvE**, **Profession**, **PvP**) and sends the daily, weekly and arena
  reset times the window's timers read. It always shows the yellow "available" marker.
- A category lists the quests in progress and the quests the character may take, filtered before the 32-entry menu
  limit, and sends their quest data ahead of the menu. Quests sorted by a zone, such as the Hero's Call and
  Warchief's Command orders, are listed under PvE.
- Reaching a level offers the faction's zone orders unlocked at that level as a "Quest Discovered!" pop-up
  (`SMSG 0x927`); accepting it takes the order without visiting a board. Each order is offered only on the level-up
  that unlocks it: dismissing a pop-up is not reported to the server, so logging in offers nothing again and a
  dismissed order is taken from a board.
- Accepting (including **Accept All**), refusing, turning in or abandoning a board quest re-sends the open category
  instead of closing the window. Every quest still passes the core's own checks.
- Dailies that need a server event are credited here: five duel victories (`80651`), a battleground win (`81260`),
  and dungeon finder clears of a Normal, Heroic or Mythic dungeon (`81042`, `81041`, `80652`).
- On a Wildcard realm, where the CoA core starts the Darkmoon - Season 10 Wildcard event (`194`), the boards also
  offer that season's board quests up to level 60 and its weekly leader quests: **Lead a Dungeon!** (`100078`, 5000
  Runes of Ascension) credits the group leader when a dungeon's final encounter falls, **Lead a Raid!** (`100077`,
  10000) when one of the listed final raid bosses dies (the classic raids have no usable last-encounter data). There
  is no Mythic+, so Lead a Mythic+ is not offered.

The board rewards are the quests' own Runes of Ascension. The Callboard Cache is handled by the CoA core.

## Configuration

`conf/hero_call_board.conf.dist`: `HeroCallBoard.Enable` (default `1`) and `HeroCallBoard.AutoOffer` (default `1`).
