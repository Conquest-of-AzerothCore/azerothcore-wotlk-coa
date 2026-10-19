# mod-worldforged-upgrades

The Guardian of Time and his two custom stores: trade a Worldforged item plus
Runes of Ascension for its next rank. The window is the client's own
`RPGItemStore`, spoken over the Ascension custom-store protocol — no client
patch involved.

## Layout

```
conf/worldforged_upgrades.conf.dist   CostFactor and friends
data/sql/db-world/base/               enUS data, applied on a fresh install
data/sql/db-world/2026_10_19_*.sql    locale + string migrations
src/WorldforgedUpgrades.h             constants, protocol ids, string ids
src/WorldforgedGuardian.cpp           the Guardian's gossip menu
src/WorldforgedStore.cpp              the custom-store protocol, server side
src/WorldforgedUnlock.cpp             account-wide tier unlocks
src/worldforged_loader.cpp            script registration
```

## Multi-language (i18n)

Every string the player can read lives in the world database, not in the code.
The pattern is mod-transmog's:

| layer | where | what |
|---|---|---|
| id | `WorldforgedStrings` enum in `src/WorldforgedUpgrades.h` | a plain `uint32`, e.g. `LANG_WORLDFORGED_PURCHASE_NO_CURRENCY = 10` |
| English | `module_string` row `('mod-worldforged-upgrades', 10, '...')` | the fallback for every locale |
| translations | `module_string_locale` rows `('mod-worldforged-upgrades', 10, 'zhCN', '...')` | one row per locale |

At runtime `ChatHandler::PGetParseModuleString` asks `WorldSession` for the
string, and the session answers with the row for **the player's own client
locale** (`GetSessionDbLocaleIndex`). No recompile, no restart beyond the
normal `.reload` cycle; a missing row logs a `sql.sql` error and shows the
literal text `error`, so the SQL migrations must be applied.

Supported locales (same set as the core): `koKR frFR deDE zhCN zhTW esES esMX
ruRU`, with `enUS` as the base.

Two things deliberately do **not** go through this system:

* `RESULT_QUERY_OK` / `RESULT_PURCHASE_OK` — the client compares these two
  against fixed English text, so translating them would break the protocol.
* The class names in the scroll-store menu — they come from `ChrClasses.dbc`
  in the player's locale, which is where every other class name in the game
  comes from.

### Adding a string

1. Append a new enumerator to `WorldforgedStrings` — never reorder, the ids
   are rows in the database.
2. Use it: `ChatHandler(session).PSendModuleSysMessage(Worldforged::MODULE_NAME, id)`
   or, when the text needs arguments, `PGetParseModuleString` with `{}`
   placeholders.
3. Add the rows to `data/sql/db-world/` as a new dated migration, English in
   `module_string` and each translation in `module_string_locale`.

### Database texts

The Guardian's own name, subname and gossip greeting are database rows, so
they are localized the way the core localizes every creature:
`creature_template_locale` (name/subname) and `npc_text_locale` (greeting).
The enUS originals stay in `base/02_worldforged_guardian.sql`.
