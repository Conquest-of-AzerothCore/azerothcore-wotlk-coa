# Featured catalog operation

After the combined package is separately authorized and activated, a GM edits a Featured Build, chooses its vanity rewards, and saves it to the server. The selected Featured revision is authoritative. No GitHub token is exposed in the editor.

The local Windows task `Area52 Featured Catalog` checks once a minute while the owning Windows user is signed in. It launches the existing WSL tooling, then uses the Windows-validated TLS and GitHub credentials already used for launcher releases. The task is registered only after initial package publication succeeds. No service, task or worker is started during preparation or CheckOnly. This local-host arrangement must be adapted separately when the tester realm moves to the VPS.

The worker publishes only the four approved catalog members inside patch-E: CharacterCreationArchetypeDetails.dbc, ItemSet.dbc, VanityCollection.dbc and CharacterCreate.lua. The editor UI is installed by the initial package. There are no DLL or launcher executable changes. Catalog refreshes preserve existing patch notes and send no Discord announcements. The initial package has the usual separate publication announcement.

Player launchers receive changes on their next update; an already-running game does not reload its DBC catalogs. Mounts appear as assigned rewards, not as a mounted Character Creation scene. Incarnation scene updates require the archetype's existing form category; unsupported scene mappings stop export rather than guess.

The runtime is `C:/Users/danie/Documents/Codex/area52-featured-catalog-runtime`. Its `outbox/delivery-state.json` identifies pending/completed jobs; immutable job folders contain sealed publication inputs. `outbox/transactions/<job>/publication/client-release.json` and the feed intent journal retain publication receipts. Failed runs retain these files and resume the same job. Do not delete a pending job or its receipt to retry it.

The worker rejects unrelated launcher-feed drift and shares a publication lock with package releases using the updated publisher. A later general client release requires reconciliation of the worker baseline before catalog publication resumes. Curated default DBC/Lua inputs remain separate from the last published manifest; do not replace defaults with generated catalogs.

To pause automatic catalog delivery, disable the Windows scheduled task. This does not change the server's saved builds or player collections. A future deployment should preserve the outbox and reconcile the existing task/runtime rather than overwrite them.
