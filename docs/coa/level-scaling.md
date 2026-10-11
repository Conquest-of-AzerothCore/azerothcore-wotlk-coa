# Level scaling: the formulas

Open-world scaling, as it is implemented here. Both halves follow each character's own choice at the
Destiny Weaver (`mod-destiny-weaver`), which the character-creation screen offers as well:

* **creatures** are scaled **per viewer**. Each character is sent their own version of a creature, at
  their own level minus `DestinyWeaver.Scaling.Offset`, while the creature object keeps its authored
  level. A level 30 and a level 20 character facing the same level 15 creature see it at 26 and 16 at
  the same time, and a character with scaling off sees 15. There is no realm-wide creature lift: with
  `DestinyWeaver.Enable` or `DestinyWeaver.LevelScaling` at 0, every creature keeps its authored level.
* **quests** are per character as well (`CoA.QuestLevelScaling` is the realm switch; the character's
  own choice decides). A quest follows its own row in the client's `QuestTemplateScaling.dbc`, so it
  trails the character inside the bounds its row sets; the level is sent to that one client, so it can
  genuinely differ per character.
* **challenge rules** and the open-world **War Mode / High-Risk** rulesets hold a character to the
  authored world whatever their own choice says (section 1, *What holds a character to the authored
  world*).

## 1. The shared header

`src/server/game/Miscellaneous/LocalLevelScaling.h`

```
ScaleCreatureLevelForViewer(original, viewerLevel, offset = 4):
    floor = max(1, viewerLevel - offset)
    return max(original, floor)                         # up only, no ceiling

ScaleDungeonCreatureLevelForViewer(viewerLevel, band):
    return clamp(viewerLevel, band.Low, band.High)       # both ways, no offset

DungeonBandFromFinder(targetLevelMin, maxLevel):        # one LFGDungeons.dbc entry
    low  = targetLevelMin if 1 <= targetLevelMin <= 60 else 15
    high = maxLevel if low <= maxLevel <= 60 else 59

CurveLevel(curve, playerLevel):                       # one QuestTemplateScaling.dbc row
    point = the point with the highest level <= playerLevel
    level = point ? playerLevel + point.offset : curve.Min
    return clamp(level, max(1, curve.Min), max(curve.Min, curve.Max))

EffectiveQuestLevel(authored, playerLevel, curve):
    stock = authored > 0 ? authored : playerLevel        # -1 = "follow the player"
    return curve ? max(stock, CurveLevel(curve, playerLevel)) : stock
```

`CreatureOffset` comes from `DestinyWeaver.Scaling.Offset` (default 4). An open-world view has no
ceiling: it is told to one client only, so the creature in front of a character comes all the way up
to that character's band. That is the whole point of the feature: content in front of a character is
relevant to that character.

Inside a scaled five-player dungeon every creature stands at the viewer's own level, held inside the
dungeon's band on both sides, because the dungeon finder admits a group well below a dungeon's
authored level. The band is the `TargetLevelMin`-`MaxLevel` of the dungeon's `LFGDungeons.dbc` entries,
merged per map; entries with placeholder levels (100/100 for Wailing Caverns, Gnomeregan and Uldaman)
use 15-59.

#### Where a creature scales

| scope | rule |
|---|---|
| open world | the maps in `DestinyWeaver.Scaling.WorldMaps` (default `0 1`) |
| dungeons | regular difficulty of the dungeon finder entries in `DestinyWeaver.Scaling.DungeonIds` (default the 19 classic entries: 1 4 6 8 10 12 14 16 18 20 22 24 26 28 163 164 165 272 273) |
| never | raids, battlegrounds, arenas, scripted private instances, Heroic/Mythic dungeons |

A creature on a scaled map still keeps its authored level when it is a pet, guardian, totem, trigger,
critter, non-combat pet, world boss, has an owner or charmer, has `unit_class` 0, serves (any
`npcflag`), or carries `NON_ATTACKABLE`, `NOT_SELECTABLE` or `IMMUNE_TO_PC`. The last two are read
from its spawn and template (`ObjectMgr::ChooseCreatureFlags`), not from live flags that scripts
toggle, so a view does not appear and vanish during an event. A friendly creature keeps its level for
that viewer.

