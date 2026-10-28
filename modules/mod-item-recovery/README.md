# mod-item-recovery

Extends the Ascension native Recovery Service; no replacement addon, NPC module or player GM permissions.

## Implemented source paths

- Vendored list: the existing 12 buyback items plus supported exact snapshots no longer in buyback.
- Deleted list: supported snapshots captured by explicit player deletion, including actual partial-stack quantities.
- Archive: newest 500 supported disposal records per character, persisted with the inventory/gold transaction. Enchants, socket enchants/gems, random-property fields, charges, binding, durability, creator and text are captured from native item fields. Restored items receive a fresh GUID and are mailed.
- Native/vendor buyback invalidates that sold item's snapshot with the inventory save. Owner/category checks, cached offer identity and a unique delivery receipt reject cross-character requests, replay and concurrent duplicate recovery transactions.
- Archived vendor recovery charges the recorded sale proceeds, preventing recovery for free; deleted recovery charges zero. These are reconstruction policies using existing buyback economics, not recovered historical Ascension archive fees.

## Deliberate limits

Legacy `recovery_item` records retain the core GM restore path and are not offered as exact snapshots. No missing historical properties or quantities are invented. Unsupported items include bags/containers, wrapped items, active refunds/trade windows, expiring/conjured items, temporary enchants, instance-scaled items and generated-loot containers. Special external item-instance state is not reconstructed by the native field snapshot; Worldforged refunds and other specialized services remain outside this implementation. Exactness is limited to the native fields and text recorded here, not arbitrary module-owned tables.

Disenchanted/recycled items, deleted characters, Worldforged refunds and Wildcard roll recovery are not implemented by this change. Reversing material-producing actions needs an independently verified output-repayment contract to prevent duplication. The new native Deleted Items category visibility and packet behavior still require real-client acceptance; no unverified client-config key was invented.

## Configuration and SQL

`ItemRecovery.Enable = 1` keeps the existing service enabled. `ItemRecovery.Archive.Enable = 1` additionally captures supported future events (default true). The archive is independent of the legacy `ItemDelete.*` logging thresholds. Deploy pending character migration `rev_20261028_02_exact_item_recovery.sql` through the normal updater before using the new binary. No world NPC migration is needed for the existing window. Existing local `.conf` files were not edited.

## Verification

Source/formatting review only. Compilation, native UI visibility, packet exchange, transaction failure/replay, restart persistence and actual mail/property preservation remain runtime-unverified. Do not label this implementation live-qualified until those checks pass.
