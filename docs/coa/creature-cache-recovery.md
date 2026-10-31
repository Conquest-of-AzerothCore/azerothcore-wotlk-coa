# Selective creature-cache recovery

A stale creature query can prevent automatic enemy targeting even when clicking the
creature works. One confirmed case cached Rumbling Earth-Heart (22313) as Critter
(type 8, flags 0), while the realm template correctly contained Elemental (type 4,
flags 512). The client excludes Critters from automatic enemy selection.

Check the realm's current creature template and query response before invalidating
the cache. This tool repairs a reviewed local cache discrepancy; it does not correct
bad server data or establish how the old cache was produced. Do not change creature
factions or shared targeting rules to compensate for stale client metadata.

Close the client and identify the cache for the affected realm. The path varies by
client; do not assume the top-level cache is the realm-specific file. Preview:

```powershell
python tools/repair_creature_cache.py --cache "PATH\creaturecache.wdb" --entry 22313 --expected-type 8 --expected-flags 0
```

Review the output, then repeat with `--apply`. Inspection is read-only by default.
Apply is Windows-only and refuses to proceed while Ascension or WoW is running.
Clients using another executable name must not use apply; their closure is not
covered by this tool's process check.

The tool checks the WDB header, record boundaries, duplicate IDs and expected
metadata. It removes only the selected record, preserving the other records and
header verbatim. A missing entry is a no-op; different metadata is rejected. Apply
creates and verifies a uniquely named backup beside the cache, checks for concurrent
changes, replaces the file atomically and verifies readback. The client requests the
missing record from the server when needed on the next session. No server restart,
SQL migration, launcher release or server activation is involved.

Keep the backup until targeting is checked in game. If recovery is needed, close the
client, preserve its current cache separately and restore the backup to the original
filename. Restoring it also restores the stale entry. Never publish personal caches
or backups in Git, PR attachments or shared client distributions.

Offline verification uses synthetic records only:

```text
python -B tools/verify_all.py --stages harness --harness test_repair_creature_cache
python -B tools/verify_all.py --stages source --base origin/main
```

These checks cover selective preservation, retry, backups, malformed/changed input,
open-client refusal, concurrent edits and replacement failure. They do not claim
in-game acceptance or verify the server's live response.