Every creature a view can exist for carries `UNIT_DYNAMIC_FLAGS` bit `0x100` on the object, which
puts the field in every create block. `OnPatchValuesUpdate` leaves the bit set for a recipient who is
shown their own version and clears it for everyone else; the client's `UnitIsLevelScaling` reads it.

`QuestScalingEnabled(player)` is the per-character gate for **quests**. The realm switch
`CoA.QuestLevelScaling` must be on for it to be consulted at all; a challenge rule or a ruleset that
blocks quest scaling answers no next, and the resolver then answers for one character. No resolver, or no opinion, means "take the realm default".
`mod-destiny-weaver` installs the resolver and stores the choice in `character_settings` under
`core.destiny_weaver` (index 0 = the choice, 2 = off). `ScalingChoiceEnabled(player)` is the same
choice with no realm switch in front of it, and it is what the per-viewer creature paths ask.

### What holds a character to the authored world

`LocalLevelScaling::ScalingBlocksFor(player)` returns the scaling a character may not have, whatever
their own or their group's choice: bit `0x1` (creatures) and bit `0x2` (quests). The creature view
(`ViewFor` in `mod-destiny-weaver`), the chest item lift and `QuestScalingEnabled` all ask it. Two
owners feed it.

| owner | what it blocks | where |
|---|---|---|
| challenge rules (`ChallengeBlocksOwner`, `mod-coa-challenges`) | `NO_CREATURE_LEVEL_SCALING` → creatures, `NO_QUEST_LEVEL_SCALING` → quests, read from `ChallengeRuleTypes.dbc` for the character's active challenges | any map |
| rulesets (`RulesetBlocksOwner`, `AscensionRulesets.cpp`) | both, while the character carries High-Risk (1004019), or War Mode (1004119) without PvE Mode (9931032) | the open world only (not an instanceable map) |

Ironman - Overwhelming Odds (71) and its twin (285) carry only the creature rule; Hardcore - Inn-Sane
(76, 290) carries both, and also `NO_PLAYER_LEVEL_SCALING`, which has nothing to block here because
this realm has no player level sync. The ruleset block is what the live tooltips of the two auras
say: "Level scaling is disabled while in High-Risk." and "Level scaling is disabled while in War
Mode."; PvE Mode's tooltip has no such line. `CoA.Ruleset.DisableLevelScaling` (default 1) turns the
ruleset block off.

Starting or stopping a challenge, switching ruleset and entering or leaving the open world change the
answer without a relog: each calls `NotifyScalingChanged(player)`, which `mod-destiny-weaver` serves
with `DestinyWeaver::RefreshClient` (creatures and quest log); without the module the quest log is
re-sent through `RefreshQuestLogQueries`.

### A creature's stats, per character

A character with scaling on fights *their* version of a creature, and everybody else fights the
authored one, at the same time, against the same corpse. Two mechanisms carry that:

- **fields** — level, max health, health, max mana, mana are rewritten per recipient in the values
  block (`OnPatchValuesUpdate`, offsets from `ShouldTrackValuesUpdatePosByIndex`). The core builds
  one buffer per `(visible flag, update type)` and patches a copy per player, so a view never leaks
  into another client. Health is carried as the same *share*, so the bar is that version's pool.
- **levels** — `Creature::getLevelForTarget` answers with the view level
  (`LocalLevelScaling::CreatureViewLevelOwner`, installed by the module). This is the lever the rest
  of the fight hangs off, because everything level-derived in a roll is asked for through it:

