# CoA Wildcard data

Generators for the data of Darkmoon - Season 10 Wildcard. Each script writes one repository file from the source
named below and reproduces it byte for byte from the same inputs.

- `level_achievement_conditions.py`: `rev_20260929_98_coa_level_achievement_conditions.sql` from
  `Achievement.dbc` and `Achievement_Criteria.dbc`.
- `prestige_achievements.py`: `rev_20260929_99_coa_prestige_achievements.sql` from the same files.
- `boss_marks.py`: `rev_20260930_01_wildcard_boss_marks.sql` from the db.ascension.gg page of item 375250,
  archived 2026-08-04, and the world database.
- `tooltip_links.py`: `rev_20260930_02_wildcard_tooltip_links.sql` from `Spell.dbc` and `CharacterAdvancement.dbc`.
- `call_board_s10_quests.py`: `rev_20260930_05_hero_call_board_s10_quests.sql` from the `questcache.wdb` of clients
  that played on the realm and the world database.
- `starter_data.py`: `src/server/coa/AscensionWildcardStarterData.h` from `CharacterAdvancement.dbc` and
  WildcardHarvest addon saves of the season's starting rerolls.

The SQL files are in `data/sql/updates/pending_db_world/`. Silas Darkmoon's and Burth's spawns
(`rev_20260930_00_wildcard_silas_burth_spawns.sql`) were placed by hand in game and have no generator.

## Usage

Python 3.11 or newer. `--dbc` is a directory with the CoA client DBC files. The world database options work as in
[coa-world](../coa-world/README.md): `--defaults-file` is a MySQL client option file, `--mysql` the client if it is
not on PATH, `--database` the world schema.

```sh
python apps/coa-wildcard/level_achievement_conditions.py --dbc <dbc> <output>
python apps/coa-wildcard/prestige_achievements.py --dbc <dbc> <output>
python apps/coa-wildcard/tooltip_links.py --dbc <dbc> <output>
python apps/coa-wildcard/boss_marks.py --page <page> --defaults-file <cnf> --database acore_world <output>
python apps/coa-wildcard/call_board_s10_quests.py --caches <dir> --defaults-file <cnf> --database acore_world <output>
python apps/coa-wildcard/starter_data.py --dbc <dbc> <harvest>... <output>
```

- `boss_marks.py` reads the saved page
  `https://web.archive.org/web/20260804172727id_/https://db.ascension.gg/?item=375250` (plain or gzip) and keeps the
  creatures the world database has.
- `call_board_s10_quests.py` searches `--caches` for `questcache.wdb` in folders named
  `Darkmoon - Season 10 Wildcard` or `darkmoon-wild-10`. It leaves out quests the world already defines and quests
  whose targets or items have no source there.
- `starter_data.py` was run with `WildcardHarvest_2026-08-31_2255_freepick.lua` and
  `WildcardHarvest_2026-09-02_2100_rollgrants.lua`.
