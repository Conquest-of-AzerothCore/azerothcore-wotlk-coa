# CoA world data tools

Import and check the [CoA world database package](../../data/coa-world/README.md).
The package contains world templates, reference data, and migration metadata.

## Install

The worldserver and `dbimport` install the package automatically. When `Updates.AutoSetup` finds the
world database empty, they verify `baseline.json`, the archive and every table checksum, then import
the tables with the migration ledger last instead of `data/sql/base/db_world/`. The normal updater then
applies the migrations the package does not cover. A failed import leaves a partial schema; drop it
before restarting.

To import the package without the server, use Python 3.11 or newer and a MySQL 8 client/server.
Create an empty world schema, then import the package **before the first worldserver startup**:

```sh
python apps/coa-world/world_data.py verify
python apps/coa-world/world_data.py bootstrap --defaults-file /path/to/world-client.cnf --database acore_world
```

The client option file supplies the connection settings. Use `--mysql /path/to/mysql`
if the client is not on PATH, and `--database` to select the world schema.
Set worldserver's `SourceDirectory` to this checkout.

Bootstrap verifies the package and imported content, and requires an empty schema.
If an import fails, recreate that partially imported schema before retrying.
Subsequent SQL migrations use the normal server updater.

## Audit

Compare an existing world database with the package without changing it:

```sh
python apps/coa-world/world_data.py audit --defaults-file /path/to/world-client.cnf --database acore_world
```

The report identifies missing tables, schema differences, changed content, and additional
tables. Later migrations and local customizations can produce expected differences.
Updater history and server-version metadata are excluded from the comparison.

## Update the package

Add content changes through `data/sql/updates/pending_db_world/` migrations.
To refresh the package, use `export_baseline.py` with a gzip SQL snapshot containing
`acore_world` and an isolated import of that database. Run `python apps/coa-world/export_baseline.py --help`
for the required arguments.

Verify the new package and import it into an empty test schema before committing the
archive and `baseline.json` together.

## Checks

```sh
python apps/coa-world/test_world_data.py
python apps/coa-world/test_mysql.py --mysql-bin /path/to/mysql/bin
```

The MySQL check creates a temporary database server with TCP disabled, verifies the
import and migration handling, and compares the package with the repository SQL.
