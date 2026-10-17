# Manastorm affix helper creature recovery

Seven helper creature entries required by the recovered Manastorm affix spell graphs were missing from the AzerothCore world database.

## Recovered creature-cache / Exiles evidence

| Entry | Name | Side | Rank | Type flags | Type | Family | Display IDs | Health modifier | Mana modifier | Client movementId |
|---:|---|---|---:|---:|---:|---:|---|---:|---:|---:|
| 80913 | Bonestorm | Hostile | 3 (Boss) | 4 | 10 | 0 | 14501 | 0.7 | 1.0 | 999 |
| 80914 | Mushroom | Hostile | 3 (Boss) | 4 | 10 | 0 | 14501 | 0.7 | 1.0 | 999 |
| 80917 | Overwhelming Energy / Cosmetic | Hostile | 3 (Boss) | 4 | 10 | 0 | 14501 | 0.7 | 1.0 | 999 |
| 80922 | Wild Magics | Neutral | 0 | 0 | 10 | 0 | 24890, 24895, 26622, 24898 | 0.2 | 1.0 | 998 |
| 80923 | Wild Magics Cosmetic Dummy | Neutral | 0 | 0 | 10 | 0 | 200003 | 0.2 | 1.0 | 998 |
| 80924 | Cold Snap | Neutral | 0 | 0 | 10 | 0 | 100003 | 0.2 | 1.0 | 999 |
| 80925 | Cold Snap Effect | Neutral | 0 | 0 | 10 | 0 | 100003 | 0.2 | 1.0 | 999 |

The Boss label is creature-template metadata, not evidence that the affix itself is a boss encounter. The three hostile helpers independently carry rank 3 and type_flags 4 in captured creature-cache data.

## Spell-graph ownership

- Bone Storm summons 80913.
- Fungal summons 80914.
- Overwhelming Energy summons 80917.
- Wild Magics summons 80922 and 80923.
- Cold Snap summons 80924 and 80925.

## Not recovered

The cited records do not establish the original numeric server faction template, unit flags, flags_extra, AIName/ScriptName, level range, exact base damage/armor, or AzerothCore MovementType.

The SQL reconstruction therefore keeps those fields explicitly conservative:

- Hostile -> faction template 14 as a server fallback.
- Neutral -> faction template 7 as a server fallback.
- helpers are non-attackable and not selectable;
- NullCreatureAI prevents unintended default melee;
- no XP is granted;
- server MovementType stays 0. Client movementId 998/999 is evidence only and is not mapped to AzerothCore MovementType.

See `data/sql/db-world/base/04_manastorm_affix_helper_creatures.sql`.

If a future source recovers the original full server rows, replace the conservative fields rather than treating them as historical values.
