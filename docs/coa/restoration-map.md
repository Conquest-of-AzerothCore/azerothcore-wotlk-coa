# Restoration map — where every piece of Open World Scaling and the Destiny Weavers lives

Server, client and database, for both restorations, with the exact file, entry or table. The realm-wide
lift that already exists in the CoA server component is untouched: this is the map of what the
per-character system adds, and of what a port has to carry.

---

## Part 1 — Open World Scaling

### Server, in CoA and modules

| file | what it holds |
|---|---|
| `modules/mod-destiny-weaver/src/destiny_weaver_scaling.cpp` | the whole per-character scaling engine: `ViewFor()` (one character's version of one creature), `ViewableCreature()` / `ViewableBy()` (who may be given a view at all), `StatsAt()` / `HitFrom()` (the `creature_classlevelstats` row), the values patch (`ShouldTrackValuesUpdatePosByIndex`, `OnPatchValuesUpdate`), the combat hooks (`DealDamage`, `ModifyMeleeDamage`, `ModifySpellDamageTaken`, `ModifyPeriodicDamageAurasTick`), the armor and level resolvers (`ViewArmorFor`, `ViewLevelForCore`), the client-refresh registry and the group-notification state (`g_toldState`, `g_lastSpoken`) |
| `modules/mod-destiny-weaver/src/destiny_weaver.cpp` | the switch itself: the Weaver menu, `LevelScalingEnabled` (the group override), `PersonalLevelScalingChoice`, `SetLevelScaling`, the two notifications (`NotifyGroupScaling`, `NotifyPersonalScaling`, `SendCentered`), the group script that refreshes clients on join / leave / disband / leadership change / leader login and logout |
| `modules/mod-destiny-weaver/src/destiny_weaver.h` | `SETTING_SOURCE` (`core.destiny_weaver`), `SETTING_LEVEL_SCALING` (0), `SETTING_EXPERIENCE_BONUS_CONTROL` (1), the opcode id, the public surface |
| `modules/mod-destiny-weaver/src/destiny_weaver_xp.cpp` | Experience Bonus Control — the bonus experience sources (potions, auras, recruit-a-friend) stripped for a character who asked for the base rate |
| `modules/mod-destiny-weaver/conf/destiny_weaver.conf.dist` | the keys below, with their defaults |
| `src/server/coa/AscensionCompat.cpp` | includes `LocalLevelScaling.h`; hosts the realm-wide fallback lift that must stay **off** while this module owns scaling |
| `modules/mod-destiny-weaver/src/destiny_weaver.h` | `CMSG_SET_LEVEL_SCALING = 0x0667`, claimed from CoA's client-opcode dispatch (`AscensionCompatOpcodes::Claim`), so a client can toggle scaling without a menu |
| `src/server/coa/AscensionCompatOpcodes.h` | the client-opcode dispatch and the atlas ids it agrees with |
| `docs/coa/level-scaling.md` | the implementation reference (formulas, group rules, notifications, the hook-dispatch trap, the multi-player and notification audits) |

### Server, in the core (patches to stock AzerothCore files)

| file | what was changed |
|---|---|
| `src/server/game/Miscellaneous/LocalLevelScaling.h` | the shared rules header: `CreatureOffset`, `ScaleCreatureLevelForViewer`, the quest curve (`CurveLevel`, `OnCurve`, `EffectiveQuestLevel`), `ScalingBlocksFor`, and the resolver slots an owner installs (`QuestScalingOwner`, `QuestCurveOwner`, `ChallengeBlocksOwner`, `RulesetBlocksOwner`, `ScalingChangedOwner`, `CreatureViewArmorOwner`, `CreatureViewLevelOwner`) with their accessors |
| `src/server/game/Entities/Unit/Unit.cpp` | `CalcArmorReducedDamage` asks the viewer's armor resolver; `getLevelForTarget` returns the view level for a creature, which is the single lever every level-derived roll hangs off |
| `src/server/game/Entities/Player/Player.cpp` / `.h` | `Player::RefreshQuestLogQueries()`; `isHonorOrXPTarget` and `RewardReputation` read the view level |
| `src/server/game/Entities/Player/PlayerQuest.cpp` | `Player::GetQuestLevel` asks the per-character resolver |
| `src/server/game/Entities/Player/KillRewarder.cpp` | the gray check and the kill experience are per member, on that member's view level |
| `src/server/game/Miscellaneous/Formulas.cpp` | `Acore::XP::BaseGain` is fed `getLevelForTarget(player)`, so a scaled kill pays |
| `src/server/game/Quests/QuestDef.cpp` / `.h` | quest experience and quest money priced at the level the quest's curve gives, never lowered |
| `src/server/game/Entities/Creature/GossipDef.cpp` | the quest menu's money line and its display follow the asking character's choice |
| `src/server/game/Handlers/LFGHandler.cpp` | the LFG quest-reward preview does the same |

### Server, configuration

| key | file | default | what it does |
|---|---|---|---|
| `DestinyWeaver.Enable` | `destiny_weaver.conf` | 1 | master switch |
| `DestinyWeaver.LevelScaling` | | 1 | the feature |
| `DestinyWeaver.LevelScaling.Default` | | 1 | what a character who never chose gets |
| `DestinyWeaver.Scaling.Offset` | | 4 | how far below the character an open-world view sits |
| `DestinyWeaver.Scaling.WorldMaps` | | "0 1" | the open-world maps whose creatures scale |
| `DestinyWeaver.Scaling.DungeonIds` | | 19 classic finder entries | the dungeons that scale inside their LFGDungeons.dbc band |
| `DestinyWeaver.ExperienceBonusControl` | | 1 | exposes the second Weaver option |
| `DestinyWeaver.DisplayStream.Enable` | | 1 | streams the Weavers' display rows (Part 2) |

Each key lives in its component's `*.conf.dist` (`src/server/coa/conf/coa.conf.dist` and
`modules/mod-destiny-weaver/conf/destiny_weaver.conf.dist`).

