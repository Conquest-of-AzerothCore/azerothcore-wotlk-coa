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

Deleted Characters now uses the original native service (0x05DA–0x05DD) to restore retained soft-deleted characters belonging to the requesting account. Restoration is free, requires an available original name and account/realm character slots, rejects stale deletion IDs, and refreshes the character cache after commit. It does not recreate purged characters or bypass character bans.

Disenchanted/recycled items and Wildcard roll recovery remain unsupported. A limited native Worldforged campaign exchange is now available in source; it is disabled until reviewed campaign data is authored and installed. Reversing material-producing actions needs an independently verified output-repayment contract to prevent duplication. The new native Deleted Items category visibility and packet behavior still require real-client acceptance; no unverified client-config key was invented.

## Configuration and SQL

`ItemRecovery.Enable = 1` keeps the existing service enabled. `ItemRecovery.Archive.Enable = 1` additionally captures supported future events (default true). The archive is independent of the legacy `ItemDelete.*` logging thresholds. Deploy pending character migration `rev_20261028_02_exact_item_recovery.sql` through the normal updater before using the new binary. No world NPC migration is needed for the existing window. Existing local `.conf` files were not edited.

## Verification

Source/formatting review only. Compilation, native UI visibility, packet exchange, transaction failure/replay, restart persistence and actual mail/property preservation remain runtime-unverified. Do not label this implementation live-qualified until those checks pass.

`ItemRecovery.Characters.Enable = 1` enables the independent Deleted Characters category under the main switch. `CharDelete.Method = 1`, `CharDelete.MinLevel` and `CharDelete.KeepDays` govern future retention. Existing local configuration files are unchanged. No migration is required for character restoration.

## Worldforged refund campaigns

`ItemRecovery.Worldforged.Enable` defaults to `0`. Install both pending `rev_20261029_01_recovery_worldforged_*` migrations through the normal updater and author reviewed `recovery_worldforged_offer` rows before enabling it. The client flag is true only while a valid configured offer is active. No historical campaigns, item IDs, refund percentages, prices or universal 14-day lifetime are seeded. The world table is the eligibility authority, not the current upgrade recipe or original-purchase inference.

Each row names one required item, one refunded item, the exact Runes of Ascension refund (375250), and explicit start/end timestamps. The verified installed DLL supports that rune refund directly; arbitrary token/item refund maps are not implemented. Terms are included in the cached record ID and checked again on recovery. Use a new offer ID for a new campaign rather than repurposing historical IDs.

Only saved, unequipped weapon/armor instances in the character's bags qualify. Newly received/moved items wait until their normal inventory save. Enchants/gems, random properties, creator/text data, changed charges, damage, expiring/refundable/tradable/instance-scaled or loot-generated state are excluded rather than silently lost. Soulbinding is retained on the replacement. This is a restricted downgrade exchange, not exact restoration of a previous base instance.

The exact owned persisted input is required and locked by the receipt insertion within the same transaction as item consumption and mail creation. Missing/stale inputs and duplicate receipts abort the transaction. Input inventory is changed in memory only after commit; failure leaves it untouched. The receipt retains offer terms, consumed GUID, recipient and mail identity. Refund delivery uses the existing staged-mail path. Runtime crash/replay/property checks remain pending.
