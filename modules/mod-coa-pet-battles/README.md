# mod-coa-pet-battles

Open-world, turn-based pet battles for Conquest of Azeroth, ported from the ALE (Lua) pet battle system of
[azerothcore-linux-server](https://github.com/catastrophic-impact/azerothcore-linux-server) (GPL-3.0, commit
`22bb7f3`). The port is staged; this module currently holds **phase 1: the data**, **phase 2: the battle
engine** with a GM command to try it, **phase 3: per-account pet journals** and **phase 4a: battle sessions and
upstream's addon protocol**.

## What it does now

At world startup the module loads the `coa_pet_*` world tables into memory and checks every reference (species →
kit, kit → ability, turns and effects, presentation rows against each species' kit, zone rosters, companions and the
stand-in creature templates). Any error is logged and leaves pet battles disabled; nothing half-loads.

Settings live in `conf/mod-coa-pet-battles.conf.dist` (`CoAPetBattles.*`), defaulting to the upstream values.

## Battle engine

`src/Engine/` is a C++ port of upstream's `pb_core.lua` and `pb_rules.lua`: pet stats and ability picks, tooltips
with each pet's own numbers, round resolution with all 42 retail effect handlers, auras and weather, family
passives, forced swaps, the trap and the enemy AI. It uses only the standard library and the loaded data, and draws
every random number through one interface in upstream's order.

It is proven against upstream by replay. `tools/pet_data/trace_upstream.py` ran 113 seeded battles (1v1 and 3v3,
levels 1–25, 1,317 rounds) through upstream's own Lua and recorded every roll, command, event and pet state in
`tests/fixtures/`. The unit tests replay each battle through the C++ engine and require identical events, statuses,
pet state and rolls. What the recorded battles cover, measured inside upstream's Lua:

- every effect handler a species can reach is dispatched at least 8 times, and the unknown-effect handler never;
- 17 engine branches that production kits can reach happen at least 4 times each — reflects (179), webbing,
  Plagued Blood, Undead/Mechanical revives, Portal/Fade swaps, the meteor, Chew, leech, siphon, spore releases,
  block charges, damage split over the bench, bench damage, ally and team heals, and forced swaps (145, 107/139);
- the tooltip of every kit option of every recorded species matches, and across all 20,568 kit tooltips of the
  3,428 species none reaches upstream's order-dependent fallback.

Effects only the unreferenced retail library can reach have their own tests on the real abilities: Life Exchange,
Nevermore and its ability lockout, Beaver Dam's wall, Refuge, Spiny Carapace, Dark Rebirth, Reflective Shield and
the XE-321 Boombot bomb. Two library branches are recorded from upstream like the rest: six battles give a pet
Cyclone (190), Void Cyclone (2102) or Photosynthesis (268, in Sunny Day weather) in place of its first ability
(`LIB` and `WEATHER` lines), covering team-wide damage auras and Photosynthesis's weather bonus.

## Pet journals (phase 3)

Each **account** owns one pet journal, shared by all its characters on this realm: up to one pet per species with
level (1–`MaxLevel`), XP, quality (1–4), an ability pick (1 or 2) per slot, health and skin, plus three teams of three
and the active team. Playerbot sessions get no journal.

- **Rules** follow upstream: a win is worth the `coa_pet_xp` XP of the enemy's level, reduced by `XpStep` (20%) per
  level the enemy is below the pet and nothing at 5+ below; level-ups carry XP over and heal fully; a hurt pet
  regains `RegenPercent` (1%) of its maximum health every `RegenSeconds` (10 s), also while offline; a capture
  replaces an owned pet only with a higher quality, or the same quality and a higher level; a battle with no team
  set up uses the three highest-level pets.
- **Companions**: a companion spell the character knows becomes a level-1 pet of its species (at login and when it is
  learned). Upstream's mapping covers 248 of the 252 stock companion spells; seven CoA companion spells are mapped
  too (158 of CoA's 1,857 companion spells in all). `data/companion_review.tsv`, written by
  `tools/pet_data/companion_census.py`, lists every companion spell with its status and a suggestion; the
  unmapped ones need new species, and the stand-in range only fits species entries up to 49999.
- **Storage**: `characters.coa_pet_journal`, `coa_pet_team` and `coa_pet_account`. An account's journal is loaded at
  its first character's login and dropped after the last logout; each change is one async write that only applies
  when its revision is newer than the stored row. A stored pet that no longer fits the data stays in the database,
  still counts as owned and is hidden until the data fits again. Deleting the account deletes its rows.
- **GM commands** (selected player or self): `.petbattle journal`, `grant <species> [level] [quality]`,
  `xp <species> <enemyLevel>`, `health <species> <hp>`, `heal`, `picks <species> <a1> <a2> <a3>`,
  `team <n> <s1> <s2> <s3>`, `team active <n>` and `reload` (reads the journal back from the database).
- Two characters of one account online at once share one journal; the gameplay harness gives every actor its own
  account, so that rule is covered by a unit test only.

## Battles and the addon protocol (phase 4a)

Players fight through upstream's client addons (`wotlk_petbattle`, `wotlk_pets`; required, shipped in phase 5). The
server speaks upstream's protocol exactly: hidden `ACORE` addon whispers of the form `module|action|payload` (240
characters sent, 255 accepted, numbered chunks for long lists, the `core` hello/who/ping handshake), the `pbt` battle
messages and the `pbj` journal messages.