| term | how it follows the viewer |
|---|---|
| spell hit and resistance tables (`MagicSpellHitResult`) | level difference, both directions |
| weapon and defence skill (`GetMaxSkillValueForLevel`, `GetUnitMeleeSkill` → `GetWeaponSkillValue`, `GetDefenseSkillValue`) | the view level × 5 |
| melee, ranged and physical-ability miss chance | `GetWeaponSkillValue(attType, victim)`, both directions |
| glancing and crushing tables | `getLevelForTarget` on both sides |
| ranged abilities that are not weapon spells | `getLevelForTarget(victim) * 5` |
| block chance adjustment | attacker skill against victim max skill, both with a target |
| daze from behind (`Unit::CalculateMeleeDamage`) | the creature's melee skill is the view level × 5 against that character |
| weapon skill-ups (`Player::UpdateCombatSkills`) | the creature counts at the view level, like defence skill-ups |
| stealth/detection and aggro radius | `Object::isVisibleForOrDetect`, `Creature::GetAggroRange`, `GetAttackDistance` |
| kill experience | `Acore::XP::Gain` (`Formulas.cpp`), and the gray checks in `KillRewarder` |
| armour a blow lands against | `Unit::CalcArmorReducedDamage` asks `LocalLevelScaling::ViewArmorFor` |
| armour-penetration cap, level-based resistance and partial resists | `ShownCombatLevel` in `Unit.cpp`: the view level on whichever side is the creature, its real level for a world boss |
| damage the creature deals | melee: `CreatureView::DamageTakenLow`/`DamageTakenHigh` scale the bottom (`BaseDamage + AttackPower / 14`) and the top (`BaseDamage × 1.5 + AttackPower / 14`) of the `creature_classlevelstats` range separately, so the blow keeps its place inside the view level's range (below); spells and periodic damage: `CreatureView::DamageTakenFactor`, the average-hit ratio of the same two rows |
| damage the character deals to it | `CreatureView::DamageDealtToPool` takes the matching share out of the real pool, so the bar falls by exactly the number their client was shown |
| overkill in damage logs | `LocalLevelScaling::ShownHealthFor`: the health that character is shown, the size their hits are logged in |
| threat | damage threat is added after `DealDamage`, so it already counts in real-pool units; healing, threat spells (`HandleThreatSpells`, `EffectThreat`), Guard Dog, mana drains and flat total-threat modifiers such as Fade go through `LocalLevelScaling::PoolThreatFor`, the same ratio, per creature, so a healer does not pull a scaled creature early |

`DamageTakenFactor` and `DamageDealtToPool` are both ratios of the *same* two rows, which is why the
view is one definition rather than several: level, pool, mana, armour, damage and skills all read the
row at the view level, and the factors are 1 for a character with scaling off.

Two of those terms needed a target the core did not pass. The daze roll asks the creature's
`GetUnitMeleeSkill()` without a victim, and weapon skill-ups read `victim->GetLevel()` for the
attacker's own blows; both now take the view level when the character has one, and stay stock for
every other pair (world bosses included).

`Unit::CalculateDamage` rolls a creature's blow as `urand(uint32(min), uint32(max))`. A Young Wolf's
1.5 - 2.3 range therefore only lands on 1 or 2, and multiplying that whole number by a view factor of
around 20 gave two flat hits whose average sat a fifth below the one the factor was measured against.
`ModifyMeleeDamage` puts the blow back at a uniform spot inside its whole-number bucket and lands it
on the same spot of the view level's range, whose bottom and top are the real ones times
`DamageTakenLow` and `DamageTakenHigh` (`DestinyWeaver::ViewBlow`), then keeps the fraction of the
scaled blow with that probability (`DestinyWeaver::WholeDamage`). Scaling both ends by one average
ratio would keep a low creature's nearly flat range flat: its attack power dominates both ends, while
at the view level the weapon term does. A number the roll cannot have produced, because an aura
already changed it, takes the ratio of its place in the real range.

### Groups: the leader sets the switch, never the level

While a character is grouped, `DestinyWeaver::LevelScalingEnabled` answers with the **leader's**
switch — on, or off, for every member. It answers with nothing else of the leader's, and that is
load-bearing rather than incidental:

- the level a creature is shown at is `ScaleCreatureLevelForViewer(original, viewer->GetLevel(), offset)` —
  the *viewer's* level;
- the level a quest is played at is `EffectiveQuestLevel(questLevel, playerLevel, curve)` — the *viewer's*
  level on the quest's own curve.