### Client

**No client patch, and none needed.** Everything the client does for this feature is stock
Ascension-client code that the module drives over the wire:

* `CMSG_SET_LEVEL_SCALING` (0x0667) — the toggle the client can send; accepted by the CoA server component's
  protocol consumer and by `destiny_weaver_server_script` when that consumer is off.
* `UnitIsLevelScaling(unit)` — the client's own query, used by `FrameXML/TextStatusBar.lua` to draw a
  scaled unit's bar as a percentage instead of an absolute number.
* The character-create choice: `GlueXML/CharacterCreateLevelScalingChoice.lua` plus
  `CharacterCreate.lua` / `NewCharacterSetupUtil` write `enableLevelScaling` into the character data,
  with the strings `ENABLE_LEVEL_SCALING`, `DISABLE_LEVEL_SCALING`, their `_TOOLTIP`s and
  `LEVEL_SCALING_TEXT` supplied by the client. This realm reads the same intent through the Weaver
  menu instead, so a fresh character's choice is made in game.
* The create-screen art this feature never needs to re-add: `ExperienceIconLevelScaling`,
  `ExperienceArtLevelScaling`, `ExperienceIconNoLevelScaling`, `ExperienceArtNoLevelScaling` (client
  atlases/icons).

### Database

* Creature scaling needs no table, no DBC row and no SQL: its rules are computed. Quest scaling reads
  `QuestTemplateScaling.dbc` from the server's `dbc` folder (`src/server/coa/AscensionQuestScaling.cpp`).
