# mod-book-of-artisans

Restores the two profession trainer books - the **Book of Artisans** and the **Beginner's Book
of Artisans** - the page they answer a right click with, the trainer window it opens, and the
shop behind the page's second option.

The book is not its own trainer, and its shop is not its own shop. It is the realm's profession
rows seen from one place - the same rows, the same states, the same purchase checks, the same
refusals, only reachable without travelling between sixteen capitals - and beside them a trade
supplier's counter, so the character who just learned a trade can buy the thread and the flux
to use it. It also carries the recipes the realm's profession trainers teach (#5818), shown only
for a trade the character knows and once their skill reaches each recipe's requirement; patterns
that are sold, dropped or discovered stay where they were. And what its
window leaves out is every rank the character cannot train yet: the window is the entry rank
of each profession, the ranks their skill has reached, and the ranks they already know, never
the top of a ladder they have not climbed. Everything below is arranged around those rules.

## The problem

The books are props a player right-clicks. The realm shipped one of them in a state that could
not be used and did not ship the other at all:

| | before | recovered |
|---|---|---|
| 57500 Book of Artisans | display **15901** (`Creature\ReinDeer\ReinDeer.mdx`, 0.2 scale), type 7, type_flags 0, rank 0, movementId 0, no script, `UNIT_FLAG_NOT_SELECTABLE` | type 8 (critter), type_flags 1048576, rank 1, display **48503**, HealthModifier 1.0, movementId 999, `unit_flags` 768 |
| 57524 Beginner's Book of Artisans | did not exist | type 10, type_flags 134217728, rank 1, display 48503, HealthModifier 1.31781, movementId 999, `unit_flags` 768 |

A book that renders as a deer is a cosmetic problem; a missing creature is a functional one. A
third one is worse than both: the shipped row also carried `UNIT_FLAG_NOT_SELECTABLE`
(0x02000000), which no other prop on the realm has and which takes away the only interaction a
book has - a non-selectable unit is not clickable, so the right click never reached the script.
The flags then cost it the window a second time: with the gossip bit set, the client reads the
book as a gossip NPC and drops the trainer list it is answered with (see *The scripts* below).
The client's own strings send players to it ("Visit a **Beginner's Book of Artisans** and learn a
profession", `TutorialObjectives` 76, and the "Path to Ascension: Power of Professions"
achievement 87250), and the only book standing in the world was the *full* one outside the
Northshire inn (guid 5300681, removed here), so there was nothing named "Beginner's" anywhere.

Only 57500 carried a trainer (`creature_default_trainer` -> `trainer` 200001); the beginner's
copy had neither creature nor trainer.

## The evidence

Both rows come from the preservation archive's record of the live realm (`creaturecache`, 254
and 184 client submissions, captured 2026-09-10, ten game modes agreeing):

* display **48503** is `Creature\FlyingBook\FlyingBook_01_Pet_purple.mdx`: the client's
  `CreatureDisplayInfo` 48503 -> `CreatureModelData` 5633. 48501 is the same prop without a
  tint (`FlyingBook_01_Pet.mdx`), which the realm already uses for the Book of Ascension.
* the remaining captured fields are the ones the SQL sets: `type`, `type_flags`, `rank`,
  `HealthModifier`, `ManaModifier`, `movementId`, and an empty subname/icon.
* `movementId` 999 is the value every other restored CoA prop on this realm carries, including
  the Destiny Weavers.

What the book *did*, from the same sources:

* the trainer behind it is the realm's own (200001), and every one of its rows is free
  (`MoneyCost` 0). Old realm reports describe the same thing from the player's side - *"a book
  that can learn all the craft and professions available"* - and the realm's own fix list
  records the books being made free. A book in the bag is therefore a profession trainer
  wherever the player is.
