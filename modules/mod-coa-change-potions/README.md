# mod-coa-change-potions

The nine CoA change potions, restored as one module: Race Change (200001), Faction Change (910200,
505005, 505006), Customization (200000, 910201, 2001185), Class Change (97858) — as `ItemScript`s
keyed by `item_template.ScriptName`, so nothing in the core is touched.

## The items

| entry | name | route to the character-select service |
|---|---|---|
| 200000, 910201, 2001185 | Customization Potion (one of them soulbound) | at-login flag `AT_LOGIN_CUSTOMIZE` (0x08) → **Customize** button |
| 200001, 2001181 | Race Change Potion (one soulbound) | `AT_LOGIN_CHANGE_RACE` (0x80) → **Race Change** button |
| 910200 | Faction Change Potion | `AT_LOGIN_CHANGE_FACTION` (0x40) → **Faction Change** button |
| 505005 | Faction Change Potion **to Horde** | as above; Alliance-only item (`FlagsExtra` 2) |
| 505006 | Faction Change Potion **to Alliance** | as above; Horde-only item (`FlagsExtra` 1) |
| 97858 | Class Change Potion | item gossip menu → the class swap below |

A script that answers the use request with `true` keeps the core out of `CastItemUseSpell`, so the
module spends the potion itself (`DestroyItemCount`) and sends the client's acknowledgement
(`SMSG_INVENTORY_CHANGE_FAILURE`, `EQUIP_ERR_NONE`) — the same shape as the core's own
`Spell::ConsumeCharge` path. **Nothing may touch the `Item*` after that call**: `DestroyItem` sets
the object to `ITEM_REMOVED` and its update fields are gone, so the entry and the name are read
first. (The module's first in-game test crashed exactly there — `Object::GetUInt32Value` faulted on
a log line reading `item->GetEntry()` after the spend.)

## Race, faction, appearance: the contract this module completes

The client and the core already implement the whole service — the module only has to raise the flag
the client reads at login:

