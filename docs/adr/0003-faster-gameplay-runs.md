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
  196.6 s with 1. Every one of the 627 copied tables had the same `SHOW CREATE TABLE` as its source,
  `AUTO_INCREMENT` included; the world copy had the same `CHECKSUM TABLE ... EXTENDED` values and the same
  `world_fingerprint`.
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

## Parallel simulated servers

### Context

Exclusive cases (real-spawn dungeons, raid boss encounters with `encounter_start` since #9116) run alone on their
worldserver, and the simulated clock ran a single worldserver, so they ran one after another: the four vanilla
dungeon scenarios took a median 171.6 s on the stock disk MySQL above. `batch.py` and `verify_all.py` rejected more
than one simulated server since #5108, which records "run all scenarios in one worldserver instead of several" as a
maintainer correction but no technical reason. The state that makes a case exclusive (Who list, live creatures, game
events, the encounter recorder, the realm clock) belongs to one process, and every server already has its own
process, port, auth/characters schemas and world-cache slot, as several real-clock servers do.

The first parallel runs exposed a limit the servers share: each simulated server with the default 16 character
database workers prepared about 7,700 statements, and MySQL's default `max_prepared_stmt_count` is 16382. With four
servers requested, the servers beyond two failed to start, the batch still passed on two servers, and the failed
slots copied their world again on every run.

### Considered options

1. Keep one simulated server.
2. Allow `--gameplay-jobs N` on the simulated clock (default 1), fail the batch when one of several simulated
   servers exits before readiness, name `max_prepared_stmt_count` when its error log shows that limit, and document
   the remedies.
3. Option 2 plus a preflight that compares `max_prepared_stmt_count` with an estimated per-server statement count.
4. Option 2 plus lowering the character database workers automatically when several servers run.

### Decision

Option 2. The servers take cases from one queue; a server holding an exclusive case takes no other, and a busy
server leaves the next exclusive case to an idle one. Real-pace diagnostics wait until every accelerated case of
every server has a result. Ports are never reused within a batch. One server stays the default, and the
`gameplay_jobs` setting still applies only to the real clock.

Option 1 leaves exclusive cases serial. Option 3 needs a hard-coded statement count that drifts with the code and the
worker setting. Option 4 changes how character writes are ordered compared with a one-server run, which is what the
parallel run is compared against.

### Consequences

- With `max_prepared_stmt_count` raised to 65528 on that MySQL, `--gameplay-jobs 4` ran the four dungeons in a
  median 122.6 s (110.3-138.0 s) against 171.6 s serially, with the same verdicts; every assertion value also
  appeared in a serial run. Four servers held 30,824 prepared statements and up to 16.0 GB RSS together; one server
  peaked at 5.1 GB. These are measurements from one workstation, not guarantees.
- A stock MySQL with no other client fits two simulated servers, and fewer when a running worldserver or authserver
  shares it; more fail the batch with a message naming `max_prepared_stmt_count` and its remedies: raise the limit
  or lower `--gameplay-db-workers`.
- A server that dies before its startup barrier still loses its slot's world copy: the SQL updater may have changed
  it, and no baseline exists to audit it. The next run copies it again.
- Each extra server needs another world copy on first use of its slot, and memory for one more worldserver.

## Optional in-RAM test database

A throwaway MySQL whose data directory is a tmpfs cut cold runs from 378.4 s to 91.3 s in the "before" measurements
(see [the guide](../coa/verification.md#optional-in-ram-test-database)). It is documented, not required: it needs
several GB of RAM, loses its data when the container stops and drops durability settings that a shared or
long-lived server must keep. The standard route stays the reference, and nothing in the runner depends on the
optional one.
