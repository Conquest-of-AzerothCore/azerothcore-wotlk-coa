# CoA DBC tools

## Agent retrieval: coa-dbc-viewer

`coa-dbc-viewer` is a read-only, JSON-first tool for agents investigating CoA abilities. Requires Python 3.11+;
inspection needs no third-party Python packages, browser, server build or running worldserver. `source` uses `rg`.
Pass the actual client extraction or server `DataDir/dbc` explicitly; these are different evidence sources.
The optional browser view uses the same parser. No game data is committed or uploaded.

For ranks/acquisition, interpreted execution paths and verification links, use the
[spell and quest mechanic map](../coa-mechanics/README.md): `coa-dbc-viewer map --data <directory> --id <spell>`.
`record --with-map` embeds it alongside selected raw fields; `--details` expands its linked contracts.

```sh
python apps/coa-dbc/coa-dbc-viewer tables --data env/dist/data/dbc
python apps/coa-dbc/coa-dbc-viewer search --data env/dist/data/dbc --table Spell --query Frostbolt --limit 10
python apps/coa-dbc/coa-dbc-viewer schema --data env/dist/data/dbc --table Spell
python apps/coa-dbc/coa-dbc-viewer record --data env/dist/data/dbc --id 116 \
  --field 'SpellName[enUS]' --field 'Description[enUS]' --field 'Effect*' --with-links
python apps/coa-dbc/coa-dbc-viewer links --data env/dist/data/dbc --id 116
python apps/coa-dbc/coa-dbc-viewer source --data env/dist/data/dbc --id 116
python apps/coa-dbc/coa-dbc-viewer compare --data env/dist/data/dbc --other out/client-dbc --id 116
```

- Successful retrieval writes JSON to stdout. Failures return nonzero with JSON errors on stderr (argument
  syntax errors use argparse). `--field` matches an exact name or a trailing `*` prefix; unknown names fail.
- Search supports name/ID substrings, `--locale`, `--offset` and `--limit` (maximum 200). Use `record --id`
  for exact ID lookup. Spell records include relevant scenario definitions and their registered numerical
  checks; these links do not claim a scenario has run. `source` finds text references, not implementation proof.
- Typed fields include raw bytes, signed values, floats, localized strings, known flag labels and links.
  Provenance includes file/schema-source hashes and extraction-manifest agreement. A missing manifest means
  unknown archive origin; a mismatched one is marked stale. A directory path does not establish client version.
- Reviewed layouts cover Spell, SpellDuration, SpellRadius, SpellRange, SpellCastTimes, Talent, TalentTab,
  SkillLineAbility, CharacterAdvancement, CharacterAdvancementClassTypes, CharacterAdvancementTabTypes,
  ChrSpecs, SpellCharges, SpellChargesCategory, SpellAddon and SpellCustomAttr. Some custom layouts are partial:
  unnamed bytes remain opaque. Other tables support `record --table NAME --row 0` as raw bytes without guessed IDs.
- Truncated files, duplicate IDs and unexpected reviewed layouts fail. Bad strings/nonfinite floats carry
  field errors. CoA's packed CharacterAdvancement has 179 logical fields in 692 bytes, so fields are byte-addressed.
- `compare` reports semantic changes, including client descriptions, while ignoring string-block repacking.
  It compares a selected ID present in both data sets. Use `client_dbc.py diff` for whole-set core-visible changes.
- DBC values precede SQL and C++ corrections. In particular, `EffectBonusMultiplier` is not the effective CoA
  AP/SP coefficient. Incoming references show acquisition candidates; trace their conditions before concluding
  that players can acquire or execute an ability. Cached data rejects detected file changes; restart after replacement.

Optional evidence layers keep database rows and recorded gameplay separate from DBC fields:

```sh
python apps/coa-dbc/capture_sql.py --config path/to/worldserver.conf --mysql path/to/mysql \
  --spell 116 --output out/spell-sql.json
python apps/coa-dbc/coa-dbc-viewer record --data env/dist/data/dbc --id 116 \
  --sql out/spell-sql.json --observations .cache/coa-gameplay-tests/RUN
python apps/coa-dbc/coa-dbc-viewer serve --data env/dist/data/dbc --port 8765
```

SQL capture uses SELECTs on a local configured world database, follows rank chains (including negative-ID
bindings), and captures bonus/proc/rank/script/DBC/learn metadata. Credentials stay in a temporary mode-600 file.
The capture may include several requested spells and their ranks; inspect row IDs. It is a sequence of reads,
not an atomic snapshot or a calculation of effective runtime values. Result directories must contain matching
scenario, summary and native result identities. Recorded samples remain historical evidence, including failures.
Neither evidence layer proves current deployment or rendered-client behavior. The optional HTTP API binds only
to loopback and is read-only: `/api/tables`, `/api/search?table=Spell&q=Frostbolt`, `/api/record?table=Spell&id=116`.

Tests: `python -B apps/coa-dbc/test_inspector.py` and `python -B apps/coa-dbc/test_capture_sql.py`.
The byte fixtures independently check signed/string/packed decoding, invalid layouts, reference cycles,
stale provenance, semantic differences and evidence mismatches. Keep new field definitions grounded in a
reviewed native reader; a plausible label is not enough.

## Client extraction and whole-set checks

The worldserver loads `DataDir/dbc` at startup. It must hold the original CoA client's tables: with a stock
or partial set it drops content that references CoA-only rows, such as item limit categories, gameobjects and
currencies. Players use the same tables, so client patches must not replace DBC archives, and `*_dbc` world
tables must not override client rows. Game files are never committed.

Extraction additionally requires [mpqcli](https://github.com/TheGrayDot/mpqcli).

```sh
python apps/coa-dbc/client_dbc.py extract "C:/CoA/client/Data" out/client-dbc --original --mpqcli path/to/mpqcli.exe
python apps/coa-dbc/client_dbc.py check out/client-dbc
python apps/coa-dbc/client_dbc.py diff "C:/CoA/server/data/dbc" out/client-dbc
```

Copy the extracted files into `<DataDir>/dbc` and restart the worldserver.

- `extract` reads the client's archives in load order; the last archive holding a table wins. `--original`
  reads the launcher's untouched `NAME.ORIGINAL` copies, `--archive NAME=PATH` substitutes any archive. Tables
  are named as the worldserver opens them. `client-dbc.manifest.json` records each table's archive and hash.
- `check` validates the set against this checkout's `DBCfmt.h`: missing tables, file name case and field
  layouts. Strings outside the string block and rows with index -1 are reported as notes.
- `diff` compares the values the core reads, so a rebuilt string block is not a change.

Tests: `python apps/coa-dbc/test_client_dbc.py`