* The per-character choice is stored through the core's settings system, which persists to
  **`acore_characters.character_settings`** as one row per character: `source = 'core.destiny_weaver'`,
  `data` holding the serialised values (`0` = the scaling choice, `1` = Experience Bonus Control).
  Statements: `CHAR_SEL_CHAR_SETTINGS` / `CHAR_REP_CHAR_SETTINGS` in
  `src/server/database/Database/Implementation/CharacterDatabase.cpp`.
* Quest rewards are read from the stock `quest_template` rows; scaling changes the level they are
  priced at, never the rows. Challenge rules come from `ChallengeRuleTypes.dbc` through
  `mod-coa-challenges`; the War Mode / High-Risk block is `CoA.Ruleset.DisableLevelScaling`.

---

## Part 2 — The Destiny Weavers

Two of the sixteen are placed, with locked positions — deliberately, and only these two, because they
are the only ones with observed evidence:

| npc | entry | guid | map | position | orientation | display |
|---|---|---|---|---|---|---|
| **Tav'ral** (Orgrimmar) | 449350 | 9000012 | 1 (Kalimdor) | `1621.807, -4385.907, 12.541` | `1.1034` | 1478 (TrollMale) |
| **Galrin Olemar** (Stormwind) | 449357 | 9000020 | 0 (Eastern Kingdoms) | `-8818.58, 671.774, 95.425` | `5.2` | 49 (HumanMale) |

### Server, in CoA and modules

| file | what it holds |
|---|---|
| `modules/mod-destiny-weaver/src/destiny_weaver.cpp` | `npc_destiny_weaver`: the greeting, the two option rows with their inline texture escapes and their `ENABLED`/`DISABLED` state word, the toggle handlers, and the group script |
| `modules/mod-destiny-weaver/src/destiny_weaver_display.cpp` | the appearance, streamed: `SMSG_PATCH_CREATURE_DISPLAY_INFO` (0x0976) and `SMSG_PATCH_CREATURE_DISPLAY_INFO_EXTRA` (0x0975) push the display row and the bake row per login, so the realm's DBC tables stay the source of truth and a model fix is never a client download |
| `modules/mod-destiny-weaver/src/destiny_weaver_display_data.h` | the generated display/bake rows for the ids the Weavers stand on (generated from `creaturedisplayinfo_dbc` / `creaturedisplayinfoextra_dbc`) |
| `modules/mod-destiny-weaver/src/destiny_weaver_loader.cpp` | script registration |
| `src/server/coa/AscensionCreaturePreset.cpp` | `creature_display_preset` — turns a preset row (customisation + apparel items) into the `CreatureDisplayInfoExtra` bake the client is sent, which is how the troll's gear is restored without a client patch |
| `docs/coa/npc-restoration.md` | the workflow: how a captured appearance is turned into preset + model + stream, for any NPC |

### Server, the SQL that carries the data

All under `data/sql/updates/pending_db_world/`, applied by the world
database updater on startup:

| file | tables it writes |
|---|---|
| `rev_20260919_01_destiny_weaver.sql` | `creature_template`, `creature_template_model`, `creature_model_info`, `creature`, `npc_text` — the sixteen creatures |
| `rev_20260919_03_destiny_weaver_displays.sql` | `creature_model_info`, `creature_template_model` — the display rows |
| `rev_20260919_04_destiny_weaver_presets.sql` | `creature_display_preset`, `creature_template`, `creature_template_model`, `creature_model_info`, `creature` |
| `rev_20260920_00_destiny_weaver_captured_look.sql` | `creature_display_preset` — the captured look |
| `rev_20260920_01_destiny_weaver_base_models.sql` | `creature_template_model` — base models |
| `rev_20260920_02_destiny_weaver_human_pair.sql` | `creature_display_preset` — the human pair |
| `rev_20260920_03_destiny_weaver_placements.sql` | `creature` — **the spawn rows, including 9000012's position** (`DELETE` of the thirteen invented spawns; the two observed ones stay) |
| `rev_20260920_04_destiny_weaver_preset_slots.sql` | `creature_display_preset`, `creature_template` |
| `rev_20260920_05_destiny_weaver_horde_captured_look.sql` | `creature_display_preset` — Tav'ral's captured gear |
| `rev_20260920_06_destiny_weaver_gossip_text.sql` | `npc_text` — the cleaned greeting |

