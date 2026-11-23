# CoA Knowledge MCP

Use whenever a task involves Ascension or CoA facts (classes, spells, items, item stats, BisBeard data, Mystic
Enchants, Worldforged/Bloodforged gear, client DBC tables, MPQ paths, dungeons, bosses, NPCs, quests) or any
`coa-knowledge` tool (`status`, `search`, `get`, `items_find`, `dbc_tables`, `dbc_rows`, `client_paths`,
`spell_compare`, `spell_scaling`, `decode_flags`, `write_entry`, `undo_entry`) is available.

The CoA Knowledge MCP (`https://coa-mcp.bledt.dev/mcp`) provides verified and provenance-tagged facts about Ascension (Conquest of Azeroth, WotLK, Octo, Classic, S10) for emulator development.

## Connection Setup

If the MCP server is not yet connected in Claude Code:
```bash
claude mcp add --scope user --transport http coa-knowledge https://coa-mcp.bledt.dev/mcp
```
For authenticated write access, configure the `Authorization: Bearer <COA_MCP_BEARER_TOKEN>` header on the MCP connection.

---

## Rules for this repository

These override the defaults below.

- The user registers the server (`claude mcp add` is blocked for agents in auto mode). Until it is registered, call it
  with curl: JSON-RPC POST to the URL, header `Accept: application/json, text/event-stream`, no session id needed.
- Without a bearer token there is no write access: do not write; tell the user about the fact instead. With write
  access, ask the user before the first write in a session (it publishes to a public service).
- Agent-written entries in the MCP are self-declared data, not proof. In a cross-check it is an extra reading of the
  client, not an independent source.
- This emulator (its databases such as `acore_world`, realm or PTR copies, its source, `verify_all.py` results) is
  never Ascension proof. Never write its rows or behaviour as Ascension facts, nor the fork's own custom content.
- Reconstructed client or server code (for example a rebuilt Extensions.dll) counts as decompiled code: never write it.

---

## 1. Reading & Research Workflow

1. **Check server state first:** Call `status` at the start of a session to see loaded layer versions and known data gaps.
2. **Pick the right read tool:**
   - `items_find` — Filter items by `realm` (`coa`, `classic`, `s10`, `wotlk`, `octo`), `slot`, `quality`, `type`, `item_class`, `category`, `name`, and `stat` + `min_value` (sorted by stat or item level).
   - `search` — Full-text search across all layers (`topic`: `spells`, `items`, `classes`, `dungeons`, `npcs`, `notes`, `dbc`; `realm`: `coa`, etc.).
   - `get` — Read a full page by ID (`item:10531`, `spell:133`, `class:coa:barbarian`, `dbc:Spell`, `dbc:Spell:133`, `path:DBFilesClient/Spell.dbc`, `entry:12`). For large pages, pass `sections` to read specific sections.
   - `dbc_tables` / `dbc_rows` — Inspect client DBC schemas, archive origins, and filter rows with `{field, op, value}` conditions.
   - `client_paths` — Browse or search file paths and sizes in the CoA client MPQs.
   - `spell_compare` / `spell_scaling` / `decode_flags` — Compare spells side-by-side, compute level-scaled spell values, or decode WoW 3.3.5a bitmasks.
3. **Respect provenance & realm honesty:**
   - `realm_proven=0` / `(unproven)` on the main BisBeard item list means the item comes from the shared CoA/Classic/S10 API; `in_client=1` means the ID exists in the CoA client's `Item.dbc`, which is a hint, not proof of CoA.
   - Files from `project` archives and `coa-development.org` pages are **not** evidence about live Ascension.

See [knowledge-mcp-tools](knowledge-mcp-tools.md) for full parameter details and examples.

---

## 2. Writing Back During Authenticated Sessions (`write_entry` / `undo_entry`)

When your MCP session has write access (`write_entry` and `undo_entry` are available), **proactively record verified Ascension facts** as you discover or confirm them so future sessions do not have to re-research them.

### What to Record (`write_entry`)
1. **Missing Gaps (Highest Priority)**
   - **Dungeons, Encounters & Mechanics:** Boss abilities, phase transitions, timers, spell IDs cast, and mythic/ascended differences (`dungeon:<slug>`, `encounter:<slug>`, `mechanic:<slug>`).
   - **NPCs & Spawns:** Creature behavior, faction, approximate spawn locations, and linked spells/items (`npc:<slug>`).
   - **Quests:** Custom CoA quest chains, objectives, NPCs, and rewards (`quest:<slug>`).
2. **Corrections & Structured Field Claims**
   - When generated data (`spell:<id>`, `item:<id>`, `class:coa:<slug>`, `dbc:<Table>:<id>`, `path:<filepath>`) is incomplete, unproven, or differs from live Ascension behavior, attach a note with `field` and `value` set (e.g., `field: "procChance"`, `value: "15%"`) so conflicts and overrides render side-by-side.
   - Confirm whether an unproven main-list item (`item:<id>`) or client row actually exists on `coa`.
3. **Client & DBC Findings**
   - Newly verified unknown/guessed DBC columns (`dbc:<Table>`) or client file purposes (`path:<client/path>`).

### Strict Rules for Every Write
- **Check before writing:** Run `get` or `search` on the subject first so you do not duplicate an existing entry.
- **Author (`author`):** 1–64 characters using letters, digits, spaces, `.`, `_`, `-` (no leading/trailing spaces).
- **Trust level (`trust`):**
  - Use `observed` **only** when you have concrete proof. You **must** pass `evidence` with a `description` (what was tested/seen in-game, packet log, or sniff) or an `http(s)` `url`. Video URLs (`youtube.com`, `youtu.be`, `twitch.tv`, `vimeo.com`, `.mp4`, etc.) **require** a `timestamp` (e.g., `"1:23"` or `"83s"`) or `?t=` in the URL.
  - Use `memory` for unverified recall or working notes without hard proof.
  - Never claim `client`, `derived`, or `cache` (those are pipeline-only).
- **Subject ID (`subject`):**
  - Use an existing entity ID (`spell:133`, `item:10531`, `dbc:Spell:133`, `path:DBFilesClient/Spell.dbc`) to attach a note to generated data, **or** create a new lowercase `<type>:<slug>` (`[a-z0-9._:-]`) with `<type>` in: `npc`, `dungeon`, `encounter`, `mechanic`, `spell`, `item`, `class`, `quest`, `note`.
- **Entry kind (`kind`):** `observation`, `note`, `correction`, or `page`.
  - On generated IDs, any kind is automatically stored as a `note` beside the generated row (generated data is never overwritten).
  - On custom IDs, a new `page` supersedes the previous `page` while keeping history.
- **Realm (`realm`):** Set `coa`, `wotlk`, `octo`, `classic`, `s10` (comma-separated if multiple), or `unknown`. Never guess `coa` if the source does not prove it.
- **Positions (`position`):** Always approximate—pass `{ "map": "<MapName>", "x": ..., "y": ..., "z": ... }` (within ±100,000) or `{ "map": "<MapName>", "leftPct": ..., "topPct": ... }` (0–100).
- **Never write excluded or secret data:**
  - Never write the emulator's own `world` database rows as if they were Ascension facts.
  - Never write decompiled client/server code.
  - Never write private player or account data.
  - Never include tokens or credentials.
- **Fixing mistakes:** If you write a wrong or superseded claim, hide it immediately with `undo_entry(id, author)`.
