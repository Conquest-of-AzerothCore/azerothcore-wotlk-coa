# mod-craftsmans-codex

Restores CoA's **Craftsman's Codex**: that character may learn one more primary profession than
the standard two, permanently, once per codex used.

## The item (realm data, not a reconstruction)

| | |
| --- | --- |
| item | **97871 Craftsman's Codex** - quoted 6, Misc/Other, display 138384, icon `inv_artifact_tome02`, one per stack, no level and no skill requirement, buy price 2,500 g, Bind to account |
| variant | **2200001 Soulbound Craftsman's Codex** - the same row with `Bonding = 1` |
| spell | **93292 Craftsman's Codex**, on use, 5 second cast, effect `SPELL_EFFECT_DUMMY` on the caster, consumed on use (`item_template.spellcharges_1 = -1`) |
| its own text | *"Unlocks a new primary profession slot. You can unlock all primary professions."* |
| where it came from | it was **sold**, never dropped: Guardian of Time (25,000,000 c = 2,500 g) and Tiraxis (500 x Bazaar Token) in the live vendor captures |

The client knows the item in three places and does nothing itself: `Interface/FrameXML/Data/Items.lua`
(`CRAFTSMANS_CODEX = 97871`), the profession book's hint when you try to open a third profession
(*"You will need to use a [Craftsman's Codex] to learn an additional profession"*), and the item
row itself with its icon and text. The hint is decided from the professions you already hold
(`numProfessions >= 2`), so the client never asks the server how many slots you have.

## Why this one is code, not data

The portable gadgets were missing rows: the fix was the database and the core did the rest. Here
nothing is missing - the item, the spell, the icon and the text all exist, the spell is castable,
and its single effect is deliberately a `SPELL_EFFECT_DUMMY`, which does nothing on its own. The
server has to answer it, and on this realm nothing did: the codex cast, spent its 5 second cast
time, vanished and granted nothing.

## What a "primary profession slot" is

Not our invention. The core already keeps the number of profession slots a character has left in
one player field, `PLAYER_CHARACTER_POINTS2` (`Player::GetFreePrimaryProfessionPoints`), and that
one value is the whole gate:

* `Player::InitPrimaryProfessions` sets it to `MaxPrimaryTradeSkill` at login - with the comment
  *"to max set before any spell loaded"* - and loading the spell book spends one slot per primary
  profession the character already knows, so it means **slots still free**;
* `Trainer::CanTeachSpell` refuses a profession's first rank while it is 0: the only thing between
  a character and their third profession;
* `Trainer::SendSpells` marks each profession entry with `PointCost[1] = 1`, which is what the
  client's trainer window greys out when the character cannot afford it.

Unlocking a slot is therefore adding to that number - and that needs no client change, because the
client is told the new count through the field it already reads.

## What this module adds

* `data/sql/db-world/` binds spell **93292** to `spell_craftsmans_codex`, the script below. A
  registered spell script runs only where the database binds the spell to it, which is why the
  item did nothing.
* `data/sql/db-characters/` creates `mod_craftsmans_codex` (`guid`, `slots`, first/last used). The
  unlock has to be remembered somewhere the character owns, because the counter it feeds is
  rebuilt from scratch at every login.
* `spell_craftsmans_codex` (a `SpellScript` on the dummy effect): using a codex adds one unlocked
  slot, hands the new allowance to the core and announces it in the two places a player looks - a
  coloured line in the chat frame (`Craftsman's Codex` in gold, the new `primary profession slot`
  in green) and a short coloured line across the middle of the screen. Neither line counts slots,
  deliberately: the counters are what `.codex status` is for, and quoting them in a toast makes
  the player subtract instead of read. A codex that would be worth nothing is refused before the
  cast instead of being consumed for it.
* `craftsmans_codex_allowance` (a `PlayerScript`), for the three moments the counter can be wrong;
  see below.
* `.codex status|grant|reset` for game masters.

## The three moments the counter can be wrong

