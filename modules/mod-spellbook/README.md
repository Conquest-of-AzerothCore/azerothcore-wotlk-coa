# mod-spellbook

Restores the Books of Ascension as class trainers: right-clicking a book opens the client's own
trainer window with the viewer's class abilities, ranked and gated by level, and **Train** learns
the selected rank for money.

## The problem

The realm's books summoned a companion creature whose script was `npc_ascension_training_book` - a
gossip menu that re-granted whatever CoA's automatic progression handed out. The
original books were a class trainer: the client draws that window only for a unit it reads as a
trainer (`UNIT_NPC_FLAG_TRAINER`, 0x10), and the ranked class abilities the books sold were never
restored to this realm's trainer data at all.

## What the module does

- **The window.** For any creature template that carries the `npc_spellbook_trainer` script
  (`spellbook.cpp`), the module answers the trainer protocol with rows built from the viewer's own
  class - the realm's class spell data, the client's rank ladders and the recovered tables below.
  The list is the server's own trainer list, so a book opened by another player still shows the
  viewer's class, and `Train` (`CMSG_TRAINER_BUY_SPELL`) learns the rank and charges its price.
- **Buying a ladder in a row.** Every row carries the rank directly beneath it as its requirement, which is
  what the original window published — the captured offer list reads "Witchblight (Rank 2)" on the rank-3
  row. A rank the character holds stays in the list as a *used* row, the way a stock trainer greys the row it
  just sold, so a purchase republishes the same rows in the same order: the rank just bought turns used and
  the rank above it turns trainable, both in place. Nothing renumbers, so the client's own restore of its
  selection and scroll position lands on the row the player was on and the list does not move under them. A
  rank whose prerequisite is missing, or whose level is above the character, arrives unavailable — and is
  refused by the server as well, so nothing is bought early. A row the character already has a rank above
  is a used row too: such a rank is not an upgrade, and the core only moves it between specs without
  announcing it, while announcing the rank it pulls into the active spec instead — which used to show a
  chat line for a rank the player had not bought. The rank above a held one is still sold normally.
- **The alert.** Before a spell is learned, the module sends the client the row of its own
  `SpellCustomAttr` table for that spell with the notable bit set (`SMSG_PATCH_SPELL_CUSTOM_ATTR`).
  That bit is what makes the client show *New Spell Learned* and play its sound: a rank up of an
  ability whose row lacks it - or a spell the table has no row for - is otherwise silent, which is
  the way a purchase used to succeed with no popup at all.
  The announcement itself is never sent from here. A grant that supersedes nothing is announced by
  the core's own `SMSG_LEARNED_SPELL`, and a rank up is answered with `SMSG_SUPERCEDED_SPELL`, which
  the client announces on its own. Sending a learned-spell packet on top of that cue announced every
  rank up twice in chat.
- **Automatic delivery off.** The books are how a character earns abilities, so this change ships
  `CoA.AutoProgression = 0` (config file and code default) in the CoA server component:
  the class spells and rank upgrades CoA handed out on level up are no longer granted
  automatically. A talent tree's free nodes (the specialization identity and its free first row) are
  still granted: the books never sell them, and without them the tree stays locked (#4436). It only ever subtracts - the reconcile pass, talent replacements,
  taught abilities and the runemaster passes are untouched, and the gossip option that restores a
  character's abilities on request still grants them.

## The data

The rows are extracted from the sources below, not hand-written: where a value could not be
recovered it is simply absent and the module does not offer it, rather than being invented. A
talent node's first rank is deliberately not for sale - the tree grants it, the book sells the
ranks above it.

| table | built from |
|---|---|
| `SpellbookOfferData.h` | the services the captured original trainer window sold (`Some DATA/CoA_SkillDump.lua`), all 21 classes, and the rank below each |
| `SpellbookRankData.h` | the client's own rank ladders - coa-datamine's ability identity layer (live talent nodes, the CAD table, `NPCTrainer`, `SpellRank`) |
| `SpellbookTrainerData.h` | the realm's `NPCTrainer.dbc`, kept only as the continuation of an ability the class really sells |
| `SpellbookTreeSpellData.h` | the client's talent trees (`CoATalentNodeData.lua`), cross-checked against `CharacterAdvancement.dbc` |
| `SpellbookNotifyData.h` | the client's `SpellCustomAttr.dbc` (patch-S.MPQ) and the notable bit its learn handler tests |
| `SpellbookCostData.h` | this realm's own trainer prices (`trainer_spell`), level driven and quadratic, utility rows at half |

## Database

Two world updates, applied by the worldserver's own updater at startup:

| file | what it restores |
|---|---|
| `data/sql/updates/pending_db_world/rev_20260918_20_books_of_ascension.sql` | the two companion books that summoned nothing (75118 Beginner's, 499992), the `creature_model_info` row the Book of Ascension's display needs before it can spawn, the Ethereal Bazaar vendor Tiraxis (900007) with the recovered Book of Ascension price, his spawn, and the gossip text |
| `data/sql/updates/pending_db_world/rev_20260918_21_spellbook_trainer.sql` | `ScriptName = 'npc_spellbook_trainer'` and `npcflag = 48` (trainer \| class trainer) on every class-training book template |

The trainer flag is load-bearing: without it the client treats a book as an ordinary gossip NPC and
drops the trainer list the module sends it - no window, no error, and nothing in the server log.
The model row matters for the same reason in reverse: without it the core refuses to spawn the
book's creature ("has no model ... can't load"), so the item summons nothing.

## Configuration

`conf/spellbook.conf.dist` installs to `configs/modules/spellbook.conf`:

| key | default | what it does |
|---|---|---|
| `Spellbook.Enable` | 1 | serve the books at all |
| `Spellbook.Notify.Enable` | 1 | mark purchases so the client announces them |
| `Spellbook.Notify.OnClientReady` | 0 | also mark every spell the window offers, once the client reports its handlers are up |
| `Spellbook.Cost.Enable` | 1 | charge the prices the window shows |
| `Spellbook.Cost.Multiplier` | 1.0 | scale every price, for retuning without a rebuild |

## Verifying it

In game: obtain a book (`.additem 98457`) and summon it - right-clicking the book opens the trainer
window with your own class, and Train learns the rank and pays for it.

The gameplay test driver in the CoA server component exposes the whole path as metrics
(`spellbook_rows`, `spellbook_offers_spell`, `spellbook_buy_succeeded`, `spellbook_learned_alerts`,
`spellbook_unannounced_buys`, ...) through its `trainer_buy` action, and one scenario replays the
three purchases of a live report (two talent-tree ranks the book refuses to sell, one class spell it sells
and announces), and a second one buys a whole rank ladder in one open window (`books-rank-refresh.json`):

```
python apps/coa-gameplay-test/run.py validate apps/coa-gameplay-test/scenarios/books-live-repro.json
python apps/coa-gameplay-test/run.py run apps/coa-gameplay-test/scenarios/books-live-repro.json
python apps/coa-gameplay-test/run.py run apps/coa-gameplay-test/scenarios/books-rank-refresh.json
```
