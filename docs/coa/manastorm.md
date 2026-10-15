# Local Manastorm

This implements a playable private reconstruction on the copied Ascension client. Official backend
parity is not asserted. Numerical balance below is an explicit local policy, authorized by the user.

The solo-scaling and cache-delivery changes described below are covered by the
[September 9 release summary](local-release-state.md).

## Playing

Enter through the native Manastorm queue, or `.manastorm enter 1`. Characters need level 10.
Solo and parties of up to five are supported. The party leader starts the run; everyone must be
alive, outside combat, in the same outdoor map within 100 yards, and within ten character levels.
The participant list is fixed for that run. Everyone needs the selected checkpoint in that party mode.

Leaving the preparation bubble starts combat. Kill guards to weaken the boss's Chaotic Link, or fight
the empowered boss directly. Defeating the boss awards that floor immediately. Cogsley provides mail,
upgrades, repair/selling and continuation; walking back into the portal also continues. `.manastorm
next`, `.manastorm leave` and `.manastorm status` provide alternate controls.

The catalog contains 61 rooms from 19 dungeon maps. Startup checks templates, height, line of sight
and connected walking segments. The installed dataset admits 30 rooms, including one opening room.
Unavailable rooms are excluded. If the early pool contains one valid room, a fresh instance of that
room is used again rather than blocking progress. Additional rooms unlock as depth increases.
This geometric check is not a combat/pathfinding playtest of every boss.

Depths extend through the native limit of 16,384. Start checkpoints use the client's irregular
difficulty-0/2 flags, not an invented every-fifth-level rule. Separate progress is stored for solo,
duo, trio and group, with separate endgame variants. With this server's existing level-80 cap, endgame
starts at 80; reaching the cap ends the leveling run before its next floor. NPC levels refresh on each
floor. Higher depths scale health/damage. Player-count scaling follows the default five-player
AutoBalance curve, normalized to the existing five-player Manastorm baseline. For `n` participants,
`f(n) = (tanh((n - 2.5) / 1.5) + 1) / (tanh(2.5 / 1.5) + 1)`, clamped to one through five players.
Health uses `4.2 * f(n)` and damage uses `1.4 * f(n)` in place of the old linear group multipliers;
armor uses `f(n)`. Solo health is about 48% lower and damage about 83% lower than the previous policy.
Depth scaling, the five-player baseline and native NPC abilities remain. Chaotic Link adds 25%
health and 10% damage per living guard, capped at eight. This adapts the curve, not the full NPCBots module.

Five shared out-of-combat resurrection charges reset each floor. A full wipe ends the run. A short
disconnect can resume an existing instance for up to 120 seconds. A process restart returns characters
to their saved outside positions; it does not recreate unfinished combat.

## Rewards and gadgets

Successful floors create real rewards. Caches are delivered directly into bags, using available stacks.
If bags are full, the saved cache waits for space and is retried automatically, including after relog.
Currency and gold retain their existing mail delivery. Previously mailed caches are preserved.
There is no bonus-on-exit cache or classless ability-card reward. For depth `d`:

| Reward | Local rule |
| --- | --- |
| Bonzo Bolts | `3 + floor(min(d, 5000) / 5)` |
| First-clear Bedlam Bullion | `1 + floor(min(d, 5000) / 50)` per character, mode and depth |
| Gold | Character level × 20 copper × `(1 + floor(min(d, 1000) / 10))` |
| Leveling XP | 7.5% of the current native next-level requirement on first clears, 6% on repeats |
| Leveling cache | One per successful floor |
| Endgame cache | Accumulated chance plus 15% + 0.05% × `min(d, 1000)`, capped at 100%; reset only on success |
| Treasure Keeper | At most one per floor; 2% + 0.015% × depth per guard kill, capped at 10%; defeating it adds two caches and 20 bolts |