So a level-31 leader with scaling on and a level-12 member with it off: the member's scaling turns on
(leader's switch), and the member then meets the world at *level 12's* answer — level 7 versions of
what they can still reach, level 31 content untouched because nothing is ever lowered. The leader
sees level 26 versions of the same creatures, from their own level. Two members of one party, one
creature, two versions, and neither is derived from the leader's level. The same holds while several
of them attack the same creature: the level and pool are patched **per recipient**, the fight inputs
ask `getLevelForTarget` **per opponent**, and nothing about a creature is made universal.

The switch is a group override, never a write: no member's stored choice is touched, so leaving or
being disbanded restores exactly what they had, and leadership handed over is read live on the next
query. What needs help is not the rule but the *wire*:

| event | what changed | who is re-sent |
|---|---|---|
| leader's switch flipped at the Weaver | the group's switch | the actor and every online member |
| member added | the newcomer now follows the leader | the newcomer |
| member removed | they go back to their own choice | that member |
| **leader** removed or disconnected | every member's switch is gone | every remaining member |
| leadership handed over | the new leader's switch | every member |
| group disbanded | everyone back to their own choice | every member |
| leader logs in, or is handed the lead | their switch applies again | every member |

A client caches the level and pool it was told for every creature, and the quest data it was told for
every quest; only a fresh message replaces either. So each of those events calls
`DestinyWeaver::RefreshClient` / `RefreshGroup` / `RefreshScalingClients`, which records the client
in a small registry (`g_viewRefresh`, guarded, holding the guid, a `CreatureUntil` stamp, a
`QuestLogDue` flag and the creatures already sent this episode). The registry is served on the thread
that owns the thing being refreshed — never a packet across threads:

- **creatures**, `destiny_weaver_view_refresh_script` (`AllCreatureScript`): a relaxed atomic read per
  creature update while nothing is pending, and while something is, the first pending viewer within
  `VIEW_REFRESH_RANGE` gets its five view fields marked changed. The creature then broadcasts those
  fields once, exactly as it would after any change, and `OnPatchValuesUpdate` rewrites them per
  recipient on the way out — so every viewer is refreshed to its own version, a viewer whose view did
  not move receives its authored values, and the window (`VIEW_REFRESH_WINDOW_MS`) is what catches
  creatures that had not ticked yet without broadcasting for ever.
- **the quest log**, `destiny_weaver_view_client_script` (`PLAYERHOOK_ON_UPDATE`): on the character's
  own thread, once per episode, `RefreshQuestLogQueries()` — the same call the Weaver's own toggle
  makes, and the reason a member's log follows a leader's switch.

**One consequence worth knowing:** a group is one group, so a leader who logs off leaves their switch
unreadable (`ObjectAccessor::FindConnectedPlayer` finds nobody) and every member falls back to their
own choice — the logout path above refreshes them so the change is never stale, and their choice is
restored when the leader returns. Excluding battleground and arena groups from the override would be
a one-line change if a stranger leading a BG group should not decide anyone's scaling.

### What the character is told

A switch that only the menu reports is a switch nobody notices mid-fight, so each real change is
announced in the middle of the screen (`SMSG_NOTIFICATION`, one packet per line, the same opcode the
realm's autobroadcasts use) and in the chat log, with the state word coloured and the rest plain
yellow. There are two sentences, because there are two different things to say:

- **the group's**, when what moved is the group's switch — `Your group has Level Scaling ENABLED` /
  `DISABLED`. Sent by `NotifyGroupScaling`.
- **the Weaver's own**, when the change is the character's own — `You have enabled open world creature
  scaling!` / `You have disabled open world creature scaling!`, the off line carrying the second
  sentence the live realm showed with it: `Quest items and credits will not be awarded if creatures
  are grey level.` Sent by `NotifyPersonalScaling`.

Which one a change gets is decided by `GroupScalingApplies` — a group sentence is only true while
there is a leader present to have a switch, so a character who left, was disbanded, or lost their
leader to a logout is answered in the Weaver's words instead, handing them their default back.
Leaving a group and being disbanded pass `remindDefault`, which makes the Weaver's line speak
**whether or not the state moved**: they are a reminder of what the character is left holding, not a
report of a change, and a character whose own choice happens to match their group's would otherwise
hear nothing at all. The reminder is the Weaver's line even while a group is still on their screen,
because that is what it is about — and the value it names comes from `PersonalLevelScalingChoice`,
never from the effective state: inside a group hook the effective answer is still the leader's switch
(the character has not finished leaving), so naming it told people the opposite of their own setting.
A leader leaving is *not* a reminder, because those members are handed the lead to one of them and end
up on a leader's switch rather than their own; it stays a change-only report in the group's words.
The
acting character is always answered in the Weaver's words, because they are the one who threw it:
`SetLevelScaling` calls `NotifyScalingSelf`, which records the state they are now being *shown* (the
leader's switch, while the group's is in effect) and then speaks, so the refresh that follows cannot
announce the same change back to them in the group's voice. `g_toldState` is the mechanism — what
each client currently believes, seeded on login, compared on every mark — so one real change is one
message whoever caused it and no event can double-notify. `g_lastSpoken` is the second half of
that guarantee: two hooks genuinely describe one event, because a member leaving a two-person group
fires the removal *and* the disband, and both hand the same member the same default. So a repeat of
the **same** state inside `SPEAK_REPEAT_WINDOW_MS` is the same news and is not spoken again - while a
change that moves still says so whichever way it moves and however quickly.

**The trap that made all of this look like it worked while none of it did.** The core dispatches a
unit hook only to the scripts that registered it — `CALL_ENABLED_HOOKS` walks
`ScriptRegistry<UnitScript>::EnabledHooks[hook]`, which is filled from the script's constructor
list — so an override that is not listed is never called and the fight silently keeps the authored
numbers. Module scripts that override `ModifyMeleeDamage`, `ModifySpellDamageTaken` or
`ModifyPeriodicDamageAurasTick` must name those hooks in their constructor. `DealDamage` is the
exception: it is dispatched to every registered unit script.

Not scaled, deliberately, and matching the reference implementation: the creature's **resistance values**
(template-based and level-independent there too; only the level terms above follow the view) and **loot
tables**, which are one corpse shared by everyone who tagged it. Scaling gear on that corpse takes the level
of whoever loots it or wins the roll, a master looter's pick the receiver's. Scaling gear from loot or a
quest reward scales only for a character whose scaling is on, by the same answer the creature view asks
(their choice, or their leader's in a group, and no challenge or open-world ruleset holding them to the
authored world); everyone else receives the authored item, and their corpse and roll frame preview none.

With `CoA.ItemScaling.Native.LevelKeys` the stored level is the client's own item key for that level
(level + 2 up to 20, + 3 up to 30, + 4 up to 50, + 5 up to 60, the client's table above 60), and a quest
reward takes the level the quest's `QuestTemplateScaling.dbc` row puts it at, or the key of the
character's level for a quest without one. `CoA.ItemScaling.Native.Preview` (needs LevelKeys; both off by
default and read at startup) lets each character see the version they would receive before it is theirs:

| Where | What the server sends |
|---|---|
| Login | `0x578` field 87 = 1 on the character's guid, which switches the client's preview on |
| Corpse | a lootable corpse's level field shows each viewer allowed to loot it their own drop level |
| Roll frame | `0x73F {u32 level}` before each roll; the winner receives the level their frame showed |
| Inspect | `0x716` with 19 levels, one per equipment slot |
| Mail list | each attached item's level (`0x578` field 0) |
| Auction list | the instance level in the auction's unused flags word, the item level for an unscaled one |

An item whose key equals its own item level is the authored item: the server answers the client's
`0x6FF` query for that key with the authored stats instead of a ladder row.

### Many characters, one creature

The question a crowded realm asks is: *can two characters change each other's world, and does anything
grow or race?* Audit result, by mechanism:

| property | how it holds |
|---|---|
| **No shared mutation.** | Nothing here writes a creature's level, health, stats or flags. The only writes are the transient values *mask* of a creature (`ForceValuesUpdateAtIndex`) and the per-recipient copy of the packet. Two characters cannot see each other's version, and a character with scaling off sees the authored creature exactly. |
| **Per-recipient delivery.** | `Map::SendObjectUpdates` builds one buffer per player and `Unit::PatchValuesUpdate` rewrites fields for that target; our five fields (`UNIT_FIELD_LEVEL`, `MAXHEALTH`, `HEALTH`, `MAXPOWER1`, `POWER1`) are registered through `ShouldTrackValuesUpdatePosByIndex`, which is called only for fields already in the update mask — so no bandwidth is added to a block that did not already carry them. |
| **Damage in both directions** | resolves the viewer from the unit that owns the hit (`GetCharmerOrOwnerPlayerOrPlayerItself`), never from "a player nearby". A pet's blows count as its owner's; a creature's blows on a pet follow the owner's view too, deliberately, because pets level with their owner — and pets themselves are never *given* a view. |
| **Lock discipline.** | One mutex (`g_viewRefreshLock`) guards the refresh registry and the three notification maps; nothing sends a packet while holding it, and the send is made on the thread that owns the client. The hot creature pass reads one relaxed `atomic<uint32>` count first and does nothing else while no refresh is pending. |
| **State lifetime.** | The refresh registry is erased when the episode is served or expires, and by `ForgetClient` on logout; `g_toldState` (what each client believes) and `g_lastSpoken` are erased on logout with it; `g_leadersSeen` holds one entry per online leader. No map is keyed by creature, so nothing accumulates per spawn. |
| **Hot-path cost.** | The realm switches and the offset are cached in atomics at config load (`g_scalingAvailable`, `LocalLevelScaling::CreatureOffset`), so `ViewFor` asks the config system nothing; it early-outs on "character has scaling off", then on the object checks, then on reaction, and only then reads the two `creature_classlevelstats` rows. |
| **`.reload config`.** | The resolvers and the cached switches are (re)installed in `ApplyTuning()` on `WORLDHOOK_ON_AFTER_CONFIG_LOAD`, so turning the feature on or off takes effect on the next creature rather than on the next restart. |

What the per-viewer model does not do: nothing reads a creature object at its view level. A script, a
creature that inspects itself, or a loot table keyed on level sees the authored creature. That is the
price of two characters fighting one wolf at two levels.

### How often the character is told

Every player-facing message this feature sends, and every trigger it has:

| trigger | who is messaged | how often |
|---|---|---|
| a character throws the switch at the Weaver | that character | once per click |
| the leader's switch changes while grouped | each online member | once per member per change |
| a member joins a group whose switch differs from theirs | that member | once |
| a member leaves, a group disbands | each affected member, in the Weaver's words | once |
| a leader logs out / hands over the lead, and the switch moves | each member whose state moved | once |
| **any periodic path** | — | **none: nothing here is sent from a timer, a creature update, an aura tick or a combat hook.** |

Against a crowded realm, the arithmetic is bounded by *real changes*: a group of 40 where the leader
toggles costs 40 lines, one per member, and nothing else for as long as the switch stays put. Two
guards keep a single event from being announced twice — `g_toldState` (what each client already
believes) makes a non-change silent, and `g_lastSpoken` suppresses a repeat of the *same* state inside
2 seconds, which is what stops the removal-plus-disband pair a two-person group fires from saying the
same thing twice. What is *not* coalesced, on purpose: toggling on, off, on again is three pieces of
news, and a realm's own social pressure is a better brake on that than a silent client.

## 2. Quest level

`QuestTemplateScaling.dbc` (15 `int32` fields: quest id, minimum, maximum, six player levels and six
offsets) gives a quest its own curve. `AscensionQuestScaling.cpp` reads it from the server's `dbc`
folder on every config load and installs it as `QuestCurveOwner`; a quest without a row is never
lifted. The point with the highest player level at or below the character's applies, so the quest
trails the character by that point's offset, held between the row's minimum and maximum:

| quest 7 "Kobold Camp Cleanup" (authored 2; min 2, max 20; points 6/5/4/3 → -4/-3/-2/-1) | player 3 | player 10 | player 24 | player 32 |
|---|---:|---:|---:|---:|
| level played at | 2 | 6 | 20 | 20 |
| on its curve (`OnCurve`) | yes | yes | yes | no, held at its maximum |

`Player::GetQuestLevel` answers with `EffectiveQuestLevel`, so the level never goes below the authored
one, and a character with scaling off (or blocked) plays every quest at its authored level.

## 3. Quest experience

`Quest::XPValue(playerLevel, levelScaling)`

```
questLevel = Level == -1 ? playerLevel : Level
if the quest scales for the character and EffectiveQuestLevel lifts it:
    if RewardXPDifficulty >= 10: return 0           # a lifted no-experience quest stays one
    questLevel = EffectiveQuestLevel(Level, playerLevel, curve)

diff = clamp(2 * (questLevel - playerLevel) + 20, 1, 10)
xp   = diff * QuestXP[questLevel][RewardXPDifficulty] / 10
xp   = round to 5 / 10 / 25 / 50 by the size of xp
```

A lifted quest pays what a quest of its *effective* level pays, with no discount. `QuestDef.h` carries
the `levelScaling` argument down from every caller so the choice is consulted per player, not per realm.

### Keeping the quest log honest

The client caches a quest's data by quest id, across characters and sessions, so once it has been
told a quest's level and rewards it keeps them until it is told again — which is how a quest picked
up with scaling on keeps showing that copy after the character turns scaling off. `Player::
RefreshQuestLogQueries()` re-sends the query response for every quest in the log, and is called:

* on **login** and on **level-up** (the CoA server component, gated on the realm switch, because a
  character with scaling off needs the resend just as much — the client is holding the scaled copy);
* on **accept** (`Player::AddQuest`), since the copy may have come from another character;
* whenever the character **changes the choice** (`DestinyWeaver::SetLevelScaling`), and whenever a
  challenge or ruleset block starts or ends (section 1).

The query response is not what the Ascension quest log shows, though. Its `Extensions.dll` answers
`GetQuestLogTitle`'s level and the log's reward experience for a quest in the log from the player's
`SMSG_UPDATE_OBJECT_ADDON` (0x0578) table: field 61 + quest log slot holds the level and field 36 +
slot the experience, for slots 0 to 24. With nothing sent there every quest shows as level 0 in grey.
`AscensionQuestLog` sends both fields, from `Player::GetQuestLevel` and the experience the quest giver
offers, on login, on level-up, when a quest takes its slot (`Player::AddQuest`) and from
`RefreshQuestLogQueries()`, so the toggle reaches the log as well.

The client's own "this quest is scaled" marker is quest flag `0x01000000` in the query response:
`GetQuestScaling` reads it, and the quest log then draws the title in `QuestDifficultyColors
["standard"]` instead of the colour of its level. `PlayerMenu::SendQuestQueryResponse` sets it only
with `CoA.QuestLevelScaling.ClientFlag` on (default off) and while the quest is on its curve for the
character, because the client then computes the level from its own copy of the row.

## 4. Quest money

`Quest::GetRewOrReqMoney(playerLevel, levelScaling)`

```
rewardedMoney = RewardMoney                            # the authored value
if RewardMoneyDifficulty is a real tier (1..9):        # stock data
    rewardedMoney = QuestMoneyReward[playerLevel][tier]
elif the quest scales for the character:
    tier = FindMoneyTier()                             # recovered, see below
    effective = EffectiveQuestLevel(Level, playerLevel, curve)
    if effective != Level and QuestMoneyReward[effective][tier] > QuestMoneyReward[Level][tier]:
        rewardedMoney = round(RewardMoney * QuestMoneyReward[effective][tier]
                                          / QuestMoneyReward[Level][tier])
return rewardedMoney * Rate.RewardQuest.Money
```

The reward keeps its own tier's ratio between the level it is played at and its own level, and is
never lowered. The curve's maximum is what bounds it: quest 7 pays at most what its tier pays at
level 20, however high the character is.

**This realm's data does not name a tier.** `quest_template.RewardMoneyDifficulty` holds the
client's `RewMoneyMaxLevel` value instead — quest 7 carries 67, which is exactly what the live
client cache stores for that quest, and it is never a usable index (`MAX_QUEST_MONEY_REWARDS = 10`),
so the stock lookup always fails. `FindMoneyTier()` recovers the missing index: of the tiers 0 to 9,
the one whose `QuestMoneyReward[QuestLevel][tier]` is closest to `RewardMoney` wins.

### Edges

* `quest_money_reward` stops at level 80; `QuestXP` goes to 100. A quest lifted past a missing row
  keeps its authored money.
* A quest with `QuestLevel <= 0` ("follow the player") has no own-level row to form a ratio from, so
  its money does not scale.
* `Quest::GetRewMoneyMaxLevel` (the "money instead of experience" payout at max level) follows
  `XPValue`, so it rises with the lifted experience.