* `Player::BuildEnumData` (in the realm's tree: `src/server/game/Entities/Player/Player.cpp`)
  writes the character list's service buttons from the at-login flags set in `characters.at_login`.
* The client's `CharacterSelect.xml` shows **Customize** / **Race Change** / **Faction Change** and
  sends `CMSG_CHAR_CUSTOMIZE`, `CMSG_CHAR_RACE_CHANGE`, `CMSG_CHAR_FACTION_CHANGE`.
* `HandleCharCustomize` / `HandleCharFactionOrRaceChange` accept only when the matching flag is set,
  and clear it when the change is applied.

So a potion sets the flag in memory *and* in `characters.at_login` (`CHAR_UPD_ADD_AT_LOGIN_FLAG`),
spends itself, and the next logout lands on a character-select screen wearing the right button.
Every check the core applies to a paid service still applies, because the core is still the one
doing it. A potion is refused, unspent, when another service is already pending (the client can only
show one button at a time) and in combat.

## Class: the one part that is not a restoration

Nothing in the client or the core can change a class: the client's paid services are exactly three,
its opcode table lists no class-change opcode or button, and the core has no class-change path. The live realm's class change ran on Ascension's own core, so its *"which
class"* step never reached anything recoverable.

The module supplies the missing halves from the realm's own data:

* **The choice** — the potion opens an item gossip menu (`ItemScript::OnGossipSelect`, reached
  through `item_template.ScriptName`, the same path as `AscensionBankVoucher.cpp` in the realm's
  `src/server/coa/`) listing **only the Ascension classes**, ids 12…32 — the ten original classes
  are deliberately absent — minus the one the character already is, and only the ones their race
  may be. The availability test is `sObjectMgr->GetPlayerInfo(race, class)`;
  `rev_20260920_00_custom_class_starting_action_bars.sql` states that `playercreateinfo` is the
  authoritative list and calls the 124-row `ascension_custom_class_race` whitelist the outdated one
  (it misses 86 supported pairs). The menu's header is the `npc_text` row `9000092` this module's SQL
  adds, entirely uncoloured: the window draws its own text and embedded colour codes fight it (the
  first row was bright yellow and came out nearly unreadable against the window's own background).
  The id is a third one rather than the first two (`9000090`, `9000091`) because the client caches
  the text it has been answered with for an id, so a rewritten row under a known id keeps showing
  the string it replaced; the SQL deletes both earlier rows so nothing can answer a query with a
  superseded string.

  The entries are the classes character creation offers, in creation's own order and under its own
  names. The client's own creator is the list: `Interface\GlueXML\CharacterCreate.lua` orders its
  pages by `COA_CLASS_ORDER` and labels each with the name `ChrClasses.dbc` gives the id, so the
  menu a player sees here is the menu they saw when they made the character:

  ```
  Necromancer   Pyromancer    Cultist      Starcaller     Sun Cleric   Tinker
  Runemaster    Primalist     Reaper       Venomancer     Chronomancer Bloodmage
  Guardian      Stormbringer  Felsworn     Barbarian      Witch Doctor Witch Hunter
  Knight of Xoroth            Templar      Ranger
  ```

  `COA_CLASS_ORDER` is not id order, and its names are not the ones the ids' keys suggest: the first
  page is Necromancer (23), Runemaster is 32 (`SPIRITMAGE`), Bloodmage is 20 (`SONOFARUGAL`),
  Felsworn is 14 (`DEMONHUNTER`), Knight of Xoroth is 17 (`FLESHWARDEN`), Templar is 19 (`MONK`),
  Venomancer is 29 (`PROPHET`), Primalist is 31 (`WILDWALKER`). `PlayableClasses` in
  `change_potions.cpp` carries each id with its `COA_CLASS_ORDER` key next to those names, so the
  mapping is auditable rather than implicit; the id is what the conversion writes, so nothing about
  it depends on the spelling.
* **The conversion** — the character is not given the new class's things on top of the old ones. It
  is rebuilt to the state it would be in if it had been created at level one as the class being
  chosen and leveled normally to the level it is, minus its own non-class progression (level,
  experience, professions, quest and item rewards, mounts, identity), which is carried over. Five of
  the realm's own definitions are the answer, and they are the ones creation and level-up read:
  * `AscensionLiveBaseline::Spells / ::Proficiencies / ::Skills`
    (`src/server/coa/AscensionLiveBaselineData.h`, generated from the live realm): the level-one
    character — `InitializeLiveBaseline` is the realm's own custom-class initialization inside
    `Player::Create`;
  * `playercreateinfo_spell_custom` (this realm's *"Local live baseline 20260903 class NN"* rows,
    learned through the core's `LearnCustomSpells`) and `playercreateinfo_skills`
    (`LearnDefaultSkills`);
  * `AscensionCompatData::ClassSpells` and `ascension_custom_class_spell` — the class's ability
    ladder, each row with the level the realm teaches it at;
  * `AscensionProgression::Ranks` — the rank upgrades, each with the level the realm teaches it at,
    once the spell they upgrade is held;
  * `AscensionCompatData::CoATalentEntries` with `CoAAutomaticDependencies` — the class tree's
    abilities and their prerequisite gates.

  **None of those three is handed out.** They are read *twice*, and the two readings answer
  different questions: `BuildKit(race, class, level)` says what the class accounts for at the
  character's level, which bounds what may be taken away, while `BuildKit(race, class, 1)` says what
  the class *is* at level one, and only that is granted. A level 50 character that becomes a class
  keeps level 50, receives the abilities, proficiencies and skill lines creation would have built
  for that class, and not one rank, ability or talent that leveling from one would have handed them:
  which of those to learn and which to spend on is the player's decision, made afterwards with the
  realm's own books, trainers and class tree, exactly as it would have been on a character that
  started this class at level one. A conversion never makes a progression choice on the player's
  behalf.

  Two of the realm's tables widen the class *without* being granted: `UnresolvedTrainerSpells` (a
  character of the class may hold these, and a conversion never hands one out — they are the trainer
  offers that sit in no class ladder at all, so no amount of leveling would have produced them) and
  the weapon/armour catalogue `ProficiencyDefinitions`, reconciled on its own with its skill lines.
  Both are in `Allowed` (what the class may hold, and so what is not taken away) and not in
  `Granted` (what a conversion hands out), which is the line the whole design runs along.

  **Removal is bounded the other way, by every class rather than by the class being left.** A spell
  is taken away only when one of the realm's class definitions owns it (the union of
  `AscensionLiveBaseline`, `ClassSpells`, `LegacyGeneratedClassSpells`, `UnresolvedTrainerSpells`,
  `CoATalentEntries`, `Ranks`, `AscensionTaughtAbilityData`, `AscensionTalentReplacementData`,
  `ascension_custom_class_spell` and `playercreateinfo_spell_custom` over ids 12…32). Everything a
  class owns and the new class does not account for goes — with the auras it was running — whatever
  class brought it, so `A → B → C → A` ends where `A → A` would have and nothing accumulates. What
  no class owns is never touched: professions, quest rewards, mounts, item-granted spells, racial
  abilities. The spell catalogue is data, not a heuristic about names, which is why it is safe to
  make it this wide; the skill catalogue is filtered to the realm's own class-owned SkillLine
  categories, so a profession a class happens to list in its baseline (Skinning sits in one) is not
  a class skill.

  Talents follow the spell book, because that is where this realm keeps them
  (`AscensionCoATalentState` derives the whole Character Advancement state from known spells): the
  old class's talent spells leave with its other spells, the vanilla trees are refunded
  (`Player::resetTalents(true)`), glyphs are removed, the chosen specialization is cleared
  (`core.ascension_active_spec`) and every stored build of the old class's specializations is
  emptied (`core.ascension_build.<spec>`), so no dormant old-class talent data survives. Nothing is
  allocated in the new class: the tree is empty and whatever the class and level entitle the
  character to is there for the player to spend, rather than a pre-picked build they did not choose.

  Proficiencies are recalculated rather than added to: the class's proficiency spells and skill
  lines are set from the baseline, and every skill line the class does not have that some class does
  is zeroed. Equipment follows from the core's own `CanUseItem`: an item the new class cannot use is
  moved into the bags (never destroyed — if there is no room it stays equipped and the log says so).
  A pet summoned by the old class is dismissed.

  The class itself is written where the realm reads it: the class byte of `UNIT_FIELD_BYTES_0` for
  the session (with a forced values update so the client agrees), `characters.class` for the
  database (written synchronously), and the character cache is refreshed from that row so name
  queries from other clients already report the new class.
  Base stats are rebuilt (`InitStatsForLevel` / `UpdateAllStats`) and the resource type follows the
  class. `playercreateinfo_action` — the starting action bar, seeded for classes 12…32 by this
  repository's own updates — is copied onto the bar, because a class change cannot keep the old
  class's buttons and would otherwise leave an empty bar. The realm's login repair of the starter kit
  is suppressed for the converted character (`core.ascension_starter`), because a character that
  changes class is not a character being created.

  On the way back in, the realm's own class service (`AscensionClassService::OnPlayerLogin` →
  `SynchronizeProgression`, `src/server/coa/AscensionCompat.cpp`) reconciles the state for the class
  the character is by then, which is what the conversion falls back on for anything it could not
  rebuild itself.

