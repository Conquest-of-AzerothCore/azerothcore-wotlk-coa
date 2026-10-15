# CoA Legendary Items

64 original non-set leveling legendaries: three per custom class (IDs 12–32), plus a shared cloak.
See the [interactive preview](preview.html) or the [complete catalog](CATALOG.md).

Eligible creature kills have a configurable 0.5% chance to add one legendary to normal corpse loot.
The loot owner determines the class pool. Normal group loot rules apply. Pets can earn a drop for their owner;
player-owned creatures, critters, totems, creatures without XP eligibility and gray creatures cannot drop one.
Players at level 60 or above receive no new drops by default. Previously earned equipment keeps working.

Required level is `creature->getLevelForTarget(lootOwner)`, the same per-player level used by Destiny Weaver.
Item level is always required level + 12. A level-32 player killing a wolf scaled from 10 to 29 receives a
level-29, item-level-41 variant. Without scaling, that gray level-10 wolf is ineligible. Normal and quest loot
continue through their existing paths. Each design has level-1 through level-60 variants with fixed stats;
equipping one does not increase its level.

Movement powers are exclusive to boots. Boots use cloth armor and class-specific stats, allowing their intended
class to equip even the earliest variants. Equipment, durability, combat and committed health changes update
powers immediately. Login and resurrection restore eligible equipped powers; unequipping, breaking an item,
death or disabling an active module removes them. Configuration changes are reconciled on the next player update.
After-kill powers require a non-gray creature kill and use visible native eight-second buffs with normal
duration refresh and expiry. Other powers remain hidden passives. No periodic condition or equipment scan runs.
Only the strongest equipped copy of a design grants its power. Movement uses native aura speed stacking rules.
Signature trinkets use native percentage spell modifiers to boost the named ability's main direct hit by 12%,
across its native rank chain, and send the corresponding client modifier updates. Client selector tags and
server rank-chain targeting keep secondary triggered spells, periodic effects and unrelated abilities unchanged.
The tags are applied only to outgoing client records, preserving server metadata used by existing class scripts.
Rank targeting is implemented by the module through a generic spell-modifier hook.
Startup validation checks the selectors against effective spell data and existing modifier masks.

## Integration

The module is discovered automatically by CMake and disabled by default. Set
`CoALegendaryItems.Enable=1` in `conf/mod-coa-legendary-items.conf` and restart to enable its scripts and patches.
Enabling after starting with it disabled requires a restart. Reloading an active module with `Enable=0` removes
its powers and prevents subsequent item and spell patches, including patches for new logins.
Its configuration template is `conf/mod-coa-legendary-items.conf.dist`. To exclude it, configure with
`-DMODULE_MOD-COA-LEGENDARY-ITEMS=disabled`.

The module's `data/sql/db-world/rev_20261004_01_coa_legendary_items.sql` supplies 5,120 item templates,
3,840 client item rows and 64 native power spells. The normal worldserver updater applies it only when the module
is built, including when its runtime option is disabled. Core's one-time cleanup migration removes client rows
and power spells installed by the former shared migrations while preserving item templates for saved inventory.
The module migration runs afterwards under a new name and hash,
so an existing migration ledger cannot mistake it for a rename and skip reinstalling the data.
Historical level-61 through level-80 item templates remain in the module for saved-item compatibility;
only level-1 through level-60 variants have client rows and can drop or grant powers.
Excluding the module from a fresh build installs none of its data. After a module has been installed, its data
can remain in the database when it is excluded; its drop and power scripts are absent and patches are not registered.
Excluding it during the first upgrade from shared migrations preserves legacy item templates for saved inventory
while removing their client rows and power spells. Keeping it built with `Enable=0` also retains module data
while disabling drops and powers.
The module validates its item and spell records at startup and disables drops and powers if they are incomplete.

`AscensionCompat` already streams `item_dbc` through `SMSG_PATCH_ITEM` (`0x0932`, eight 32-bit fields).
The enabled module explicitly registers its variants and power spells with the shared patch registries.
SQL-only item rows require registration; core registers its Heartwood Key independently. Server-only SQL spells
are streamed only for description overrides or explicit registrations. All variants use on-demand streaming
and existing client appearances. Names, orange legendary quality,
requirements and stats come from native item query responses.

Legendary powers use native equip-spell tooltip lines. Each level variant has a separate display-only
spell with its exact bonus and condition; item flavor descriptions are empty. These spells have no effects
and are skipped by the module's equip-spell hook, so the event-driven power auras remain the only source
of gameplay bonuses. Tooltip spells are delivered only alongside owned, acquired or queried items, once per
spell per session. The login stream omits unowned variants, and its item-table capacity placeholder does not
request a tooltip spell. Tooltip rows precede native item responses, including bulk queries.

The pending world migration upgrades existing module data and runs after the module's
catalog migration on fresh installs. It adds nothing when the module's client item rows are absent.
The enabled module advances the native client-cache version so previously cached item descriptions are fetched again.

Keep `CoA.SendDisplayPatches=1` enabled. The spell streamer merges physical records, SQL `spell_dbc` overlays and
registered ability-selector patches using `SMSG_PATCH_SPELL` (`0x092A`, 170 words and four sized strings).
Existing description overrides take priority, and empty SQL strings preserve physical strings. Timed buff
tooltips receive current effect amounts through the existing Ascension aura-amount packets. No physical client
or server DBC file is modified. Server packet construction is covered by socketless gameplay scenarios; live
client delivery, numeric tooltip rendering and buff icons require separate client acceptance.

The authoritative designs are in `data/catalog.json`. Regenerate the C++ catalog, catalog
and standalone HTML preview with `python3 -B modules/mod-coa-legendary-items/tools/generate_catalog.py`.
To author a new full catalog migration, pass `--sql-output` with a new path in the module's `data/sql/db-world/`.
Previously applied migrations are kept unchanged.
The HTML works directly from disk and makes no external requests.

## Verification

Use `python3 -B tools/verify_all.py` for source, build, unit, catalog and gameplay checks.
The gameplay scenarios live in `tests/gameplay/` and remain discoverable by catalog id. Default verification
skips them when the module is excluded from the build or its runtime option is disabled. To run them, use a
separate test module configuration with `CoALegendaryItems.Enable=1` and `CoALegendaryItems.DropChance=100`
so drop eligibility can be asserted deterministically. The shared `client-sql-patches-opt-in` scenario verifies
the disabled and unbuilt paths and is omitted from default selection while the module is active.
`tests/test_optional_module.py` checks fresh installs, cleanup of legacy data
and repeated module installs on a disposable MySQL server.
