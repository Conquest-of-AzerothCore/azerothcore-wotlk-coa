# Classic Mythic Dungeon cache 1278054

The supplied item export names this item Manastorm Cache: Mythic Dungeons and describes it as:

> Manastorm 201 to 250
> Contains gear up to Mythic Dungeons!

The supplied loot export has no loot rows or references for this cache. It is a scriptless HAS_LOOT container,
RequiredLevel 60, with no recovered item-loot conditions. This describes the export, not a live database query.

## Candidate mapping

[MYTHIC_DUNGEON_CACHE_CANDIDATES.csv](MYTHIC_DUNGEON_CACHE_CANDIDATES.csv) records 1833 unique item IDs,
their exact descriptions, metadata, source lines and base relationships: 611 Normal, 611 Heroic and 611 Mythic.
The Normal and Heroic tiers reuse the documented SQL 49/50 mappings and their reconstruction caveats.
Each Mythic variant matches its base name, class, subclass, equipment slot and display model exactly.
All 611 Mythic variants have the exact description @Mythic Dungeon@, epic quality and RequiredLevel 60.
No @Mythic 1@, @Mythic 2@ or other ranked Mythic+ variants are included.

610 Mythic items have ItemLevel 64. The explicit exception is 523198, Idol of Brutality, ItemLevel 70,
mapped from base 23198. Its plain Mythic Dungeon description and identity are retained; item level alone
is not a tier classifier. Normal items have ItemLevel 57; Heroic items have ItemLevel 61.

## User-approved selection policy

One guaranteed item while the module is enabled: 75% Mythic, 20% Heroic, 5% Normal. These are CoA policy odds,
not recovered Ascension odds. Three explicit-chance root rows share GroupId 1, selecting exactly one tier.
Dedicated reference pools 9003101 (Normal), 9003102 (Heroic) and 9003103 (Mythic) each contain 611 pure gear
leaves. Existing primary-stat preference applies after tier selection and does not alter the tier split.

ManastormRewards recognizes 1278054 even outside the active depth catalogue, allowing existing or granted
copies to use stat preference. The existing OnAfterRefCount guard now also covers this cache's three pools,
forcing one reference iteration regardless of global reference amount rates. Standard container opening,
Normal and Heroic cache behavior, Mode 1/2 transport, depth brackets and progression remain unchanged.

## Migration and validation

Apply SQL 53 to acore_world after rebuilding the changed module, then restart worldserver. Its preflight
checks the scriptless HAS_LOOT cache, all 1833 exact candidate identities and descriptions, level at most 60,
InnoDB loot tables, conditions, and reserved-reference ownership/consumers across all loot stores.
Persistent loot changes are transactional. Tier counts use one temporary-table reference per statement,
avoiding the MySQL error 1137 encountered in the initial SQL 50.

SQLite model checks passed for generated candidate identity, 611 leaves per tier, actual migration mutation,
75/20/5 exclusive root group, unchanged Heroic cache and idempotent reapplication. Missing-tier and empty
fixtures fail the count checks. All Mythic candidates were verified to have the exact unranked marker.
MySQL procedure execution, C++ compilation and in-game opening remain untested.

Source item dump SHA-256: 3e36f8748b12b89605ec278953ad4c9c3db505757d4bc9a7294ea19c052e243e.
