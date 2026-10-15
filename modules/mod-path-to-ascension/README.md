# mod-path-to-ascension

**Path to Ascension**: the Ascension client's tutorial book. The client draws the book from its own
`Tutorial*.dbc`; this module supplies the server side:

- **Catalog.** At startup it loads `Tutorial.dbc`, `TutorialCategories.dbc`, `TutorialObjectives.dbc` and
  `TutorialRewards.dbc` from `DataDir/dbc` (262 tutorials, 196 quest references). Any other catalog disables the
  module with an error.
- **Verified progress.** Objectives are completed from server events, never from a raw achievement or quest
  credit: levels, innkeeper binds, named NPC visits, Call Board use and daily turn-ins, riding skills, mounting
  outdoors, dual specialization, the dungeon finder, dungeon clears by difficulty (end-game Normal, Heroic, Mythic),
  the fourteen original raids by spawn mode, world bosses, battlegrounds, War Games, arena vendors, PvE/PvP power
  and item level thresholds, Titan Scrolls, profession training at the Book of Artisans, rank training at a
  Book of Ascension, pet talents, auction wins, the Ethereal Bazaar, transmogrification, vanity items, appearance
  collection, Closest Town/City resurrection and the Manastorm (entry, purchases, potions, loadout, clears).
  A completed tutorial also completes its client achievement.
- **Rewards.** The client's claim (`0x6A8`) grants the tutorial's `TutorialRewards.dbc` items once per character,
  all or nothing, in one character save. Eligibility follows the tutorial's realm, expansion, race, class,
  prerequisite, required spell and game mode fields.
- **Tracking views.** A tutorial with an event-completed quest in `data/sql` can be started from the book or from a
  quest giver (Gorn Axefist offers the riding one). The quest completes with the tutorial, cannot be rewarded by the
  ordinary quest path and leaves the log when the reward is claimed.

Progress lives in the character's `core.ascension.tutorial_*` settings, which the core saves with the character.

## Dependencies on other systems

The module listens to generic hooks only: `PlayerScript` hooks for trainer spells, pet talents, mail items and quest
eligibility, and `OnPlayerCoAProgress` for the CoA core's Manastorm, collection and resurrection events.
Game-mode-restricted tutorials ask `OnPlayerGetGameModeMask`, which `mod-coa-challenges` answers; without it those
tutorials stay unavailable. `mod-war-games` supplies the War Games tutorial's matches and `mod-hero-call-board`
the boards.

## Not restored

About 85 of the 196 client quest references have a progress callback. Outfit creation and pet appearance
tutorials, the custom-difficulty raid tutorials beyond the spawn modes the server offers, the Mark of Triumph
vendors, Warchests and the Callboard Cache contents are outside this module.

## Configuration

`conf/path_to_ascension.conf.dist`: `PathToAscension.Enable`, `.RealmProfile` (default PTR, the column the
installed catalog fills), `.Expansion` (default Vanilla: the expansion whose tutorial variants are offered and
shown to the client; Onyxia's Lair and Naxxramas stay hidden while they are Wrath raids, Mythic+ Dungeons while
the server has no Mythic+),
`.VerifiedProgress.Enable`, `.Rewards.Enable`, `.Tracking.Enable`, `.LegacyContent.Enable`,
`.StarterMountBridge.Enable`.
