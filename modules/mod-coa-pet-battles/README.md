# mod-coa-pet-battles

Open-world, turn-based pet battles for Conquest of Azeroth, ported from the ALE (Lua) pet battle system of
[azerothcore-linux-server](https://github.com/catastrophic-impact/azerothcore-linux-server) (GPL-3.0, commit
`22bb7f3`). The port is staged; this module currently holds **phase 1: the data**, **phase 2: the battle
engine** with a GM command to try it, and **phase 3: per-account pet journals**.

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
