# mod-treasure-keeper

Restores CoA's two bank companions: the **Treasure Keeper** and the **Celestial Treasure Keeper**,
non-combat pets whose right click opens the character's **own (native) bank**.

## The companions (realm data, not a reconstruction)

| | |
| --- | --- |
| items | **98073 Celestial Treasure Keeper** (Season 9 bundle exclusive) and **99491 Treasure Keeper** — quoted 6, Misc/Pet, flags 0x8000000, no level requirement, on-use **55884** (companion learning) plus taught summon spell |
| summon spells | **93417** → creature **80918**, **985356** → creature **10111377**: both `EFFECT_SUMMON` (28), `EffectMiscValueB` **41** (`SummonProperties` 41 — a guardian, the same shape as the Book of Artisans companion), DurationIndex 21 (until dismissed) |
| their own text | *"Right Click to summon and dismiss your companion, that acts as a portable bank while in safe zones. Cannot be summoned in High-Risk Open World."* |
| regression | `apps/coa-gameplay-test/scenarios/treasure-keeper.json` — the ruleset rule end to end: served in PvE and with no ruleset aura, summoned-and-refused in High-Risk and War Mode where an existing companion answers the click with the reason, and served again after a switch back to PvE |
| creatures | **80918 Celestial Treasure Keeper** and **10111377 Treasure Keeper**, faction 35, summon-only (no `creature` rows anywhere) |
| displays | 47857 `Creature\CelestialHuman\CelestialHuman.m2`, 48611 `Creature\wyrmtongue\wyrmtongue.mdx` — both also in CoA's `AscensionCollectionModelData.h` and in the client's `Appearances.dbc` (rows 54544, 54558), which is the Pets-tab pair |
| where they came from | store/bundle grants only: no vendor, loot table or quest rewards them anywhere in this database |

## Why they did nothing

The bank is the core's own, so all a companion needs is to be a banker:

```
UNIT_NPC_FLAG_BANKER (0x20000)  ->  client click  ->  CMSG_BANKER_ACTIVATE (0x01B7, stock)
    ->  WorldSession::HandleBankerActivateOpcode  ->  Player::GetNPCIfCanInteractWith(guid, UNIT_NPC_FLAG_BANKER)
    ->  SendShowBank  ->  the native bank frame
```

Both rows carried **`npcflag` 0**, so the right click produced no packet at all. `unit_flags` was 0
as well; 768 (IMMUNE_TO_PC | IMMUNE_TO_NPC) is this realm's convention for the interactable
companions and props — the Book of Artisans and the restored Destiny Weavers carry it — so the pet
cannot be killed or spell-targeted out from under the window.

The flag has to be the banker bit **alone**: a unit that also carries the gossip flag is read by the
client as a gossip NPC and never sends the banker click — the same silent trap the Book of Artisans
hit with its trainer flag.

## Why the Celestial one was a giant

A creature renders at `CreatureDisplayInfo.dbc`'s scale multiplied by
`creature_template_model`.`DisplayScale`:

| creature | display | client scale | server scale | rendered |
| --- | --- | --- | --- | --- |
| 80918 Celestial (before) | 47857 | **3.5** | 1 | **3.5×** |
| 10111377 Treasure Keeper | 48611 | 0.5 | 1 | 0.5× (correct) |

So the plain keeper was already right and the Celestial one three and a half times its intended
size. The SQL counters it to the plain sibling's 0.5×: `3.5 × 0.1429`. This is the one value no
capture can confirm — the live server's scale never reaches a client — so it is the number to change
if the pet should sit larger; `0.2857` would put the model at its natural (human) size instead.
Reported by the realm's own bug stream as *"Celestial Treasure Keeper Massive and Non-Interactable"*
and *"Treasure Keeper not working … Right clicking the pet should give access to the bank"*.

## The ruleset restriction — three separate states

*"Cannot be summoned in High-Risk Open World"* is a ruleset, not a zone, and the rulesets live in the
character's auras (`src/server/coa/AscensionRulesets.cpp`): **High-Risk** is **1004019**,
**War Mode** is **1004119** alone, and **PvE is that same War Mode aura plus the marker 9931032** —
which is how the client's own `C_Player:GetRuleset()` tells PvE from War Mode, and why a PvE
character shows a buff the client titles "War Mode".

So the states stay separate here as they are on the client: **War Mode and High-Risk refuse the
companion, PvE keeps it**, and a character with no ruleset aura has it too. PvE is the one allowed
state the client renders with a "War Mode" buff, which is a client data matter and not something the
summon path answers; an allowed summon therefore says nothing in chat.

