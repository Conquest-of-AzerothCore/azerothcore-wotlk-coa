# mod-coa-qol

Raises the stack size of profession materials. Configure it in `conf/mod-coa-qol.conf.dist`.

At worldserver startup the module raises the stack limit of selected item templates in memory. Nothing
in `item_template` is modified, so disabling the module or the option restores the database values on the
next start.

- Default: every stackable Trade Goods item (item class 7) stacks to 2000. Set
  `CoAQol.StackSize.Materials = 200` for the smaller limit.
- Stack limits only rise. Non-stackable items, unlimited items and items that already stack higher are
  untouched, so an `item_template` value above the configured size wins.
- `CoAQol.StackSize.ItemClasses` picks more classes (for example `"3,7"` adds gems);
  `IncludedItems` and `ExcludedItems` override by item ID, and exclusion wins.
- The limit is applied once at startup, so changing it needs a restart. Stacks that already exist stay
  as they are if the limit is lowered later.
- The client caches item data. Clear its Cache folder after the first start with the module and after
  any change, or the old limit is still shown and enforced in the interface.

Every stack path reads the template through `ItemTemplate::GetMaxStackSize`, so bags, bank, mail, auction,
trade and the personal bank follow the new limit without further changes.

## Verification

`python3 -B tools/verify_all.py --stages source,build,unit --base origin/main`. Reconfigure the build
directory first so CMake discovers the module and its unit tests. Unit tests cover list parsing and stack
planning. They do not replace an in-game check: start with the module, clear the client cache, and loot or
buy a stack of ore past 20, then mail, trade and bank it.
