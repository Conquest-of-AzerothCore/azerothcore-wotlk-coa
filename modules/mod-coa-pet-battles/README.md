# mod-coa-pet-battles

Open-world, turn-based pet battles for Conquest of Azeroth, ported from the ALE (Lua) pet battle system of
[azerothcore-linux-server](https://github.com/catastrophic-impact/azerothcore-linux-server) (GPL-3.0, commit
`22bb7f3`). The port is staged; this module currently holds **phase 1: the data**.

## What it does now

At world startup the module loads the `coa_pet_*` world tables into memory and checks every reference (species →
kit, kit → ability, turns and effects, presentation rows against each species' kit, zone rosters, companions and the
stand-in creature templates). Any error is logged and leaves pet battles disabled; nothing half-loads.

Settings live in `conf/mod-coa-pet-battles.conf.dist` (`CoAPetBattles.*`), defaulting to the upstream values.

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

`sql_writer.write(export, directory, date, first_number, creature_template_columns(base schema))` then writes the
pending SQL, and `sql_reader.read` reads it back for comparison with the export. Once the data is tuned in CoA, a
fresh export would undo those changes, so treat a re-import as a deliberate replacement.
