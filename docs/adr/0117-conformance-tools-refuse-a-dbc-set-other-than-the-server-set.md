# 0117. Conformance tools refuse a DBC set other than the server set

- Status: accepted
- Date: 2026-11-11

## Context

Expected values come from the DBC set the worldserver loads, `/srv/coa/server-data/dbc` (`profile.DBC_DIR`), the
set `coa-verify` mounts for the server. A class file's `dbc_dir` and `scaffold --dbc-dir` could still point the
tools at another set, such as a client snapshot whose `Spell.dbc` differs, and nothing in a manifest or a verdict
file said which set its expectations came from. The clause-spec prototype added a guard (commit f48d2c8189); ADR
0116 carries it over.

## Considered options

1. Compare paths. Rejected: a copy of the server set at another path is the same data, and a path says nothing
   about a file replaced in place.
2. Hash `Spell.dbc` and refuse any set whose hash differs from the server set's. Chosen: `Spell.dbc` holds the
   values the tooltips read and the server applies.

## Decision

- `profile.spell_dbc_sha256(dbc_dir)` hashes a set's `Spell.dbc` (cached on size and mtime); `server_dbc_dir` and
  `require_server_sha` raise `DbcSetMismatch` for a set whose sha differs from `DBC_DIR`'s.
- `load_class_file` applies the guard to a class file's `dbc_dir`; `generate`, `sheets` and `scaffold --dbc-dir`
  to the set they read. `generate` records `spell_dbc_sha256` in the manifest; `compare` refuses a manifest whose
  recorded sha is not the server set's and copies it into `verdicts.json`.

## Consequences

- A manifest generated before this change carries no sha and is still compared.
- Every generated manifest gains one field; scenarios do not change.
- A server set replaced in place makes every earlier manifest refused by `compare`; such a manifest must be
  generated again.
