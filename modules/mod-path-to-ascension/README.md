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
  collection, saved outfits, Closest Town/City resurrection, Prestige, the Hero's stat path, Mystic Enchanting
  (scroll purchase, reforges, extracts, collection quality and count, active slots, presets), the Hero Architect
  (opening it, loading a featured end-game build), the 2v2 solo arena queue, Wildcard (level 10, Scrolls of Fortune
  claims, buyback and rerolls, locks, card packs, starter cards, rapid rolling) and the Manastorm (entry,
  purchases, potions, loadout, clears). A delivered vanity item counts as a store delivery.
  A completed tutorial also completes its client achievement.
- **Rewards.** The client's claim (`0x6A8`) grants the tutorial's `TutorialRewards.dbc` items once per character,
  all or nothing, in one character save. Eligibility follows the tutorial's realm, expansion, race, class,
  prerequisite, required spell and game mode fields.
- **Tracking views.** A tutorial with an event-completed quest in `data/sql` can be started from the book or from a
  quest giver (Gorn Axefist offers the riding one). The quest completes with the tutorial, cannot be rewarded by the
  ordinary quest path and leaves the log when the reward is claimed.
- **Novice Rider.** Its race quests (4420430-4420439) are ordinary quests: the book and the riding trainers of the
  race's faction offer them, learning Novice Riding completes them and the turn-in gives the race's starter mount. The tutorial completes once
  that quest is rewarded and the mount is learned; its Path to Ascension reward is claimed separately.

Progress lives in the character's `core.ascension.tutorial_*` settings, which the core saves with the character.

## Dependencies on other systems

The module listens to generic hooks only: `PlayerScript` hooks for trainer spells, pet talents, mail items and quest
eligibility, and `OnPlayerCoAProgress` for the CoA core's Manastorm, collection, resurrection, Mystic Enchant,
Hero Architect, solo arena and Wildcard events.
Game-mode-restricted tutorials ask `OnPlayerGetGameModeMask`, which `mod-coa-challenges` answers; without it those
tutorials stay unavailable. `mod-war-games` supplies the War Games tutorial's matches and `mod-hero-call-board`
the boards.

## Not restored

196 of the 262 tutorials have a progress callback. The pet appearance tutorial, the
custom-difficulty raid tutorials beyond the spawn modes the server offers, the Mark of Triumph vendors, Warchests and
the Callboard Cache contents are outside this module.

## Configuration

`conf/path_to_ascension.conf.dist`: `PathToAscension.Enable`, `.RealmProfile` (default PTR, the column the
installed catalog fills), `.Expansion` (default Vanilla: the expansion whose tutorial variants are offered and
shown to the client; Onyxia's Lair and Naxxramas stay hidden while they are Wrath raids, Mythic+ Dungeons while
the server has no Mythic+),
`.VerifiedProgress.Enable`, `.Rewards.Enable`, `.Tracking.Enable`, `.LegacyContent.Enable`.