## Drinking a potion ends at the character screen, ten seconds later

Every potion logs the character out to the character selection screen ten seconds after it is used,
`SMSG_LOGOUT_RESPONSE (instant)` followed by `WorldSession::LogoutPlayer(true)`, the core's own
instant logout, which is what sends `SMSG_LOGOUT_COMPLETE` — 0x004E in the client's own opcode
table, where `CMSG_LOGOUT_REQUEST` is 0x004C and `SMSG_LOGOUT_RESPONSE` is 0x004D. The service
potions have nothing left to do in the world once the
flag is set, and the class conversion cannot rebuild a client-side spell book in place, so the
screen where the next step happens is where the player is sent.

The ten seconds are counted by `WorldScript::OnUpdate`, on the world thread, and **not** by
`Player::m_Events`: a map event's callbacks run inside `Player::Update` on a map worker thread, and
logging the player out from there tears it out of the map mid-update (`Player::Update` then carries
on into `UpdatePvPFlag` and reads update fields the logout has freed — the `Object::HasByteFlag`
fault the first version of this module produced). Re-drinking a second potion inside the ten seconds
resets the countdown rather than queueing a second logout, and a player who left in the meantime is
skipped.

One notification says so, in the realm's own notice yellow, and the same sentence goes to the chat
frame with the potion as a real clickable item link:

