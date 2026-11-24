# 1012. Static client data ships in the client MPQs

- Status: accepted
- Date: 2026-11-20

## Context

The server streamed static client rows at login and on demand: creature models and displays, item displays and
items, spells, spell visuals, sounds, super tracks, skill line abilities, shapeshift forms, vanity collections,
vehicles, world maps, and, before login, game object displays, maps and map difficulties. Every login paid for
rows that never change between players, an item or world map change needed server code (`ClientItemPatches`,
`coa_client_*` tables), and the client's view depended on the stream arriving. ADR 0005 still names the display
patch service as a source of client rows.

## Considered options

1. Keep streaming.
2. Bake the streamed rows into the client's DBC files, ship them through the CDN, keep SQL as the source and add a
   bake tool that writes server rows into the archives.
3. Bake the rows once and make the client DBC files the source; the server keeps its own copy and a tool checks
   that both agree.

## Decision

Option 3. The rows streamed at `ced81e8073` were baked into the winning DBC of each table (`patch-M.MPQ`,
`patch-S.MPQ`, `patch-T.MPQ`, `patch-ZG.MPQ`) and the static streams, their registries, config and tables were
removed (PR #12775). Rows that differ per player or over time keep being sent. New or changed client rows are
edited in the client archives; the server reads the same tables from `<DataDir>/dbc` and the world `*_dbc`
overrides. `apps/coa-dbc/client_dbc.py drift` compares an extracted client set with the server's tables, the
`*_dbc` overrides and `coa_client_spell_description`. The workflow is in
[static client data](../coa/client-data.md).

## Consequences

- Login no longer carries static rows; a client without the current archives shows missing or wrong data, so the
  CDN update must be published before the server.
- A contributor who adds an item, spell, display or map row edits a client archive and the server copy together,
  and runs the drift check; the gameplay harness models the server's rows and cannot see a stale archive.
- Rolling the server back past PR #12775 also needs the dropped `coa_client_*` tables restored.
- The display patch service named in ADR 0005 now sends only the per-player rows.
