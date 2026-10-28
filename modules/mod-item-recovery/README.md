# mod-item-recovery

Answers the Ascension client's **Item Recovery** window (opcodes `0x5DE`/`0x5E0`) from the character's
twelve native vendor buyback slots.

- At login the client is told the recovery window is available (`CONFIG_RECOVERY_VENDORED_ITEM_ENABLED`).
- The window lists the buyback slots: item, count, sale time and the price the vendor paid.
- Recovering an entry buys back that exact item instance for that price, in one character save, and
  refreshes the list. Stale, mismatched, unaffordable and full-bag requests are refused with the client's
  own result codes (`VENDORED_ITEM_RECOVERY_*`).

The historical service's longer archive of sold and deleted items, and its fees, are not restored.

## Configuration

`conf/item_recovery.conf.dist`: `ItemRecovery.Enable` (default `1`).
