# CoA world database package

The SQL archive contains world templates, reference data, and migration metadata.
`baseline.json` identifies the archive and records its checksums, table schemas,
content fingerprints, and covered migrations.

The worldserver and `dbimport` import the package into an empty world database during
`Updates.AutoSetup`. See the [world data tools](../../apps/coa-world/README.md) for the manual import,
auditing, and package updates.