* **Logging in.** The counter is reset to `MaxPrimaryTradeSkill` on every login, so the unlocked
  slots are added back in `Player::LoadFromDB`, before the client has been sent the character -
  the count has to be right in that first update, because the client prices trainer entries
  against it. The spell book is not loaded yet at that point and does not need to be: the counter
  has just been set to the maximum, the load spends one slot per profession the character holds,
  so adding the unlocked slots to that maximum is adding them to the finished allowance. A second
  pass in `OnPlayerLogin`, with the spell book in memory, re-derives the allowance from the
  professions actually held and corrects the load if it was ever out of step.
* **Unlearning a profession.** The core refunds the slot it spent (`Player::removeSpell`) but caps
  the refund at `MaxPrimaryTradeSkill` - a ceiling a character with unlocked slots is above, which
  would quietly eat one of them. The refund is re-derived here instead, from the professions the
  character still holds: a primary profession's first rank, present in the spell book, which is
  exactly the set the core counts when it spends a slot.
* **Buying one too many.** `CraftsmansCodex.MaxSlots` (default: every skill line the server files
  under `SKILL_CATEGORY_PROFESSION`, 13 on this realm - the 11 stock professions plus CoA's
  Fletching and Demonic Intuition) is the point at which *"You can unlock all primary
  professions"* is reached. At that ceiling the cast is refused, so the item is not consumed.

## Applying it

1. The SQL is applied by the worldserver's own updater at startup (`Updates.EnableDatabases`
   covering the world and characters databases). On a repack that runs with the updater off,
   apply both files by hand, exactly as they are:
   `data/sql/db-world/2026_09_20_00_craftsmans_codex.sql` and
   `data/sql/db-characters/2026_09_20_00_craftsmans_codex.sql`.
2. Reconfigure CMake before building, so the module is picked up (modules are discovered at
   configure time), then build and deploy the worldserver as usual.

## How to confirm it

1. Boot: `>> mod-craftsmans-codex: Craftsman's Codex complete - spell 93292 bound, item(s) 97871
   grant one primary profession slot each (base 2, up to 13 professions on this realm).`
2. In game: `.additem 97871`, right-click it, wait out the 5 second cast. You get the announcement
   twice - `Craftsman's Codex: a new primary profession slot is unlocked.` in chat, and
   `New profession slot unlocked` across the middle of the screen - the item is consumed, and a
   **third** primary profession can now be learned from its trainer. A second codex opens a fourth,
   and so on. `.codex grant` announces itself the same way to the player it grants to.
3. `.codex status <name>` reports the unlocked slots, the allowance, the professions held and how
   many are still free - for an offline character too. `.codex grant <name> [count]` and
   `.codex reset <name>` hand slots out or take them back without an item.
4. The ledger: `SELECT * FROM acore_characters.mod_craftsmans_codex;`

## Two things worth being straight about

* **The values are the realm's; the plumbing is ours.** Item, spell, text, effect and the
  consumption rule are all realm data, and the gate - the counter and the trainer - is the core's
  own. What CoA's own server did behind the dummy is not recoverable (their server code was never
  captured), so the messages, the table shape, the command and the ceiling default are ours. The
  outcome the item promises - one more profession slot, permanently - is what this reproduces.
* **It is still not obtainable.** No vendor, loot table or quest on this realm grants the item; on
  CoA it came from the shop and the Bazaar. Wiring it to a vendor is a separate change, so for now
  it is `.additem 97871` for testing. The QA variant 2200001 works the same way.

## Files

| | |
| --- | --- |
| `src/craftsmans_codex.cpp` | the spell script, the allowance hooks, the startup check, the command |
| `src/CC_loader.cpp` | `Addmod_craftsmans_codexScripts` |
| `data/sql/db-world/2026_09_20_00_craftsmans_codex.sql` | binds the spell to the script |
| `data/sql/db-characters/2026_09_20_00_craftsmans_codex.sql` | the per-character ledger |
| `conf/craftsmans_codex.conf.dist` | `Enable`, `MaxSlots`, `VerifyOnStartup`, `Command` |