```
|cffffff00Customization Potion used. You will be logged out to the character screen in
|cffffb34010 seconds|r|cffffff00, where the |cffffb340Customize|r|cffffff00 button is waiting.|r

|cffffff00You are now a |cff8a3303Barbarian|r|cffffff00. You will be logged out to the character
screen in |cffffb34010 seconds|r|cffffff00.|r
```

Colours: `|cffffff00` notice yellow and `|cffe6cc80` item gold for the potion name, and **one**
accent for the words the player acts on — the ten seconds of the countdown and the button the potion
is about are the same colour. They used to be two (`|cffffd100` for the countdown, `|cff00ff9a` for
the button), which made a single sentence carry two "look here" colours beside the yellow; the
accent is now the only saturated colour in the line.

The accent is `ChangePotions.NoticeAccent`, a bare six-digit RGB, default `ffb340` amber. It was
chosen from a rendered set of candidates over the notice's own background (teal `00ff9a`, cyan
`00e0ff`, sky `40c4ff`, ice `7fd8ff` / `a8e6ff`, mint `00ffd0`, green `66ff66`, lime `b6ff4d`, the old
gold `ffd100`, amber `ffb340`); the candidates are listed in the shipped config. It is read when a
notice is sent, so `.reload config` retunes it without a rebuild, and anything that is not six hex
digits falls back to the default instead of breaking the line. The one deliberate exception is the
*to Horde* potion, which names its side in `|cffff2020` red and takes the accent for its countdown
like the others.

A class-change notice names the new class in that class's own colour — the client's
`RAID_CLASS_COLORS` entry for it (Barbarian `|cff8a3303`, Necromancer `|cff45db9c`, Tinker
`|cffd9d9d9`, …), so the line paints the class the way the rest of the game does.
The class name is the one word in that notice the accent never touches; only its ten seconds take it.
The menu itself stays uncoloured: the window's own text and an embedded colour code fight each
other, which is why the header row is plain as well.
The chat copy of the sentence carries the potion as a real item link
(`|cffe6cc80|Hitem:…|h[Customization Potion]|h|r`) instead, because a notification draws colours but
not links.

## What is in here

| | |
|---|---|
| `src/change_potions.cpp` | the nine entries, the flag call, the class menu, the class swap, the logout |
| `src/change_potions_loader.cpp` | `Addmod_coa_change_potionsScripts()` |
| `conf/mod_coa_change_potions.conf.dist` | `ChangePotions.ClassChangeEnable` (default 1) and `ChangePotions.NoticeAccent` (default `"ffb340"`) |
| `data/sql/updates/pending_db_world/rev_20260927_10_coa_change_potion_items.sql` | the nine `item_template` rows, the realm's values field for field, `ScriptName = item_coa_change_potion` |
| `data/sql/updates/pending_db_world/rev_20260927_11_coa_change_potion_menu_text.sql` | the class menu's `npc_text` header (id 9000092, with the two superseded ids deleted) |

Both SQL files live in the repository's pending world updates because that is where CI requires new
SQL (`tools/check_change_boundaries.py`), and both are written to be re-appliable (`REPLACE INTO`,
`DELETE` + `INSERT`).

## Installing

1. Build the worldserver (the module is picked up from `modules/`).
2. Let the updater apply both `rev_20260927_1*.sql` files, or run them by hand.
3. Copy `conf/mod_coa_change_potions.conf.dist` next to `worldserver.conf` as
   `mod_coa_change_potions.conf` if you want to change the class-change toggle. The module is built
   against the realm's own class library in `src/server/coa/` (the `CoA.*` settings live in
   `coa.conf`), and touches nothing outside `modules/mod-coa-change-potions/`.
4. Restart. The startup log shows
   `Loaded 229 class progression rows; a class change is built from 315 live baseline spells, 243
   proficiencies and 449 skills, and is bounded by <n> class-owned spells and <n> class-owned skill
   lines.`

## Verifying