The ruleset every attempt was judged under is written to the log (`Summon 93417 by X: PvE Mode, i.e.
High-Risk false / War Mode aura true / PvE marker true; ...`), because the client's buff cannot tell
PvE from War Mode and the log is where that distinction is legible.

`TreasureKeeper.SeparatePveFromWarMode = 0` reads the shared aura alone instead, which refuses PvE
as well; it exists for a realm that wants "no War Mode buff, no companion" and is not the default.

Mercenary Mode needs no state of its own here: the realm only applies it from a PvP ruleset
(`AscensionMercenary.cpp`, whose own predicate is High-Risk or War Mode without the PvE marker), so a
mercenary is refused with the ruleset that carries it and the companions need no fourth state.

## Cities are exempt (`TreasureKeeper.AllowInCities`)

The item refuses the companion in *"High-Risk Open World"* — and a city is not open world: this
realm's own PvP rulesets cannot touch a character inside one. So inside a city the companion is
**summonable and usable whatever the ruleset says**, including in War Mode and High-Risk.

A city is read from the client's own area flags — `AREA_FLAG_CAPITAL`, the flag the core's own rest
and PvP logic reads (`PlayerUpdates.cpp`: *"Is in a capital city"*) — and it is checked on both the
character's area and its zone, so the city and all of its subzones count: Stormwind (1519),
Orgrimmar (1637), the Undercity (1497), Thunder Bluff (1638), Darnassus (1657), the Exodar (3557),
Silvermoon (3487), Shattrath (3703) and Dalaran (4395). `TreasureKeeper.AllowInCities = 0` enforces
the rulesets everywhere instead.

The refusal speaks with the item's own wording instead of the client's generic cast error.

A companion that is **already out** keeps its banker flag in every ruleset, so it stays
right-clickable — and the click is *answered* instead of being swallowed, with
*"Your Treasure Keeper cannot be used in High-Risk Open World."* / *"…while War Mode is active."*
when the ruleset forbids it. A flag taken away would be silent in the worst way, because a unit
without the banker flag produces no packet at all and the client simply offers no bank.

**Anyone can use any keeper that is out.** The bank the core opens is the *clicking* character's own
(`SendShowBank` answers the clicking session), so a companion another player has out is theirs to use
— the same rules apply to it, but they are read from the **clicker**: the clicker's ruleset and the
clicker's city decide whether the window opens, and the clicker is the one told why when it does not.
The owner is never consulted, which is also why the module answers the click before the core does: a
packet naming a companion across the map is left to the core, so nobody is ever told about a click
they did not make.

Every one of those lines is sent twice from one string: to the chat log, and to the **middle of the
screen** on `SMSG_NOTIFICATION` — the notification opcode this realm's own autobroadcasts and the
weavers' messages use — so the reason is read where the player is looking, not only where they may
not be reading.

That answer is the module's only core hook: `PlayerScript::OnPlayerBankerActivate`
(`PLAYERHOOK_ON_BANKER_ACTIVATE`, `src/server/game/Scripting/ScriptDefines/PlayerScript.h`), called
from `WorldSession::HandleBankerActivateOpcode` before it sends `SMSG_SHOW_BANK`. Returning false
withholds the native window and nothing else; the module never opens a bank of its own.


## What this module adds

* `data/sql/db-world/` — the banker flag (`131072`), `unit_flags` 768, the Celestial `DisplayScale`
  and the `spell_script_names` bindings for 93417 and 985356. Applied by the core's own module
  updater, so module and data stay together.
* `spell_treasure_keeper_summon` — a `SpellScript` on both summon spells: refused while the
  character is in High-Risk or in War Mode, allowed in PvE (the marker's own state) and from a
  character that carries no ruleset aura at all.
* `treasure_keeper_summon_guard` — an `AllCreatureScript` on the same creatures, so a companion that
  came up by any other path (macro, addon, a path this module does not bind) is dismissed and logged
  rather than quietly serving.
* `treasure_keeper_bank_gate` — a `PlayerScript` on the core's new banker hook: it answers the
  click that must not open the bank (a refused ruleset outside a city) and lets every other banker
  click through untouched — including a companion that another player has out, which opens the
  clicker's own bank.
* `treasure_keeper_readiness` — a startup report, because every way this companion can be wrong is
  silent: a missing banker flag, a display the client's cache disagrees with, a missing
  `creature_model_info` row, or a server scale that leaves a 3.5× display uncorrected. It logs both
  companions' effective rendered size and flags.
* a refusal that is turned on logs the spell, the character and which switch refused it; a refused
  bank click logs the companion and the ruleset the same way.

Deliberately not done: a second bank window. The core's handler is the single implementation of
"open the native bank" — the CoA personal/realm banks are a different feature (summoned vault
objects, the CoA server component's `AscensionPersonalBank`) and are untouched by this module.