> **Moving a Weaver:** the position lives in `creature` **and** in
> `rev_20260920_03_destiny_weaver_placements.sql` (`UPDATE creature SET position_x = 1630.5, … WHERE guid
> = 9000012`). A `.npc move` in game writes the database row and survives a restart, because the updater
> skips a file whose SHA1 already matches the `updates` table — but **editing that SQL file at all
> changes its hash, so the next startup re-applies it and snaps the NPC back**. When a move is final,
> write the new coordinates into the file (that is the change which makes it apply *your* numbers).

### Database, what the data actually is

| table | rows for this |
|---|---|
| `creature_template` | entries 449340–449357 (`Tav'vin`, `Magistrix Benjamin`, `Thrain Galewin`, `Veylae`, `Saltheris Dawnborn`, `Elundra Moonsong`, `Waerun Cliffwalker`, `Galric Olim`, `Tav'ral`, `Magistrix Belanor`, `Thrainnor Galestrom`, `Veylin`, `Salthoril Dawnspire`, `Elundrel Moonsinger`, `Waeric Cliffstrider`, `Galrin Olemar`), all with subname `Destiny Weaver` |
| `creature_template_model` | the base model per entry — 449350 → display `1478`, 449357 → display `49` |
| `creature_display_preset` | the captured look: customisation (`race`, `gender`, `skin`, `face`, `hair`, `haircolor`, `facialhair`) and apparel. Both placed Weavers carry the same five apparel ids — `item_body` 126792, `item_chest` 66195, `item_legs` 66200, `item_feet` 142624, `item_wrists` 142619 — with race-appropriate customisation (449350: race 8 / skin 3 / face 2 / hair 7 / haircolor 1 / facialhair 4; 449357: race 1 / skin 4 / face 2 / hair 6 / haircolor 8 / facialhair 4) |
| `creature_model_info` | the bounding radius / combat reach for the display ids |
| `creature` | the two spawns above; the other thirteen were deleted as invented |
| `npc_text` | **30520** — the greeting the menu opens with (`Greetings, Hero. I offer two services to customize your adventure: …`); text 19175 points new characters at the Weaver |
| `creaturedisplayinfo_dbc` / `creaturedisplayinfoextra_dbc` | the display and bake rows the stream sends; the extra table is empty in the database because CoA builds the bake from the preset at runtime |

### Client

**No client patch.** The Weavers are creatures the realm creates, standing on display ids the realm
*streams* to the client at login (0x0976 / 0x0975), with their gear baked from `creature_display_preset`
through `AscensionCreaturePreset.cpp`. What the client must already have is only what the client always
has:

* the two option icons, drawn by inline texture escapes in the option text:
  `Interface/ICONS/nhi_infernaltome` (Experience bonuses!) and `Interface/ICONS/nhi_corruptionpower`
  (Open world scaling!) — both present in the CoA client, confirmed in game against the captured menu;
* the base character models the displays point at (`Character\Troll\Male\TrollMale.mdx`,
  `Character\Human\Male\HumanMale.mdx`) and the item icons/textures the apparel ids resolve to;
* nothing else — no DBC edit, no MPQ patch, no addon.

---

## What a port has to carry, in one line each

1. **The header + core patches** in Part 1 (they are inert without the module: with no resolver
   installed, the core answers exactly as `main` does today).
2. **`mod-destiny-weaver`** — scaling engine, the menu, the notifications, the display stream.
3. **The SQL updates** — creatures, models, presets, spawns, gossip text.
4. **Nothing client-side**, which is the point of streaming the displays and of keeping the
   per-recipient patch: the same build works on a stock CoA client.