Nine actual cache items open through native item loot. Pools use real local dungeon/reference-loot
equipment. Selection filters level/basic proficiency and prefers nearby required levels; a restricted
character with no eligible entry still gets a real tradable item. This is not a specialization/stat
optimizer. The top leveling cache includes TBC/WotLK rewards for levels 61–79. Endgame caches use
level-80 gear: item levels 187–200 before depth 25, and 200–232 including epics thereafter.

The three starter items are reusable Manastorm Potion, Regeneration Matrix and Magical Escape.
Cogsley replaces missing items when bag space permits. There are 107 purchase entries across potion,
Interrupt Rod and Hearty Heal upgrade families. Each rank costs `15 × rank²` bolts and requires the
previous rank. Four native loadout slots persist in the character database; active gadgets require
ownership and an equipped slot. Change the loadout outside a run. Hearty upgrades are passive and add
25% healing scaling per rank. The Cogsley companion costs ten bullion; one bullion exchanges for ten bolts.

The implemented rotating affixes are Unrelenting Speed, Leeching and Tribal Fury, from depth six.
Other client-authored hazards are not represented as working affixes. The potion's resource helper
is implemented; the eight Mobility Mixtures permit moving casts/channels only inside private instances.
Temporary gadget buffs are removed on normal exit. Native class spells using the same private aura
number do not acquire this exception.

## Persistence and isolation

A floor's first-clear record, pity/cache counters, currency mail, item instances, pending-cache records
and XP voucher share one database transaction. Each cache has a durable item GUID before delivery.
Moving that item into an empty inventory slot, or merging it into an existing saved stack, commits with
consumption of its pending record. Native bag publication waits for a successful commit; the player's
map thread waits for that small transaction so the selected slot cannot change meanwhile. A slot conflict
fails instead of overwriting an inventory row. Native stack state and its update queue are preserved when
serializing the prospective stack. Newly created unsaved bags/stacks defer delivery until persisted.
Online mail publication waits for commit too. XP application saves native character state and consumes
the voucher together. Session tokens and bounded packet queues protect deferred input. Shared encounter
state is separate from each participant's personal progress, inventory/loadout and return location.

Private instances retain their owner's GUID plus an explicit participant allowlist. They do not use
ordinary dungeon bindings, persistent world spawns, normal kill loot/reputation or quest kill credit.
Core hooks still handle mapless character loading safely. No client executable/DLL patch is part of
this package.

## Evidence and reproduction

The repository's [Manastorm harness](../../apps/coa-tests/manastorm/run.py) compiles production
reward, queue and loadout methods against an isolated transaction backend.
Additional validation covered the native checkpoint dataset, mapless ownership,
movement scope and actual Lua 5.1 behavior. These checks and a linked build do not
constitute a manual in-game combat run.

SQL goes through the normal updater. Never edit an already applied migration;
use a new follow-up. Client overlays remain external deployment inputs, including
the earlier Ranger secondary-mana, Advantage and trusted ScenarioObjectiveTracker
saved-position fixes.

Research references: [official Manastorm feature update](https://ascension.gg/cs/news/s9-ch.2-full-features-overview/458)
for per-floor rewards, group progression, accumulating cache chance and gadget upgrades;
[official CoA update](https://ascension.gg/en/news/conquest-of-azeroth-massive-update-article/464)
for CoA context. Exact drop rates were not recovered; the table above describes this server's own balance.
The solo follow-up uses [trickerer/mod-autobalance at 3020acda](https://github.com/trickerer/mod-autobalance/blob/3020acda28a23b532ff9b7515dc4de41a4ef0be8/src/AutoBalance.cpp)
and its configuration defaults.
The [solo-tuning harness](../../apps/coa-tests/manastorm/solo_tuning.py) compares actual
before/after spawn blocks and the original AutoBalance function, then exercises
production cache delivery with native item-queue functions against isolated
transaction doubles. It requires the pinned AutoBalance source and hash manifest
as `--autobalance`, and the original module source as `--before-source`; those
historical inputs are supplied separately. Both runners require Python and a
C++20 compiler.
