# Native exact-item recovery: deleted and vendored items

Before, Recovery Service exposed only current vendor buyback slots. New source extends the same module/window with owner-scoped snapshots of supported future deletion/sale events. Snapshots preserve recorded native item fields/text, including enchantments, gems and random properties, rather than regenerating plain items from legacy entry/count rows. Newest 500 records are retained per character. Sold records are hidden while their original item remains in buyback and invalidated when bought back. Archive delivery uses a unique receipt, mail and price debit in one character transaction; responses publish only after successful commit.

Policy: archived vendor items repay their original sale price, deleted items are free; no claim of historical Ascension archive fees. Legacy basic rows stay GM-reviewed. Expiring items/temporary enchants, wrapped, refundable/tradeable, loot-bearing, instance-scaled and container items are excluded. Specialized module-owned item state and disenchant/recycling/refund/character/Wildcard restoration remain unsupported.

Pending character migration: rev_20261028_02_exact_item_recovery.sql. No SQL applied and no local config changed. Requires compilation, updater deployment and native-client acceptance before live use; source/static checks do not verify gameplay or mail delivery.

Advertise deleted-item recovery through the original client CONFIG_RECOVERY_DELETED_ITEM_ENABLED flag when recovery/archive are enabled. Previously the implemented deleted-item request handlers remained inaccessible because the UI disabled that category. Emit explicit false flags when disabled. Native UI/recovery runtime acceptance remains pending.

Route deleted-item query/recover opcodes through the compatibility filter to the recovery module. Previously the generic extension sink discarded them, leaving the native UI loading indefinitely.

Keep Deleted and Vendored offer caches separate, matching client category caching. Previously switching categories could invalidate an unchanged recovery selection. Refresh the affected list after failed as well as successful recovery requests while retaining strict ownership/ID/duplicate checks.

Allow recorded partial-stack deletions to recover their deleted quantity while the remaining stack still exists. Original-item inventory/buyback exclusions apply to vendored recovery; deleted snapshots retain owner/source checks, atomically saved deletion quantities and unique transactional recovery receipts. Runtime replay and property-preservation acceptance remains pending.
