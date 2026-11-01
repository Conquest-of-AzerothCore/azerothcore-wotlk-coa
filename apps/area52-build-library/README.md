# Area 52 Shared Build Library worker

This directory owns the realm-side integration for the [public Build Architect Library](https://github.com/CWO4PapaBear/Area-52-Build-Architect-Library). Public builds and portable codecs remain in that repository. `portable/` is a pinned Git submodule; it is a dependency, not a second independently maintained codec.

## Source setup and verification

```sh
git submodule update --init -- apps/area52-build-library/portable
python -B tools/verify_all.py --stages source,harness --base origin/main --harness area52-build-library-worker
```

The harness runs worker tests and the pinned portable tests without network access, database access, service management, publication or gameplay. It covers catalog drift, safe GitHub commit intents/readback, ingestion, private status notifications and no duplicate sends. The native validator and slot fixture under `native/` use actual CoA sources and require a separately qualified catalog build; Python tests alone do not qualify native rules.

## Required realm integration

The server's `main` at the split base predates the currently deployed Area 52 outbox and positional Mystic Enchant slot implementation. Adding these tools does **not** make that older server tree an equivalent deployment. The receiving realm must already provide authenticated `A52LIB` requests, `area52_library_publication` and refresh/import tables, the native build codec, and `ArrangeSlots`/positional `ValidateSlots`. This change relocates and preserves the existing worker; it does not merge unrelated gameplay packages or install a service.

Build `native/catalog_validator.cpp` against the selected server revision's `AscensionFreePickRules.cpp`, `AscensionMysticEnchantCatalog.cpp` and `ClientDBC.cpp`, with its matching headers and the existing `coa_talent_catalog.STUBS` bounded data-store adapters. Use the existing offline verification runner and compiler. Qualify `native/slot_fixture.cpp`, actual DBC loading, and representative saved wire records, then create the private `catalog-data.json` with hashes for the executable, each DBC, effective DBC source, and every native source/header input. Do not copy another realm's manifest or check binaries/DBCs into Git.

The November 1 helper repair calls `ArrangeSlots` before `ValidateSlots`, matching the active grant path. Valid serialized enchant ordering must not cause rejection; excessive legendary/epic slots, stacks, level violations and missing ownership remain rejected. Requalify the helper and manifest together whenever pinned native rules or data change. Never refresh hashes alone to bypass drift.

## Runtime layout

Deploy a reviewed copy of this directory outside the source checkout, keeping `tools/`, `native/` and `portable/tools/` at their relative locations. Runtime needs only the two portable Python modules, at the pinned revision. Keep executable/catalog data, queue, token and configuration private and outside Git. No default credentials or installation-specific configuration is supplied.

`tools/worker_service.py --config /private/worker.json --check` checks current hashes and read-only GitHub access. Add `--offline` to omit GitHub access. Neither form starts a worker or publishes. Starting the service without `--check` may process existing consented requests, and requires separate deployment/publication authorization.

The configuration requires `schema: 1`, `publication_enabled`, `poll_seconds` (5–300), a stable installation UUID, `state_directory`, `realm_container` (database container), `token_file`, `catalog_manifest`, `validator`, and `catalog_directory`. Optional `notification_since` is a database timestamp used to avoid notifying historical requests when enabling alerts. Preserve the existing installation UUID, state directory, outbox rows and SQLite bindings when relocating; changing them can lose deduplication identity.

The current Area 52 private-notification adapter uses the existing private Remote GM credential file and the `ascension-freepick-worldserver` network namespace. Configure/review those deployment-specific paths before using another realm. Messages go only to the requesting account's online characters. Notification receipts are reserved before sending; an uncertain send is not repeated automatically. Offline recipients remain pending. Notification failure does not roll back successful publication.

## Recovery and publication

Catalog drift pauses before ingestion and also remains recoverable if detected during validation. Request identity and consent survive. GitHub writes save commit intent before advancing a non-forced ref; uncertain outcomes perform readback rather than another write. Verify the authored commit and current descendant file hashes before reporting success. Do not requeue a build to recover a transport or catalog failure.

The November 1 recovery requalified the helper, retained Mystic Knight's original request, and verified one public revision. Worker repairs include current slot arrangement, startup and mid-ingestion drift handling, private failure/completion alerts, and durable notification receipts. The repository split itself performs no deployment, client update, realm restart, SQL write, service restart or publication of player content.
