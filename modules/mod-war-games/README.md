# mod-war-games

**War Games**: private arena matches between two groups, arranged by **Teri Glozilk** (creature `9990001`,
spawned in Orgrimmar and Stormwind).

1. A group leader (or a solo player) talks to Teri, picks an arena and types the opposing leader's name.
2. The opposing leader receives the challenge as a gossip window and accepts or declines it.
3. On acceptance both rosters are validated again and transferred into a fresh private instance of the chosen
   map. At the end every participant returns to where they came from.

Rules enforced by the core (`BattlegroundMgr::RequestWargame`/`AcceptWargame`/`CreateNewWargame`):

- Each side is a leader's whole group (or the leader alone), up to a raid; the sides cannot share players.
- Every participant must be online, alive, out of combat, not travelling, not in a battleground or queue, and in
  the same level bracket as everyone else.
- A participant can be part of only one pending challenge; logging out cancels it.
- The match is never rated, never enters the public queues and never borrows another map.

Available maps: Nagrand Arena, Blade's Edge Arena, Ruins of Lordaeron. The other twelve names in Teri's
list are shown but refused until those arenas are restored.

`mod-path-to-ascension` credits the War Games tutorial to everyone who finishes a match, winners and losers.

## Configuration

`conf/war_games.conf.dist`: `WarGames.Enable` (default `1`).
