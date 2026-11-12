# Expected-behavior sources

Use these, in order, to establish what a spell, talent, item or class is meant to do and to find data the server
lacks. The installed DBC, DB and code win when they have the value; a differing snapshot is a finding to report.
All community sources are snapshots, not the live server.

1. **The tooltip** in the installed client data (`apps/coa-dbc` viewer, `.agents/docs/systems/ascension-spell-parity.md`
   for how tooltip variables resolve).
2. **https://ascensionsidekick.com/** — `https://ascensionsidekick.com/data.js` (`window.ASC.coaKits[class]
   .specs[].abilities[]`: name, level, talent flag, description without numbers or IDs; `coaGuide`/`coaSkill`).
3. **https://bindmysoul.com/** — `https://bindmysoul.com/conquest/talents.normalized.json` holds every CoA talent
   node with `spellId`, full tooltip text with numbers, tree kind, required level, point costs and dependencies
   (snapshot `metadata.fetchedAt` 2026-07-22). Its spec IDs differ from the server's `.localspec` IDs: match on
   `spellId`.
4. **CoA Knowledge MCP** (`coa-knowledge`) — provenance-tagged facts per realm; see [knowledge-mcp](knowledge-mcp.md).
   Agent-written entries are self-declared data, not proof. Its Spell.dbc layer was built from a client whose
   Spell.dbc equals the server's, so its spell values are a second reading of our own data and add no independent
   weight.
5. **https://github.com/hertigservices/ascension-data** — `supplemental/exiles-db-export/` (2026-09-13 export of
   the db.exil.es CoA database: spells, creatures, spawns, loot; `SCHEMA_REFERENCE.md`), `datasets/cache.json`
   (captured WDB caches), `supplemental/coa-databank/` (talent scrapes). Search it by name or ID at
   https://ascension-db.ascension-archive.workers.dev/. Client protocol:
   https://github.com/hertigservices/Ascension_preservation (`reference/ascension_custom_opcodes.json`,
   `docs/WIRE-SPEC.md`).
6. **The user** — when the sources above disagree or are silent, ask instead of guessing.

A value taken from a snapshot names its source and snapshot date in the commit and PR, and the user approves the
choice first (in auto mode: see [batch-scheduling](batch-scheduling.md), Decisions in auto mode).

## Class conformance work

Class conformance work ([guide](../../../../docs/coa/class-conformance.md), section 4) uses its own trust order: server
data and owner rulings, then live captures, then official pages, then fan-written notes. It searches these references
first and cites what it found, or "nothing found". A doubtful case goes to the mentor session when one is set up, and
otherwise to the owner as a question ([rulings](../../../../docs/coa/class-conformance-rulings.md), G-11, G-40 and
G-42).

## Obtainability

This fork is a reconstruction: a missing acquisition row is exactly what lost server data looks like, so its own
database cannot prove a spell is unobtainable. Use calibrated outside captures (the guide's `coa-obtainable`, see
[guide-tooling](guide-tooling.md)) and never report a bare absence. The same comparison finds spells the live
capture offers that `CharacterAdvancement.dbc` lacks, which are real gaps worth their own report.