* the **Beginner's Book showed a gossip page** before anything else, not a window straight away:
  the new-player tutorial anchors its first popup to the `GOSSIP_SHOW` event of creature
  **57524** (`Ascension_NewPlayerExperience/old/Tutorial_Professions.lua`, popups `PROFESSIONS1`
  and `PROFESSIONS2`, quest 1903542, "Visit a Beginner's Book of Artisans and learn a
  profession"). The full Book of Artisans is the place that answers with the trainer window, the
  way the realm's other books do.

Two things the capture does **not** carry, and how they are handled:

* **Spawn positions.** The archive keeps one example sighting per creature and says so itself
  ("One example sighting; not a complete spawn list"). It records 23 sightings for 57500 across
  the Barrens, Durotar and Stormwind City, and 10 for 57524 across the Barrens and Durotar, but
  only one coordinate each - both in the Barrens south of Ratchet. Only the **Beginner's**
  book's position is used: it is the world prop the tutorial sends players to. The **full**
  book is not placed at all - it is a summonable companion (item -> spell 750750 -> creature
  57500), so it belongs nowhere on the map. The world database had one standing outside the
  Northshire inn (guid 5300681); the SQL removes it.
* **Orientation.** Not recorded either. The placed book faces Ratchet's innkeeper, the nearest one.

## The row set: the professions, and only the professions

A row of the book is a row that *teaches a profession*, and which spells those are is not a
judgment call: the client's own `Spell.dbc` says so. A spell whose effect is one of these three
is one:

| effect | | what it is |
| --- | --- | --- |
| 44 | `SPELL_EFFECT_SKILL_STEP` | the "Apprentice ... Grand Master <profession>" rows, which learn the trade and raise its ceiling |
| 47 | `SPELL_EFFECT_TRADE_SKILL` | the trade-skill learn spell itself |
| 118 | `SPELL_EFFECT_SKILL` | a bare skill grant (CoA's Bushcraft) |

**What the realm shipped.** 200001 held 4739 rows, and they were not the professions: every recipe
the game has was in there, from the pattern a vendor sells to the last tier of a profession's
catalogue. **93 of them are profession rows**; the other 4646 are what a player had to scroll
through to find the row they came for.

**What survives.** Those 93, and nothing else, so the book offers the same thing at the top of the
ladder as at the bottom. Sixteen professions carry rank rows, and Bushcraft is a single grant:

| profession | ranks | rows |
| --- | --- | --- |
| Blacksmithing, Leatherworking, Alchemy, Herbalism, Cooking, Mining, Tailoring, Engineering, Enchanting, Fishing, Skinning, Jewelcrafting, Inscription, First Aid | Apprentice, Journeyman, Expert, Artisan, Master, Grand Master | 84 |
| Woodcutting, Woodworking | Apprentice, Journeyman, Expert, Artisan | 8 |
| Bushcraft | one skill grant | 1 |
| | | **93** |

**What that costs, and what it does not.** 84 of the 93 are taught by the realm's own trainers as
well - a capital's blacksmith, a camp's cook - so the book is a convenience and not the only way
in. The other **9 are taught by no other trainer anywhere in the realm**: Bushcraft, Woodcutting
and Woodworking are CoA's own professions and the book is their only teacher. That is why the
whole ladder is kept rather than the apprentice rows alone: a book that dropped them would leave
professions that can be learned nowhere at all.

**What the book shows of those rows.** Holding a rank and offering it are not the same thing. A
character who has never held a needle has no use for Grand Master Tailoring: it would sit in the
window as a red line nobody can buy, from the first click to the last, and the same is true of the
five ranks between it and the one the character is entitled to. So the window carries the rows the
character can train *now* - the entry rank of every profession, the ranks their own skill has
opened, and the ranks they already know, drawn greyed. That is **16 rows** for a character who has
learned nothing: the fourteen trades plus Woodcutting and Woodworking. (Bushcraft, the seventeenth
profession, is gated to another class in the client's own `SkillLineAbility.dbc` - `classMask`
0x100000 - so it is not a row for anybody else at all.) Learn the apprentice rank, take the skill
to 50, and journeyman is in the next window the book sends, because the book re-sends after every
purchase. Everything above that is absent from the list rather than red in it.

The rows themselves are the realm's own `trainer_spell` rows, untouched - their skill line,
required skill, required level and required ability - so nothing is available earlier or under
other conditions than at the trainer that teaches it. All 93 are free (`MoneyCost` 0), which is
the realm's own convention for these books; the fix list in *The evidence* above is the realm
making them free.

**The Beginner's Book** (trainer 200002) is the same list cut to one row per profession - the
entry rank, `ReqSkillRank = 0` - rebuilt from 200001 every time this SQL runs, so it can never
drift from the full book and can never hold a row the full book does not. It holds 17 rows:
Apprentice of each of the sixteen professions, plus Bushcraft's grant. Nothing above the first
rank is in it at all: that book teaches the first step, and the ladder is the full book's.

**Why the ids are written out.** SQL cannot ask the client what a spell does, so the rows are kept
by an explicit list of the 93 ids. The list is the set that was in the book already, filtered to the
spells the client's `Spell.dbc` gives effect 44, 47 or 118 - the file's own comment says the same
thing next to it - so a client whose spells change moves this list and nothing else.

## The page, and the shop behind its second option

A right click on either book opens the original's page rather than a frame, and the page has the
original's two options:

| option | icon | what it opens |
| --- | --- | --- |
| I require training! | trainer | the trainer window, filtered to the rows the character can train |
| I would like to browse your goods. | vendor | a vendor list carrying Edna Mullby's stock |

The page is data - `gossip_menu_option` 57500, its line in `npc_text` 57500 - and the core sends
it. Both options are ordinary gossip actions (`GOSSIP_OPTION_TRAINER` 5 and
`GOSSIP_OPTION_VENDOR` 3), so the client asks for the trainer list or the vendor list itself;
the module takes over exactly one of the two, the training option, because that is the only way
the window it opens is the filtered one, and the goods option is left to the core. The page is
also what the new-player tutorial waits for: its first popup is anchored to `GOSSIP_SHOW` on the
Beginner's Book (see *The evidence*).

Every half of that chain needs its flag, and `npcflag` is **177**: gossip (1), so the client asks
for the page at all; trainer and class trainer (48), so it will draw the window; vendor (128), so
the core will send the shelves. The bits are not decoration, and the warning that usually goes
with them is about a *list nobody asked for*: a trainer list pushed to a unit the client reads as
a gossip NPC is dropped on the floor, which is what the Books of Ascension ran into with gossip
and vendor and no trainer bit (`rev_20260918_21_spellbook_trainer.sql`). Both lists these books
send are asked for, one by each option, so the flag that costs another trainer its window is the
flag that earns these two their page.

The shelves are Edna Mullby's: entry 1286, "Trade Supplies" in Stormwind, cloned row for row
into `npc_vendor` for both books - **29 rows**, Coarse Thread at 10 copper through Imbued Vial at
2 gold, plus the one limited-stock design she carries. `npc_vendor` holds no price (the core and
the client both read the item's own `BuyPrice`), so cloning the rows *is* "the same items at the
same prices", and her own rows are never written to. The 29 prices add up to 41440 copper, which
is what the scenario asserts the shelves come to. The only difference between the two books is
the trainer behind the first option: one row per profession for the beginner's, the whole ladder
for the full book.

## The fix

`data/sql/db-world/book_of_artisans.sql` carries the data, the module carries the one thing data
cannot express.

**The data** (applied by the core's own module updater - directories under
`modules/*/data/sql/` whose name contains the database name are picked up at startup). Every
statement is idempotent; the file is applied again whenever it changes.

* 57500 is created if the database has no row for it - a rebuilt world, a fresh schema - and
  otherwise updated to the captured values; 57524 is created as a clone of it with the three fields
  the capture records differently. Cloning keeps every column the realm already had a sensible
  answer for (faction, speeds, immunities, flags) instead of inventing them. The `trainer` row
  200001 is written here too, for the same reason: only the realm's own database carried it, so a
  database built from this repository would have had no trainer for the full book.
* `unit_flags` 768 (`IMMUNE_TO_PC | IMMUNE_TO_NPC`) for both, which is what the realm's own
  restored props carry - the Destiny Weavers have exactly this pair.
* `creature_template_model` 48503 for both, and the `creature_model_info` row for 48503. The
  model info row is load-bearing, not cosmetic: without it the core logs *"No model data exist
  for `CreatureDisplayID`"* and the creature is dropped when it loads.
* Trainers: 57500 keeps 200001; 57524 gets 200002. The list is cut to the 93 profession rows
  first, and the beginner's copy is rebuilt from what is left, so it can never hold a row the full
  book does not.
* Spawns: guid 9000031 (57524) at `-887.072, -3778.650, 11.735`, map 1 - the Beginner's book's
  recovered position. 57500 is deliberately left unplaced, and the world database's own
  Northshire spawn of it (guid 5300681) is deleted.

**The scripts** (`src/book_of_artisans.cpp`) exist because the request for the window has to be
answered on the path the client actually uses, and because a window is a snapshot.

* **The flags are the difference between a page and nothing at all.** Both books carry `npcflag`
  **177** - gossip, trainer, class trainer, vendor - which is what makes the client ask for the
  page and then accept both frames the page's options lead to. *The page, and the shop behind its
  second option* above says why each bit is there, and what the Books of Ascension hit by
  carrying gossip and vendor without the trainer bit: clickable, and inert.
* **The window is the core's own, not the module's.** A right click is answered with
  `WorldSession::SendTrainerList`, which is `Trainer::SendSpells`: the book's trainer row, the
  rows of it the character can train, in the order the rows load in, its own trainer type (`Tradeskill`, 2), and each row
  carrying the state `Trainer::GetSpellState` gives it - **0 available, 1 unavailable, 2 already
  known** - which is the mechanism the 3.3.5 client draws as a buyable row, a red row and a grey
  "already known" row. A window built anywhere else would be a second opinion about the same
  character, and `GetSpellState` is also what gates the purchase, so a list built here could only
  ever disagree with the sale. It also means every requirement a trainer applies - skill line
  and rank, level, required ability, and the previous rank of a ladder's chain - is applied to the
  book unchanged, because it is the same function reading the same row. The one gate that lives
  only in the purchase is the count of free primary profession slots: `Trainer::CanTeachSpell`
  refuses a profession's first rank while the character has none left, which is the whole point of
  a Craftsman's Codex, and the window does not know about it. A character whose slots are all spent
  therefore sees the other trades offered and is refused when they click, exactly as they are at a
  placed trainer.
* **The rows out of reach are dropped where the state is decided.**
  `WorldSession::SendTrainerList` and `Trainer::SendSpells` take a `bool onlyTrainable`, `false` by
  default (the whole of that change: `Trainer.h`, `Trainer.cpp`, `WorldSession.h`, `NPCHandler.cpp`).
  With it set, a row whose `GetSpellState` is `Unavailable` is not written at all; the state is
  asked once and then both decides whether the row is written and what the row reads, so the window
  can never offer a row the purchase would refuse. Every placed trainer on the realm - and the core's handler for any
  creature this module does not own - keeps sending its whole list, red rows included; the two
  books are the only creatures that ask. Known rows are deliberately kept: the client draws them
  greyed, they are the only record in the window of what the character already has, and a greyed
  row costs nothing to look at. Money is deliberately not part of it: a spell the character cannot
  afford is still one they can train.
* **The window is a snapshot, and the book refreshes it.** It is computed from the character on
  every request, and after every purchase from the book the list is sent again: learning a
  profession, buying a rank and learning a recipe all change other rows, and a client that was
  only told the state from before the purchase would go on offering a recipe the character
  already owns. Reopening and relogging recompute from the character again; nothing is cached
  anywhere, and no list is ever sent that was not just built.

  Deliberately not done: pushing a new list when a profession skill goes up elsewhere
  (crafting). A 3.3.5 trainer window is a snapshot the player reopens; pushing a full list on
  every skill-up would send it behind a window that may already be closed, and the client cannot
  tell the server that it closed the frame.
* **Both ways to the window are answered.** The page's first option comes through the module's own
  `OnGossipSelect`, which sends the filtered list; a client that asks for the list without the
  page - `CMSG_TRAINER_LIST` on a trainer-flagged unit - is answered by the server script
  instead, and both roads end at the same window. Training a row still goes through the core
  (`CMSG_TRAINER_BUY_SPELL` -> `Trainer::TeachSpell`), so the purchase, its price, its failure
  reasons and the learned spell are the core's own.

The module also verifies the chain once at startup and logs an error naming the missing half if
a creature, its model, its model info, its trainer row, its page, its shelves or one of the three
flags disappears - every one of them fails silently in game, which is why each is checked and
named rather than left to a click that answers nothing.

## How it is verified

Two things are checked: the list, from outside the game, and the book itself, in a real
worldserver.

**The list, against the client.** The profession spells of the client's `Spell.dbc` are the ones
carrying effect 44, 47 or 118, and the rows the realm's 200001 already held that are not among them
are recipes: 4739 rows in, 93 out, so 4646 left the book and every one of them is still taught,
sold or dropped where it always was. What the SQL leaves behind is checked by reading it back:

* 200001 holds those 93 rows and nothing else, and every one of them is a profession row;
* 200002 holds the same rows cut at `ReqSkillRank = 0` - 17 of them, row for row identical to the
  full book's;
* the full book then adds the recipes profession trainers (`trainer`.`Type` 2) teach under the eleven
  crafting and secondary trades, each at the lowest requirement any trainer asks
  (`data/sql/updates/pending_db_world/rev_20261001_10_book_of_artisans_recipes.sql`, which sorts
  after this module's file and touches none of its rows); the beginner's book holds no recipe.

**The book, in a real worldserver** (`apps/coa-gameplay-test/scenarios/book-of-artisans.json`,
69 steps, 52 of them assertions) does what a player does: it right-clicks, reads the page, and
takes one option at a time. The page offers two options and opens no frame by itself. The first
option sends a window of 16 rows for a character who has learned nothing - one per trade - with
3911 and 2020 offered and available and 13977880 (Woodcutting, which no other trainer in the
realm teaches) offered with them, while every rank above the entry one is **absent from the list
rather than red in it**: Grand Master Blacksmith (51298), Journeyman Tailor (3912), Journeyman
Blacksmith (2021), Bushcraft (573523, another class's profession) and the tailoring patterns
2393, 7420 and the untrainable 2387 all read `trainer_window_state` -1. The second option
sends the shop: 29 rows, Coarse Thread at 10, Rune Thread at 5000, the limited-stock design at
1500, an item Edna does not sell absent, and the whole list adding up to 41440 - the same items at
the same prices as her own counter. Then the training: buying 3911 teaches the tailoring skill spell
(3908), leaves its row known and the window the same size; asking for 3912 at apprentice skill is
refused, which is the sale being gated even when the row is not on screen; raising tailoring to
75 puts 3912 in the next window as an available row - the window grows by exactly one row - and
buying it grants 3909. The beginner's book carries the same page and the same 29 shelves, and its
window holds the entry rows only: 16 rows at skill 75, with 3912 not in that book at all.

Run it with the harness (`apps/coa-gameplay-test/README.md`):

```powershell
python apps/coa-gameplay-test/run.py run apps/coa-gameplay-test/scenarios/book-of-artisans.json `
  --worldserver <build>/bin/RelWithDebInfo/worldserver.exe --config <worldserver.conf> `
  --mysql <mysql.exe> --mysqldump <mysqldump.exe> [--database-client-config <admin-client.ini>]
```

A fixture creature spawned for a scenario needs the book's faction (35). The harness default (14)
makes `Player::GetNPCIfCanInteractWith` refuse it, and the symptom is a silent click.

The scenario moves tailoring with the harness's `set_skill` action, which was added for it: a
scenario session is plain player session, so the GM `setskill` command is not available to any
scenario, and a rank above the entry one cannot be reached without moving the profession's skill.

The shop is read with four metrics that were added with it - `vendor_list_packets`, `vendor_items`,
`vendor_price` (by `item`) and `vendor_price_sum` - because a list of goods is the whole of what a
shop can be judged on from the server side, and the sum of its prices is a fingerprint of the
stock it came from.

The data half is verified by applying the file to the world database and reading the rows back:
the two creatures, the two trainers, the 93 and 17 rows, the model and its model info, the page, the
two options, the 29 shelves and the spawn all hold what the tables above say, and a second apply
changes no row in any of them. The scenario was run against a worldserver built with this module,
and every step passed.

## What is still missing

* **The tutorial that sends players there.** Quest 1903542 "Path to Ascension: Power of
  Professions" (the objective is "Visit the Beginner's Book of Artisans outside the inn and learn
  a profession") does not exist in the world database, and its `RequiredNpcOrGo1` is **80115**,
  an entry that appears in no client cache and in none of the ten captured game modes. Restoring
  that quest means deciding what 80115 was; the book itself does not depend on it.
* **The rest of the spawn list**, as above.
* **Who sold the book itself.** The Book of Artisans is a companion item: 134987 and 750750 both
  teach spell 750750, which is `SPELL_EFFECT_SUMMON` for creature 57500 (`Spell.dbc`, effect 28,
  MiscValue 57500), so using the item puts a portable book in the world. Both item rows exist.
  Which vendor sold them on the live realm is not recorded next to the books - that is the
  *item's* vendor, a different question from the shop behind the page - and Tiraxis sells the
  Book of Ascension (98457) for 350 Bazaar Tokens, which is a different product.
* **Two rows whose spell this realm's `Spell.dbc` does not have** (31460, 55898) went with the
  recipes. They are not profession rows - the loader dropped them with *"references non-existing
  spell ... ignoring"* anyway - so nothing could ever have been bought from them.

## How to confirm it by hand

1. Start the worldserver; look for one line per book:

   ```
   Book of Artisans (entry 57500) ready: display 48503 x1, npcflag 0xB1, trainer 2 with 93 spells, 29 items on the shelves.
   Beginner's Book of Artisans (entry 57524) ready: display 48503 x1, npcflag 0xB1, trainer 2 with 17 spells, 29 items on the shelves.
   ```

   `0xB1` is 177, and the two counts are the point of that line. An `ERROR` line instead names
   the half that is wrong: a missing model or trainer, a page with no options in it, an empty
   shop, or one of the three flags gone.

2. Go to Ratchet (`/go xyz -887.072 -3778.650 11.735 1`) - a purple flying book outside the
   inn. Right-click it and the page opens with the original's two options: "I require
   training!" and "I would like to browse your goods.". Training gives one row per trade the
   character can train - no rank or recipe above what their own skill has reached, and no recipe
   of a trade they do not know - and browsing gives Edna Mullby's shelves, at her prices. Learn a
   profession, raise its skill, reopen the page, and the next rank and its recipes are there.
3. `.additem 134987` and use the item: a portable Book of Artisans appears at your side -
   right-click it for the same page and the same shelves. This is the only way to reach 57500;
   it is not spawned anywhere, and using the item again dismisses it.
4. `.additem 750750` is the same companion under its second item entry, for a second copy.

One client-side trap: the model a companion is previewed with comes from the client's own
`Cache/WDB/enUS/AzerothCore/creaturecache.wdb`, not from the unit on screen. A cache written
before this restore still holds 57500 with display 15901 (the deer) and shows it in the
Collections tab, while the summoned unit renders the book, because that display travels in the
unit's own update. Renaming that file away (or the whole `Cache/WDB` folder) makes the tab agree
with the world.