- **Sessions** (`src/Battle/`): one battle per account; the account's battle team (the phase 3 fill when no team is
  set) against up to three enemies; the turn offer (`go`, `force`, and `lock`/`stun` turns that pass by themselves),
  playback of every engine event with upstream's delays, capture, XP for every pet that acted, health kept after the
  battle (fainted pets at 1). A battle ends on win, loss, forfeit (`pbt|quit`), five idle minutes, death, changing map
  or moving more than 40 yards away. Starting a new battle silently replaces a running one.
- **Differences from upstream, by decision**: logging out mid-battle counts as a forfeit (every pet at 1 health; upstream
  let players escape); no creature freeze around a battle; a second character of the same account cannot battle while
  another fights; status tooltips are kept per battle; the journal list sends pets by species.
- **Stand-ins**: both active pets appear next to the player as their stand-in creatures with the pet's model and size.
  Spell visuals, lunges and emotes are phase 5.
- **Proof**: `tools/pet_data/trace_battles.py` runs upstream's `pb_battle.lua` and `pb_store.lua` under stubbed server
  functions and records 41 sessions (`tests/fixtures/sessions.txt`): refusals, forfeit, watchdog, interruptions,
  logout, restart, the account rule, bots, the three capture outcomes, the journal messages and 24 random battles. The
  unit tests replay every session through the C++ code and require identical messages, delays, stand-in spawns, rolls
  and final journals.
- **GM commands**: `.petbattle fight <species>[@level] ...` (up to three enemies, level 5 by default) starts a battle for
  the selected player or yourself; `.petbattle send <module|action|payload>` acts as that player's addon.

## Wild pets (phase 4b)

Small wild pets appear around players in the 61 zones of `coa_pet_zone`, by upstream's `pb_wild.lua` rules; the
numbers are `CoAPetBattles.Wild.*` settings with upstream's values as defaults.

- **Where**: every 5 seconds the real creatures (with a database spawn, alive, out of combat) within 60 yards of each
  eligible player seed up to 3 wild pets of different species within 90 yards, one per species within 90 yards. A pet
  appears at a random spot 5-50 yards from its creature on ground within 2.5 yards of its height (3 yards away after 8
  misses), at pet size, friendly and passive, and wanders 3 yards. Critters (`critter = 1`) are adopted instead: the
  real critter becomes the wild pet and gets its faction and flags back afterwards.
- **Who**: every player except bots; scanning skips players who are dead, in combat, in a pet battle or outside the
  normal phase. A player who found nothing is searched again after moving 25 yards or after 45 seconds.
- **Retiring**: after 10 minutes, after a minute with nobody within 90 yards, when its creature is gone, or at shutdown.
- **Challenge**: right-click within 12 yards; the pet's level follows the zone's mob-to-pet level range from the seeding
  creature's level. Above pet level 2, two more pets of the zone's species join. A started battle consumes the pet (an
  adopted critter despawns and respawns normally) and keeps that species away from the spot for 90 seconds.
- **Minimap**: the addon receives `pbw|pets|<dx>,<dy>,<species>,<level>,<name>;...` once a second and `none` once
  when the last pet nearby is gone.
- **Differences from upstream, by decision**: critters are adopted (upstream's adoption code exists but no species uses
  it); a shutdown releases adopted critters; upstream's GM size tools and its rescale workaround are not ported.
- **Proof**: `tools/pet_data/trace_wild.py` runs upstream's `pb_wild.lua` in a scripted world and records 24 situations
  (`tests/fixtures/wild.txt`); the unit tests replay each one spawn for spawn, roll for roll.
- **GM commands**: `.petbattle wild` lists the wild pets near you; `.petbattle challenge` challenges the nearest one
  within reach, the same path as the menu.

## Trying it: `.petbattle sim`

GMs can run a whole battle between two pet species and read it in chat:

```
.petbattle sim <speciesA> <speciesB> [level] [seed]
```

Species are creature entries from `coa_pet_species`. Both pets are rare at the given level (default 25), the
upstream AI plays both sides, and the battle stops after 50 rounds. The seed is printed so the same battle can be
replayed, on any server build: the sim draws its numbers from MT19937 without a standard-library distribution.