* Tiraxis's *Convenience Items* list shows **Customization Potion**, **Faction Change Potion** and
  **Race Change Potion** at 150 Bazaar Tokens instead of three empty slots, and the starting log no
  longer prints
  `(game_event_)npc_vendor for Vendor (Entry: 900008) have in item list non-existed item (...)` for
  910201 / 910200 / 200001.
* Drink a Race Change / Faction Change / Customization Potion: one notice, the potion leaves the
  bags, and ten seconds later the character is at the character-select screen with **Race Change** /
  **Faction Change** / **Customize** waiting. The core applies the change with all of its own
  checks.
* Drink a Class Change Potion: the menu lists the classes character creation offers, in creation's
  own order and names; picking one spends the potion, converts the class, and ten seconds later the
  character list shows the new class. After logging in: the new class's **base state** — the
  abilities, proficiencies and skill lines creation builds for it, and nothing the class would have
  *bought* by this level, no rank upgrades and no allocated talents — its own starting action bar,
  no spell or talent of the old class, no specialization chosen and no glyphs. The worldserver log
  carries one line per conversion with the counts (`changed class A -> B at level N: X class spells
  and Y skill lines removed, Z spells of the new class granted, W item(s) unequipped, talents and
  specialization reset.`), which is the quickest way to see that a change did work rather than
  appear to. `Z` is the level-one count and does not grow with the character's level.
* The conversion is worth testing as a chain: `A → B → C → A`, or `A → B` twice in a row. With the
  same level and the same race, the second arrival at a class is the same character state as the
  first, and the log line's counts are the same.

### A test run, item by item

Tiraxis sells three of the nine. The other six were webshop mail on the live realm and have no
source in this repository, so they need a GM command:

| entries | how a test character gets them | what to check |
|---|---|---|
| 910201, 910200, 200001 | Tiraxis, 150 Bazaar Tokens | the *Convenience Items* list has all three slots filled |
| 200000, 2001185 | `.additem 200000` / `.additem 2001185` | drink → notice → auto-logout → **Customize** |
| 200001, 2001181 | Tiraxis / `.additem 2001181` | drink → notice → auto-logout → **Race Change** |
| 910200 | Tiraxis | drink → notice → auto-logout → **Faction Change** |
| 505005 | `.additem 505005`, Alliance character | as above; the client refuses a Horde character (`FlagsExtra` 2) |
| 505006 | `.additem 505006`, Horde character | as above; the client refuses an Alliance character (`FlagsExtra` 1) |
| 97858 | `.additem 97858` | drink → class menu → pick → notice → auto-logout → log in and read the spell book |

Drinking a second service potion before logging out must be refused, and the potion must survive the
refusal: the client can only show one of the three buttons at a time. Nothing is spent in combat
either. The class potion is spent when a class is picked, not when the menu opens, so closing the
menu costs nothing.

## Known limits

* The class conversion cannot know about live-realm-only bookkeeping (Ascension's webshop-side class
  records), so it is a realm-local implementation of the same *intent*, built from the realm's own
  class definitions rather than from a copy of the live realm's class-change code.
* A specialization the player had *chosen* cannot be reproduced, because it is a choice and not a
  level: the conversion clears it and leaves the class's talent tree to the player, which is the
  state of a character that leveled the class and spent nothing. That is the closest a server can
  get to "as if they had been this class the whole way" without making the character's choices for
  them.
* This repack runs with `CoA.AutoProgression = 0`, so class abilities and their rank upgrades are not
  handed out at level-up: they are bought from the Books of Ascension (`mod-spellbook`), whose offers
  and ranks are the class's own level-gated rows. A conversion hands out the class's level-one base
  state and stops there, so the ladder above it stays exactly where it was for the player to buy —
  the same position a character that started this class at level one would be in at this level. The
  level-gated rows are still read, but only to decide what the class accounts for, which is what
  keeps a bought rank from being taken away and an old class's bought rank from staying.
* A faction change can still be refused by the core *after* the potion is spent (mail in the
  mailbox, an active auction, arena team captain, a guild without cross-faction guilds); the potion
  is gone by then.
* `505005` / `505006` are seven-day, faction-restricted items: they can only be used by the faction
  they are meant for (Alliance → Horde, Horde → Alliance), which the client enforces from
  `FlagsExtra`.
