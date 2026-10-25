# 0003. Faster gameplay runs

- Status: accepted
- Date: 2026-10-25

## Context

Every gameplay worldserver needs isolated copies of the source databases: a world copy for each world-cache slot
on first use (and on every `--refresh-world` or `--fresh-databases` run), and auth/characters schemas for every
worldserver. `Databases.copy` in `apps/coa-gameplay-test/run.py` piped `mysqldump` into `mysql`: one client process
serialized every row to SQL text and a second parsed it back, one table at a time.

On a stock MySQL 8.4 on disk (binary log on, `sync_binlog=1`, `innodb_flush_log_at_trx_commit=1`), a run that
refreshed the 409-table world cache spent a median 310.7 s preparing databases against 47.2 s for a run that
reused it. The world copy was most of the difference.

## Considered options

1. Keep `mysqldump | mysql`.
2. Run several `mysqldump | mysql` pipelines, one per group of tables.
3. Copy inside MySQL: recreate each table, then `INSERT INTO copy.t SELECT ... FROM source.t`, with several
   connections in parallel.
4. Copy InnoDB tablespaces (`FLUSH TABLES ... FOR EXPORT` and `ALTER TABLE ... IMPORT TABLESPACE`).

## Decision

Option 3. For each base table the runner reads `SHOW CREATE TABLE` from the source and runs it in the copy, then
copies the rows with `INSERT ... SELECT`, naming every non-generated column. Tables are distributed largest first
over `--copy-workers` connections (1-32, default `min(8, CPU count)`, verify_all setting `gameplay_copy_workers`).
Each statement runs with mysqldump's `sql_mode` (`NO_AUTO_VALUE_ON_ZERO`), foreign key checks off and
READ-COMMITTED isolation. A source schema with views, triggers, routines or events, or a server with statement-based
binary logging, is copied with the existing `mysqldump | mysql` pipeline, and the run log names the reason.

`CREATE TABLE ... LIKE` was the first choice for the table definitions, but MySQL 8.4 drops foreign keys with it
(`acore_world.creature_sparring` loses `creature_sparring_ibfk_1`; auth and characters have nine more), and it
resets the `AUTO_INCREMENT` counter. Replaying `SHOW CREATE TABLE` is what mysqldump itself does, so definitions stay
identical. Under REPEATABLE-READ, `INSERT ... SELECT` takes shared locks on every source row it reads (6,103 record
locks for `creature_formations` in a probe); READ-COMMITTED reads without row locks, as the dump did. MySQL rejects
InnoDB writes at READ-COMMITTED under statement-based binary logging, hence that fallback.

Option 2 keeps the text round trip, and its cost grows with the number of client processes. Option 4 needs file
access to the server's data directory and per-table locks on the source, which a loopback client does not have.

## Consequences

- On the stock disk MySQL above, preparing all three schemas for a fresh run took 71.2 s with 8 workers and
  196.6 s with 1. Every one
  of the 627 copied tables had the same `SHOW CREATE TABLE` as its source, `AUTO_INCREMENT` included; the world
  copy had the same `CHECKSUM TABLE ... EXTENDED` values and the same `world_fingerprint`.
- A run that refreshes the world cache on that server spent 102.9 s and 119.2 s preparing databases in two runs,
  against the 310.7 s median before. That time still includes two source checksums and the drop of the old cache.
- Each table is copied in its own statement, so the copy is not one consistent snapshot of the source, unlike
  `mysqldump --single-transaction`. The world cache already fingerprints the source again after the copy and
  rejects a change; a fresh-mode copy does not detect source writes made during the copy.
- More connections mean more concurrent I/O on the MySQL server; `gameplay_copy_workers` lowers it, and 1 copies
  one table at a time.
- A failed statement stops the remaining tables, waits for the running ones and raises; the existing cleanup drops
  the partial schema and the world cache never reaches `ready`.
- `mysqldump` stays a prerequisite for the fallback.