```
[Pet sim] <pet A> (<level> rare) vs <pet B> (<level> rare), seed <seed>
R<round> <pet>: <ability> -> <target> <damage> (<health>/<max health>)
R<round> <pet> heals <amount> (<health>/<max health>)
R<round> <target> dodges <ability>
R<round> <pet>: <aura> (<rounds> rounds | permanent | <charges> charges)
R<round> <pet> faints.
<pet> wins.
```

## Data

The data is CoA-owned: tune it with ordinary pending SQL updates. It was imported once from the upstream Lua's
effective state after loading (the generated tables plus the code that runs when they load: family clones of
abilities, synthetic wild kits, extra zones), and each species' ability names, icons, tooltips and visuals were
resolved by upstream's own `C.Kit` at import time.

| Table | Rows |
|---|---|
| `coa_pet_species` | 3,428 |
| `coa_pet_kit` | 3,842 (421 retail kits are kept as an unreferenced library) |
| `coa_pet_kit_ability` | 22,959 |
| `coa_pet_ability` | 4,933 |
| `coa_pet_ability_turn` | 5,937 |
| `coa_pet_ability_effect` | 10,975 |
| `coa_pet_effect_property` | 242 |
| `coa_pet_state` | 123 |
| `coa_pet_aura_state` | 807 |
| `coa_pet_xp` | 123 |
| `coa_pet_zone` | 61 |
| `coa_pet_zone_species` | 3,312 |
| `coa_pet_presentation` | 20,568 |
| `coa_pet_model_size` | 3,425 |
| `coa_pet_display_size` | 3,983 |
| `coa_pet_companion` | 248 |

Rows left out on import, as upstream ignores them at runtime:

- Companion spells whose creature is not a pet species: 49964 and 50049 (creature 27914), 62609 (33238),
  62746 (33239).
- Kit stat keys other than power, speed and stamina (cosmetic, boss and elite markers on 18 kits that no species
  uses); upstream reads only the three stats.

## Stand-in creatures

Each species battles as a stand-in creature: a copy of its own `creature_template` at entry **9800000 + species**
(range 9800000–9849999 is reserved for this module), level 60, faction 35, with AI, scripts, flags, loot, gossip
and difficulty entries cleared, and a pet-sized display scale.

## Re-running the import

The importer is in `tools/pet_data/`. It needs a Lua 5.1 runtime through [lupa](https://pypi.org/project/lupa/)
2.8, installed outside the repository:

```sh
python3 -m pip install --target /tmp/lupa-lib lupa==2.8
PYTHONPATH=/tmp/lupa-lib python3 -B modules/mod-coa-pet-battles/tools/pet_data/export_upstream.py \
  --upstream <azerothcore-linux-server checkout> --commit <commit> --out /tmp/export.json
```

Then write the pending SQL. The importer reads every data file back and refuses to finish unless it equals the
export and its row counts:

```sh
python3 -B modules/mod-coa-pet-battles/tools/pet_data/import_data.py --export /tmp/export.json \
  --date <YYYYMMDD> --first-number <first unused NN>
```

The committed files `rev_20261123_81..97` were generated this way from upstream commit `22bb7f3` (export sha256
`f84767f102e3ca450f57c97a5f4b9d377bc1a1c8de13e98c7e6edc4bcea244fd`). Once the data is tuned in CoA, a fresh export
would undo those changes, so treat a re-import as a deliberate replacement.

A stand-in whose species is removed later keeps its `creature_template` row (that table is never deleted from), but
loses its model rows on the next import; retire it with an explicit update rather than leaving the entry behind.

## Re-recording the replay fixtures

`tests/fixtures/` was recorded from the same export and upstream commit. The run is deterministic and refuses to
finish unless every handler and branch reaches its minimum count:

```sh
PYTHONPATH=/tmp/lupa-lib python3 -B modules/mod-coa-pet-battles/tools/pet_data/trace_upstream.py \
  --upstream <azerothcore-linux-server checkout> --export /tmp/export.json \
  --out-dir modules/mod-coa-pet-battles/tests/fixtures --seed 20261123 --battles 400 \
  --max-bytes 3300000 --random-bytes 1650000
```

The battle sessions are recorded the same way; `--mysql-defaults` (read-only) refreshes the display and model rows in
`battle_world.txt` from a world database:

```sh
PYTHONPATH=/tmp/lupa-lib python3 -B modules/mod-coa-pet-battles/tools/pet_data/trace_battles.py \
  --upstream <azerothcore-linux-server checkout> --seed 20261124 --battles 24
```

The wild pet situations use the same test pool and `battle_world.txt`:

```sh
PYTHONPATH=/tmp/lupa-lib python3 -B modules/mod-coa-pet-battles/tools/pet_data/trace_wild.py \
  --upstream <azerothcore-linux-server checkout> --seed 4242
```
